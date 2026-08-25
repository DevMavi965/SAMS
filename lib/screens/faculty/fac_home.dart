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

import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../services/db_service.dart';

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
      }

      return todaysLectures;
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _todaysLecturesFuture = getTodaysLectures();
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
                return FacClassCard( lectureModel:snapshot.data![index],);
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
                          future: getDepartmentCompletedLecturesThisWeekCount(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data.toString());
                          },
                        ),
                        Text("/"),
                        FutureBuilder(
                          future: getDepartmentLecturesThisWeekCount(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data.toString());
                          },
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 5,),
                Flexible(
                  child: FutureBuilder(
                    future: getPercentageConductedLecturesThisWeek(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text("Loading...");
                      } else if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else if (!snapshot.hasData || snapshot.data == null) {
                        return Text("0");
                      }
                      return LinearProgressIndicator(
                        value: snapshot.data! / 100,
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
                  future: getDepartmentAvgAttendanceThisWeek(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading...");
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return Text("0");
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Avg Attendance"),
                            Text("${(snapshot.data!['avg_attendance']*100).toStringAsFixed(1)}%")
                          ],
                        ),
                        SizedBox(height: 5,),
                        LinearProgressIndicator(
                          value: snapshot.data!['avg_attendance'],
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
                          future: getDepartmentAttendanceCountThisWeek(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!, "present"),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data.toString(),style: TextStyle(fontWeight: FontWeight.w600,));
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
                          future: getDepartmentAttendanceCountThisWeek(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!, "late"),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data.toString(),style: TextStyle(fontWeight: FontWeight.w600,));
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
                          future: getDepartmentAttendanceCountThisWeek(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!, "absent"),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            } else if (!snapshot.hasData || snapshot.data == null) {
                              return Text("0");
                            }
                            return Text(snapshot.data.toString(),style: TextStyle(fontWeight: FontWeight.w600,));
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

  /// Runs the shared "lectures this week for this department" scan once and
  /// hands back the raw index docs, so the stat helpers below don't each
  /// repeat the same Firestore round trip.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _lectureIndexDocsThisWeek(
      BuildContext context, String insAdminId, String instituteId, String departmentId,
      {bool completedOnly = false}) async {
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
    if (completedOnly) {
      q = q.where("status", isEqualTo: "completed");
    }

    final snap = await q.get();

    return snap.docs.where((idxDoc) {
      final datedRaw = idxDoc.data()['dated'];
      if (datedRaw is! Timestamp) return false;
      final datedDate = datedRaw.toDate();
      return !datedDate.isBefore(startOfWeek) && datedDate.isBefore(endOfWeek);
    }).toList();
  }

  Future<int> getDepartmentLecturesThisWeekCount(BuildContext context, String insAdminId, String instituteId, String departmentId) async {
    try {
      final docs = await _lectureIndexDocsThisWeek(context, insAdminId, instituteId, departmentId);
      return docs.length;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  Future<int> getDepartmentCompletedLecturesThisWeekCount(BuildContext context, String insAdminId, String instituteId, String departmentId) async {
    try {
      final docs = await _lectureIndexDocsThisWeek(context, insAdminId, instituteId, departmentId, completedOnly: true);
      return docs.length;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  Future<num> getPercentageConductedLecturesThisWeek(BuildContext context, String insAdminId, String instituteId, String departmentId) async {
    try {
      final conductedLectures = await getDepartmentCompletedLecturesThisWeekCount(context, insAdminId, instituteId, departmentId);
      final totalLectures = await getDepartmentLecturesThisWeekCount(context, insAdminId, instituteId, departmentId);
      if (totalLectures == 0) return 0;
      return (conductedLectures / totalLectures) * 100;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  /// Counts how many attendance entries across this week's lectures have the
  /// given status ("present" / "absent" / "late"), reading from the unified
  /// `attendance` field on each lecture doc (List<Attendance>-shaped map).
  Future<int> getDepartmentAttendanceCountThisWeek(
      BuildContext context, String insAdminId, String instituteId, String departmentId, String status) async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final docs = await _lectureIndexDocsThisWeek(context, insAdminId, instituteId, departmentId);

      int total = 0;

      for (var idxDoc in docs) {
        final idx = idxDoc.data();

        final lectureDoc = await dbService.dbref
            .collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("departments").doc(departmentId)
            .collection("sessions").doc(idx['session_id'])
            .collection("semesters").doc(idx['semester_id'])
            .collection("courses").doc(idx['course_id'])
            .collection("lectures").doc(idxDoc.id)
            .get();

        if (!lectureDoc.exists) continue;

        final attendanceList = _parseAttendance(lectureDoc.data()?['attendance']);
        total += attendanceList.where((a) => a.status == status).length;
      }

      return total;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  Future<Map<String, dynamic>> getDepartmentAvgAttendanceThisWeek(BuildContext context, String insAdminId, String instituteId, String departmentId) async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final docs = await _lectureIndexDocsThisWeek(context, insAdminId, instituteId, departmentId);

      int totalPresent = 0;
      int lectureCount = 0;

      for (var idxDoc in docs) {
        final idx = idxDoc.data();

        // Need the actual lecture document to read its "attendance" array —
        // indexDoc only stores pointers, not the attendance data itself.
        // session_id/semester_id come from this lecture's own index entry.
        final lectureDoc = await dbService.dbref
            .collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("departments").doc(departmentId)
            .collection("sessions").doc(idx['session_id'])
            .collection("semesters").doc(idx['semester_id'])
            .collection("courses").doc(idx['course_id'])
            .collection("lectures").doc(idxDoc.id)
            .get();

        if (!lectureDoc.exists) continue;

        final attendanceList = _parseAttendance(lectureDoc.data()?['attendance']);
        totalPresent += attendanceList.where((a) => a.status == "present").length;
        lectureCount++;
      }

      final avgAttendance = lectureCount > 0 ? (totalPresent / lectureCount) : 0.0;

      return {
        "total_present": totalPresent,
        "lecture_count": lectureCount,
        "avg_attendance": avgAttendance,
      };
    } catch (e) {
      print(e.toString());
      return {
        "total_present": 0,
        "lecture_count": 0,
        "avg_attendance": 0.0,
      };
    }
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
}