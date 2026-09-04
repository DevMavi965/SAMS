import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/attendance.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/widgets/fac_widgets/fac_class_card.dart';
import 'package:smas3/widgets/fac_widgets/fac_home_grid.dart';
import 'package:smas3/widgets/student_widgets/upcoming_class_card.dart';

import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../services/db_service.dart';
import '../../services/notification_helper.dart';

class FacHomeTab extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;

  final Lecturer lecturer;
  const FacHomeTab({super.key, required this.lecturer, required this.insAdmin, required this.institute, required this.department});

  @override
  State<FacHomeTab> createState() => _FacHomeTabState();
}

class _FacHomeTabState extends State<FacHomeTab> {

  List<LectureModel> lectures = [];

  // cached so today's lectures are only fetched once per build cycle,
  // instead of once in initState + once per FutureBuilder that needs them
  late Future<List<LectureModel>> _todaysLecturesFuture;

  // Single cached future for the whole "This Week" stats card. Replaces
  // 5 separate uncached Futures that were each re-triggered on every
  // rebuild and each re-fetching the same lecture docs independently.
  late Future<Map<String, dynamic>> _weeklyStatsFuture;

  // One in-app Timer per today's lecture, firing at that lecture's end
  // time to auto-finalize its attendance (see _armAutoFinalize below).
  // Cancelled in dispose so they don't fire against an unmounted state.
  final List<Timer> _autoFinalizeTimers = [];

  // ---- shared helpers for parsing the "attendance" field stored on a lecture doc ----

  static TimeOfDay? _toTimeOfDay(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return TimeOfDay.fromDateTime(v.toDate());
    if (v is Map) {
      final h = v['hour'];
      final m = v['minute'];
      if (h is int && m is int) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  static List<Attendance> _parseAttendance(dynamic rawList) {
    if (rawList is! List) return [];
    return rawList
        .whereType<Map>()
        .map((raw) => Attendance(
      sid: raw['sid']?.toString() ?? '',
      checkin: _toTimeOfDay(raw['checkin']),
      checkout: _toTimeOfDay(raw['checkout']),
      mid_point: raw['mid_point'] is bool ? raw['mid_point'] as bool : null,
      method: raw['method']?.toString(),
      status: raw['status']?.toString() ?? 'absent',
    ))
        .toList();
  }

  static LectureModel _lectureFromDoc(String id, Map<String, dynamic> data) {
    final datedTs = data['dated'] as Timestamp;
    final startTs = data['start_time'] as Timestamp;
    final endTs = data['end_time'] as Timestamp;

    return LectureModel(
      id: id,
      dated: datedTs.toDate(),
      start_time: TimeOfDay.fromDateTime(startTs.toDate()),
      end_time: TimeOfDay.fromDateTime(endTs.toDate()),
      attendance: _parseAttendance(data['attendance']),
      room: data['room'] ?? '',
      status: data['status'],
      course: data['course_name'] ?? '',
    );
  }

  Future<List<LectureModel>> getTodaysLectures() async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final now = DateTime.now();

      // Step 1: find every course this lecturer teaches.
      final myCourses = await dbService.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
          .where("institute_id", isEqualTo: widget.institute.id)
          .where("lecturer_id", isEqualTo: widget.lecturer.id)
          .get();

      if (myCourses.docs.isEmpty) return [];

      final courseIds = myCourses.docs.map((doc) => doc.id).toList();

      List<LectureModel> todaysLectures = [];

      for (var i = 0; i < courseIds.length; i += 30) {
        final batch = courseIds.sublist(
          i,
          i + 30 > courseIds.length ? courseIds.length : i + 30,
        );

        // Equality-only — no composite index needed.
        final lecturesIndexSnap = await dbService.indexDoc
            .where("type", isEqualTo: "lecture")
            .where("course_id", whereIn: batch)
            .get();

        for (var idxDoc in lecturesIndexSnap.docs) {
          final idx = idxDoc.data();

          final datedRaw = idx['dated'];
          if (datedRaw is! Timestamp) continue;
          final datedDate = datedRaw.toDate();

          final isToday = DateUtils.isSameDay(datedDate, now);
          if (!isToday) continue;

          // session_id / semester_id come from the lecture's own index doc —
          // a lecturer can have lectures across multiple sessions/semesters,
          // so this must be resolved per-lecture, not once for the whole lecturer.
          final lectureDoc = await dbService.dbref
              .collection("ins_admins").doc(widget.insAdmin.id)
              .collection("institutes").doc(widget.institute.id)
              .collection("departments").doc(idx['department_id'])
              .collection("sessions").doc(idx['session_id'])
              .collection("semesters").doc(idx['semester_id'])
              .collection("courses").doc(idx['course_id'])
              .collection("lectures").doc(idxDoc.id)
              .get();

          if (!lectureDoc.exists) continue;

          todaysLectures.add(_lectureFromDoc(lectureDoc.id, lectureDoc.data()!));
        }
      }//Today
      try{
        for (var lecture in todaysLectures) {
          await scheduleLectureNotificationBeforeStart(lecture);
          await scheduleLectureNotificationStart(lecture);
          await scheduleLectureNotificationEnd(lecture);
          await scheduleLectureNotificationBeforeEnd(lecture);
        }
      }catch(e){
        print("fac schedule error:$e");
      }

      // Arm (or immediately run) automatic attendance finalization for
      // each of today's lectures — see _armAutoFinalize below.
      for (var lecture in todaysLectures) {
        _armAutoFinalize(lecture);
      }

      return todaysLectures;
    } catch (e) {
      print(e.toString());
      return [];
    }
  }
  void _armAutoFinalize(LectureModel lecture) {
    final dbService = Provider.of<DbService>(context, listen: false);
    final end = _combineDateAndTime(lecture.dated, lecture.end_time);
    final now = DateTime.now();

    if (!now.isBefore(end)) {
      dbService.finalizeLectureAttendance(null, lecture);
      return;
    }

    final timer = Timer(end.difference(now), () {
      if (!mounted) return;
      dbService.finalizeLectureAttendance(null, lecture);
    });
    _autoFinalizeTimers.add(timer);
  }

  @override
  void initState() {
    super.initState();
    _todaysLecturesFuture = getTodaysLectures();
    _weeklyStatsFuture = _computeWeeklyStats(
      context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!,
    );
  }

  @override
  void dispose() {
    for (final t in _autoFinalizeTimers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
    ListView(
      children: [
        Text("Welcome ${widget.lecturer.name}!",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
        SizedBox(height: 7,),
        Text("Manage Your Classes and Attendance",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        FacHomeGrid(insAdmin:widget.insAdmin, institute: widget.institute, department: widget.department,lecturer: widget.lecturer,),
        SizedBox(height: 10,),

        // _MarkAttendanceCard(context),
        SizedBox(height: 25,),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's lectures",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500),),
            Badge(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9),
              label: Padding(
                padding: const EdgeInsets.all(4.0),
                child: FutureBuilder(
                  future: _todaysLecturesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading...");
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Text("0");
                    }
                    return Text(
                      "${snapshot.data!.length} lectures",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    );
                  },
                ),
              ),
            )
          ],
        ),
        SizedBox(height: 7,),
        //classes (completed or pending)
        FutureBuilder(
          future: _todaysLecturesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Loading...");
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Text("0");
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return UpcomingClassCard( lectureModel:snapshot.data![index],);
              },
            );
          },
        ),
        SizedBox(height: 15,),
        Card(
          color: Colors.white,
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: 10,vertical: 10
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${widget.lecturer.deprt}-This Week",style: TextStyle(fontSize: 17,fontWeight: FontWeight.w400),),
                SizedBox(height: 25,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("classes conducted"),
                    SizedBox(width: 10,),
                    Row(
                      children: [
                        FutureBuilder(
                          future: _weeklyStatsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data!['conducted_lectures'].toString());
                          },
                        ),
                        Text("/"),
                        FutureBuilder(
                          future: _weeklyStatsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data!['total_lectures'].toString());
                          },
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 5,),
                Flexible(
                  child: FutureBuilder(
                    future: _weeklyStatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text("Loading...");
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return Text("0");
                      }
                      final percentageConducted = snapshot.data!['percentage_conducted'] as num;
                      return LinearProgressIndicator(
                        value: percentageConducted / 100,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(10),

                      );
                    },
                  ),
                ),

                SizedBox(height: 20,),
                FutureBuilder(
                  future: _weeklyStatsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading...");
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Text("0");
                    }
                    final avgAttendance = snapshot.data!['avg_attendance'] as double;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Avg Attendance"),
                            Text("${(avgAttendance*100).toStringAsFixed(1)}%")
                          ],
                        ),
                        SizedBox(height: 5,),
                        LinearProgressIndicator(
                          value: avgAttendance,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(10),

                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 7,),
                Divider(
                  thickness: 0.5,
                  color: Colors.grey,
                ),
                SizedBox(height: 7,),
                Flex(direction: Axis.horizontal,
                  children: [
                    Expanded(child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(CupertinoIcons.check_mark_circled,color: Theme.of(context).primaryColor,size: 30,),
                        FutureBuilder(
                          future: _weeklyStatsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            // present tile = present + late combined
                            return Text("${snapshot.data!['present_count']-snapshot.data!['late_count']}",style: TextStyle(fontWeight: FontWeight.w600,));
                          },
                        ),
                        Text("Present",style: TextStyle(color: Colors.grey),)
                      ],
                    )),
                    Expanded(child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(CupertinoIcons.clock,color: Colors.brown,size: 30,),
                        FutureBuilder(
                          future: _weeklyStatsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data!['late_count'].toString(),style: TextStyle(fontWeight: FontWeight.w600,));
                          },
                        ),
                        Text("Late",style: TextStyle(color: Colors.grey),)
                      ],
                    )),
                    Expanded(child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(CupertinoIcons.xmark_circle,color: Colors.red,size: 30,),
                        FutureBuilder(
                          future: _weeklyStatsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data!['absent_count'].toString(),style: TextStyle(fontWeight: FontWeight.w600,));
                          },
                        ),
                        Text("Absent",style: TextStyle(color: Colors.grey),)
                      ],
                    ))
                  ],
                )

              ],
            ),
          ),
        )
      ],
    ));
  }


  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _lectureIndexDocsThisWeek(
      BuildContext context, String insAdminId, String instituteId, String departmentId) async
  {
    final dbService = Provider.of<DbService>(context, listen: false);

    final now = DateTime.now();
    // Week starts Monday, ends Sunday (inclusive).
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 7)); // exclusive upper bound

    Query<Map<String, dynamic>> q = dbService.indexDoc
        .where("type", isEqualTo: "lecture")
        .where("ins_admin_id", isEqualTo: insAdminId)
        .where("institute_id", isEqualTo: instituteId)
        .where("department_id", isEqualTo: departmentId);

    final snap = await q.get();

    return snap.docs.where((idxDoc) {
      final datedRaw = idxDoc.data()['dated'];
      if (datedRaw is! Timestamp) return false;
      final datedDate = datedRaw.toDate();
      return !datedDate.isBefore(startOfWeek) && datedDate.isBefore(endOfWeek);
    }).toList();
  }


  Future<Map<String, dynamic>> _computeWeeklyStats(
      BuildContext context, String insAdminId, String instituteId, String departmentId) async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final docs = await _lectureIndexDocsThisWeek(context, insAdminId, instituteId, departmentId);
      final now = DateTime.now();

      // Fetch every lecture doc in parallel instead of one await per loop iteration.
      final lectureSnaps = await Future.wait(docs.map((idxDoc) {
        final idx = idxDoc.data();
        return dbService.dbref
            .collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("departments").doc(departmentId)
            .collection("sessions").doc(idx['session_id'])
            .collection("semesters").doc(idx['semester_id'])
            .collection("courses").doc(idx['course_id'])
            .collection("lectures").doc(idxDoc.id)
            .get();
      }));

      int conductedLectures = 0;
      int presentCount = 0; // present + late, i.e. "attended"
      int lateCount = 0;
      int absentCount = 0;

      for (final lectureDoc in lectureSnaps) {
        if (!lectureDoc.exists) continue;
        final data = lectureDoc.data();
        if (data == null) continue;

        if (!_isLectureTimeElapsed(data, now)) continue;
        conductedLectures++;

        final attendanceList = _parseAttendance(data['attendance']);
        // A student only counts as present if they actually completed the
        // session: status is present/late AND a checkout was recorded.
        // status==present/late with no checkout means they checked in but
        // never checked out — that does not count as present.
        final present = attendanceList
            .where((a) => a.status == "present" && a.checkout != null)
            .length;
        final late = attendanceList
            .where((a) => a.status == "late" && a.checkout != null)
            .length;
        final absent = attendanceList.where((a) => a.status == "absent").length;

        presentCount += present + late; // present tile shows present+late combined
        lateCount += late;
        absentCount += absent;
      }

      final totalMarks = presentCount + absentCount; // presentCount already includes late
      final avgAttendance = totalMarks > 0 ? (presentCount / totalMarks) : 0.0;
      final totalLectures = docs.length;
      final percentageConducted = totalLectures > 0 ? (conductedLectures / totalLectures) * 100 : 0;

      return {
        "total_lectures": totalLectures,
        "conducted_lectures": conductedLectures,
        "percentage_conducted": percentageConducted,
        "avg_attendance": avgAttendance,
        "present_count": presentCount,
        "late_count": lateCount,
        "absent_count": absentCount,
      };
    } catch (e) {
      print(e.toString());
      return {
        "total_lectures": 0,
        "conducted_lectures": 0,
        "percentage_conducted": 0,
        "avg_attendance": 0.0,
        "present_count": 0,
        "late_count": 0,
        "absent_count": 0,
      };
    }
  }

  bool _isLectureTimeElapsed(Map<String, dynamic> lectureData, DateTime now) {
    final dateTs = lectureData['dated'] as Timestamp?;
    final endTs = lectureData['end_time'] as Timestamp?;
    if (dateTs == null || endTs == null) return false;

    final date = dateTs.toDate();
    final endTod = endTs.toDate();
    final lectureEnd = DateTime(date.year, date.month, date.day, endTod.hour, endTod.minute);

    return now.isAfter(lectureEnd);
  }

  Widget _MarkAttendanceCard(BuildContext context){
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 10
      ),
      height: 140,
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ListTile(
            title: Text("Mark Attendance",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400,color: Colors.white),),
            subtitle: Text("Use Facial recognition or Manual",style: TextStyle(fontSize: 13,color: Colors.white),),
            trailing: Icon(Icons.filter_center_focus,color: Colors.white60,size: 48,),
          ),
          ElevatedButton(

              style: ElevatedButton.styleFrom(
                  fixedSize: Size(MediaQuery.of(context).size.width, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  )
              )

              ,onPressed:(){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Attendance Marked"),
                  duration: Duration(seconds: 1),
                  backgroundColor: Theme.of(context).primaryColor,));
          },
              child: Text("Mark Attendance",style: TextStyle(color: Theme.of(context).primaryColor))
          ),
        ],
      ),
    );
  }
  Future<void> scheduleLectureNotificationBeforeStart(LectureModel lecture) async {
    // 10 min before the lecture
    final lectureStart = _combineDateAndTime(
      lecture.dated,
      lecture.start_time,
    );

    // Don't schedule lectures that have already started
    if (lectureStart.isBefore(DateTime.now())) {
      return;
    }

    final notifDate=lectureStart.subtract(const Duration(minutes: 10));
    await NotifHelper.scheduledNotification("lecture", "lecture start remainder:", " ${lecture.course} lecture starting [Room # ${lecture.room}] in 10 minutes ", notifDate,100);
  }
  Future<void> scheduleLectureNotificationStart(LectureModel lecture) async {
    // 10 min before the lecture
    final lectureStart = _combineDateAndTime(
      lecture.dated,
      lecture.start_time,
    );

    // Don't schedule lectures that have already started
    if (lectureStart.isBefore(DateTime.now())) {
      return;
    }
    await NotifHelper.scheduledNotification("lecture", "lecture-start reminder :", " ${lecture.course} lecture started in [Room # ${lecture.room}], make sure to be at time", lectureStart,100);
  }
  Future<void> scheduleLectureNotificationEnd(LectureModel lecture) async {
    // 10 min before the lecture
    final lectureEnd = _combineDateAndTime(
      lecture.dated,
      lecture.end_time,
    );

    // Don't schedule lectures that have already started
    if (lectureEnd.isBefore(DateTime.now())) {
      return;
    }
    await NotifHelper.scheduledNotification("lecture", "chek-out remainder :", " ${lecture.course} lecture ended , make sure  students check-out ", lectureEnd,100);
  }
  Future<void> scheduleLectureNotificationBeforeEnd(LectureModel lecture) async {
    // 10 min before the lecture
    final lectureEnd = _combineDateAndTime(
      lecture.dated,
      lecture.end_time,
    );

    // Don't schedule lectures that have already started
    if (lectureEnd.isBefore(DateTime.now())) {
      return;
    }

    final notifDate=lectureEnd.subtract(const Duration(minutes: 5));
    await NotifHelper.scheduledNotification("lecture", "lecture-ending remainder :", " ${lecture.course} lecture ending soon in few minutes , make sure students check-out ", notifDate,100);
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}