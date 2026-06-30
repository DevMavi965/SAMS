import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/course.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/lecture.dart';

import '../../../models/semester.dart';
import '../../../models/session.dart';
import '../../../services/db_service.dart';

class DailySchedule extends StatefulWidget {
  final DateTime date;
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;

  const DailySchedule({
    super.key,
    required this.date,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.session,
    required this.semester,
  });

  @override
  State<DailySchedule> createState() => _DailyScheduleState();
}

class _DailyScheduleState extends State<DailySchedule> {
  static const int _minDurationMinutes = 30;
  static const int _maxDurationMinutes = 120;

  List<Course> courses = [];
  bool coursesLoading = true;

  final Map<String, List<LectureModel>> _todayByCourse = {};

  List<LectureModel> get todayLectures {
    final all = _todayByCourse.values.expand((l) => l).toList();
    all.sort((a, b) => a.start_time.hour != b.start_time.hour
        ? a.start_time.hour.compareTo(b.start_time.hour)
        : a.start_time.minute.compareTo(b.start_time.minute));
    return all;
  }

  List<Course> get availableCourses => courses
      .where((c) => todayLectures.where((l) => l.course == c.name).isEmpty)
      .toList();

  StreamSubscription<QuerySnapshot>? _coursesSub;
  final Map<String, StreamSubscription<QuerySnapshot>> _lectureSubs = {};

  String? selectedCourse;
  TimeOfDay? startTime, endTime;
  final TextEditingController room = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ── helpers 888888888888888888888888888888888888888888888888888888888888888888888888888888──────

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _formatDuration(TimeOfDay start, TimeOfDay end) {
    final mins = _toMinutes(end) - _toMinutes(start);
    if (mins <= 0) return '';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Returns a non-null error string when the slot is invalid, null when ok.
  /// Pass [excludeId] when editing so the lecture doesn't conflict with itself.
  String? _validateSlot(
      TimeOfDay start,
      TimeOfDay end, {
        String? excludeId,
      }) {
    final startMins = _toMinutes(start);
    final endMins = _toMinutes(end);

    // 1. end must be after start
    if (endMins <= startMins) {
      return 'End time must be after start time.';
    }

    // 2. minimum duration
    final duration = endMins - startMins;
    if (duration < _minDurationMinutes) {
      return 'Lecture must be at least $_minDurationMinutes minutes long.';
    }

    // 3. maximum duration
    if (duration > _maxDurationMinutes) {
      return 'Lecture cannot be longer than ${_maxDurationMinutes ~/ 60} hours.';
    }

    // 4. no overlap with any other lecture on the same day
    for (final existing in todayLectures) {
      if (excludeId != null && existing.id == excludeId) continue;

      final existStart = _toMinutes(existing.start_time);
      final existEnd = _toMinutes(existing.end_time);

      if (startMins < existEnd && endMins > existStart) {
        return '"${existing.course}" is already scheduled from '
            '${_formatTime(existing.start_time)} to '
            '${_formatTime(existing.end_time)}.\n'
            'Please choose a different time slot.';
      }
    }

    return null; // all good
  }

  // ── Firestore streams 88888888888888888888888888888888888888888888888888888888888888888─────

  @override
  void initState() {
    super.initState();
    _listenToCourses();
  }

  CollectionReference _coursesRef() {
    final db = Provider.of<DbService>(context, listen: false);
    return db.dbref
        .collection("ins_admins")
        .doc(widget.insAdmin.id)
        .collection("institutes")
        .doc(widget.institute.id)
        .collection("departments")
        .doc(widget.department.id)
        .collection("sessions")
        .doc(widget.session.id)
        .collection("semesters")
        .doc(widget.semester.id)
        .collection("courses");
  }

  void _listenToCourses() {
    _coursesSub = _coursesRef().snapshots().listen((snapshot) {
      if (!mounted) return;

      final newCourses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Course(
          id: doc.id,
          name: data['name'],
          insAdminId: data['ins_admin_id'],
          institute_id: data['institute_id'],
          department_id: data['department_id'],
          session_id: data['session_id'],
          semester_id: data['semester_id'],
          course_code: data['course_code'],
          credit_hours: data['credit_hours'],
          no_of_lectures: data['no_of_lectures'],
          type: data['type'],
          lecturer_id: data['lecturer_id'],
          created_at: (data['created_at'] as Timestamp).toDate(),
          lecturer_name: data['lecturer_name'],
        );
      }).toList();

      setState(() {
        courses = newCourses;
        coursesLoading = false;
      });

      final currentIds = newCourses.map((c) => c.id).toSet();
      final removedIds =
      _lectureSubs.keys.where((id) => !currentIds.contains(id)).toList();
      for (var id in removedIds) {
        _lectureSubs[id]?.cancel();
        _lectureSubs.remove(id);
        _todayByCourse.remove(id);
      }
      for (var course in newCourses) {
        _lectureSubs.putIfAbsent(
            course.id!, () => _listenToLectures(course));
      }
      if (removedIds.isNotEmpty) setState(() {});
    }, onError: (e) {
      if (!mounted) return;
      setState(() => coursesLoading = false);
    });
  }

  StreamSubscription<QuerySnapshot> _listenToLectures(Course course) {
    return _coursesRef()
        .doc(course.id)
        .collection("lectures")
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final today = <LectureModel>[];
      for (var lec in snapshot.docs) {
        final data = lec.data() as Map<String, dynamic>;
        final dated = (data['dated'] as Timestamp).toDate();
        if (dated.year == widget.date.year &&
            dated.month == widget.date.month &&
            dated.day == widget.date.day) {
          today.add(LectureModel(
            id: lec.id,
            course: data['course_name'],
            dated: dated,
            start_time: TimeOfDay(
              hour: (data['start_time'] as Timestamp).toDate().hour,
              minute: (data['start_time'] as Timestamp).toDate().minute,
            ),
            end_time: TimeOfDay(
              hour: (data['end_time'] as Timestamp).toDate().hour,
              minute: (data['end_time'] as Timestamp).toDate().minute,
            ),
            present: List<String>.from(data['present']),
            absent: List<String>.from(data['absent']),
            room: data['room'],
            status: data['status'],
          ));
        }
      }
      setState(() => _todayByCourse[course.id!] = today);
    });
  }

  @override
  void dispose() {
    _coursesSub?.cancel();
    for (var sub in _lectureSubs.values) {
      sub.cancel();
    }
    room.dispose();
    super.dispose();
  }

  // ── UI 8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              "${getWeekday(widget.date)} ${DateFormat("dd MMM yy").format(widget.date)}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: 10
        ),
        children: [
          const SizedBox(height: 0),

          if (coursesLoading)
            const Center(child: CircularProgressIndicator())
          else if (courses.isEmpty)
            const Center(child: Text("No courses found")),

          const SizedBox(height: 20),

          if (!coursesLoading && todayLectures.isEmpty)
            const Center(child: Text("No lectures today, add first",style: TextStyle(color: Colors.black54),))
          else
            for (var lecture in todayLectures)
              // ListTile(
              //   onTap: () {
              //
              //   },
              //   title: Text(lecture.course),
              //   subtitle: Text(
              //     "${lecture.start_time.format(context)} - ${lecture.end_time.format(context)}",
              //   ),
              //   trailing: Text(lecture.room),
              //   leading: IconButton(onPressed: (){
              //     Provider.of<DbService>(context,listen: false).removeLecture(context, lecture.id!);
              //   }, icon: Icon(Icons.delete)),
              // ),
             InkWell(
               onTap: (){
                 final course = _courseForLecture(lecture);
                 if (course == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content:
                       Text("Course for this lecture no longer exists"),
                     ),
                   );
                   return;
                 }
                 _openLectureSheet(context,
                     lecture: lecture, courseId: course.id);
               },
               child: Container(
                 margin: EdgeInsets.only(
                   bottom: 5
                 ),
                 padding: EdgeInsets.symmetric(
                   horizontal: 3,
                   vertical: 12
                 ),
                 decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(10),
                   color: Theme.of(context).primaryColor.withOpacity(0.1),
                   border: Border.all(
                     color: Theme.of(context).primaryColor,
                     width: 2
                   )
                 ),
                 child:
                 Row(
                   children: [
                     Expanded(
                         child:CircleAvatar(
                       backgroundColor: Theme.of(context).primaryColor,
                       radius: 27,
                       child: Text(RMFuncts.getFirstLetters(lecture.course),style: TextStyle(color: Colors.white,fontSize: 16),)
                     )
                     ),
                     SizedBox(width: 8,),
                     Expanded(
                       flex: 3,
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Flexible(
                             child: Row(
                               children: [

                                 Text(lecture.course,style: TextStyle(
                                   fontWeight: FontWeight.w500,fontSize: 16
                                 ),),
                               ],
                             ),
                           ),
                           SizedBox(height: 5,),
                           Flexible(
                             child: Row(
                               children: [
                                 Icon(CupertinoIcons.person_crop_circle),
                                 SizedBox(width: 10,),
                                 Text(courses.firstWhere((e)=>e.name==lecture.course).lecturer_name!,),
                               ],
                             ),
                           ),
                           SizedBox(height: 5,),
                           Flexible(
                             child: Row(
                               children: [
                                 Icon(CupertinoIcons.clock),
                                 SizedBox(width: 10,),
                                 Text("${lecture.start_time.format(context)}  to  ${lecture.end_time.format(context)}",style: TextStyle(color: Colors.black87),),
                               ],
                             ),
                           ),
                           SizedBox(height: 5,),
                           Flexible(
                             child: Row(
                               children: [
                                 Icon(Icons.door_front_door_outlined),
                                 SizedBox(width: 10,),
                                 Text("Room no :${lecture.room}"),
                               ],
                             ),
                           ),
                           SizedBox(height: 5,),
                           Flexible(
                             child: Row(
                               children: [
                                 Icon(Icons.calendar_today_outlined),
                                 SizedBox(width: 10,),
                                 Text("Scheduled on:${DateFormat("dd MMM yyyy").format(lecture.dated)}"),
                               ],
                             ),
                           ),

                         ],
                       ),
                     ),
                     Expanded(child: Column(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Badge(
                           backgroundColor: Theme.of(context).primaryColor,
                           label: Text(lecture.status==null?"Completed":lecture.status!,style: TextStyle(color: Colors.white),),
                         ),
                         SizedBox(height: 10,),
                         IconButton(onPressed: (){
                            Provider.of<DbService>(context,listen: false).removeLecture(context, lecture.id!);
                         }, icon: Icon(CupertinoIcons.delete))
                       ],
                     ))
                   ],
                 ),
               ),
             ),

          const SizedBox(height: 20),

          if (!coursesLoading && courses.isNotEmpty && availableCourses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "All courses already scheduled",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else if (!coursesLoading && courses.isNotEmpty)
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).primaryColor),
              ),
              onPressed: () => _openLectureSheet(context),
              child: const Text("Add Lecture",
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Course? _courseForLecture(LectureModel lecture) {
    for (var c in courses) {
      if (c.name == lecture.course) return c;
    }
    return null;
  }

  // ── Bottom sheet 888888888888888888888888888888888888888888888888888888888888888888888888888888─

  void _openLectureSheet(BuildContext context,
      {LectureModel? lecture, String? courseId}) {
    final bool isEditing = lecture != null;

    // seed form fields
    if (isEditing) {
      selectedCourse = courseId;
      startTime = lecture.start_time;
      endTime = lecture.end_time;
      room.text = lecture.room;
    } else {
      selectedCourse = null;
      startTime = null;
      endTime = null;
      room.clear();
    }

    // live error message shown below the time pickers
    String? timeError;

    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, set) {
          // recomputes the inline error whenever start/end change
          void revalidateTimes() {
            if (startTime != null && endTime != null) {
              set(() {
                timeError = _validateSlot(
                  startTime!,
                  endTime!,
                  excludeId: isEditing ? lecture.id : null,
                );
              });
            }
          }

          return Padding(
            // keeps the sheet above the keyboard
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // ── title 8888888888888888888888888888888888888888888888888888──────
                    Center(
                      child: Text(
                        isEditing ? "Update Lecture" : "Add Lecture",
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── course selector / label 66666666666666666666666
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          lecture.course,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                      )
                    else
                      courses.isEmpty
                          ? const Text("No courses found, add first")
                          : DropdownButtonFormField<String>(
                        value: selectedCourse,
                        hint: const Text("Select Course"),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Course",
                        ),
                        items: [
                          for (var course in availableCourses)
                            DropdownMenuItem(
                              value: course.id,
                              child: Text(course.name),
                            ),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "Please select a course";
                          }
                          return null;
                        },
                        onChanged: (v) => set(() => selectedCourse = v),
                      ),

                    const SizedBox(height: 14),

                    // ── time pickers 777777777888888888888888888888
                    Row(
                      children: [
                        // start time
                        Expanded(
                          child: _TimeTile(
                            label: "Start Time",
                            time: startTime,
                            hasError: timeError != null && startTime != null,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: sheetContext,
                                initialTime: startTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                set(() => startTime = picked);
                                revalidateTimes();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // end time
                        Expanded(
                          child: _TimeTile(
                            label: "End Time",
                            time: endTime,
                            hasError: timeError != null && endTime != null,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: sheetContext,
                                initialTime: endTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                set(() => endTime = picked);
                                revalidateTimes();
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // ── duration badge 5555555555555555555555555555555
                    if (startTime != null && endTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: () {
                          final startM = _toMinutes(startTime!);
                          final endM = _toMinutes(endTime!);
                          if (endM <= startM) return const SizedBox.shrink();
                          final dur = endM - startM;
                          final isOk = dur >= _minDurationMinutes &&
                              dur <= _maxDurationMinutes;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: isOk ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(startTime!, endTime!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOk ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!isOk) ...[
                                const SizedBox(width: 4),
                                Text(
                                  dur < _minDurationMinutes
                                      ? "(min $_minDurationMinutes min)"
                                      : "(max ${_maxDurationMinutes ~/ 60}h)",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.orange),
                                ),
                              ]
                            ],
                          );
                        }(),
                      ),

                    // ── inline time error 7777777777776666666666666
                    if (timeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                timeError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // ── room field 7777777777777777777777777777777777777
                    TextFormField(
                      controller: room,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Room",
                        hintText: "e.g. Lab-3",
                        prefixIcon: Icon(Icons.door_front_door_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Please enter the room";
                        }
                        if (v.trim().length > 10) {
                          return "Room must be 10 characters or fewer";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── submit button hhhhhhhhhhhhhhhhhhhhhhhhh
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        // 1. course
                        final courseChosen =
                            isEditing || selectedCourse != null;
                        if (!courseChosen) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text("Please select a course")),
                          );
                          return;
                        }

                        // 2. times picked
                        if (startTime == null || endTime == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Please select both start and end time")),
                          );
                          return;
                        }

                        // 3. room field
                        if (!formKey.currentState!.validate()) return;

                        // 4. full time validation (end > start, duration, overlaps)
                        final error = _validateSlot(
                          startTime!,
                          endTime!,
                          excludeId: isEditing ? lecture.id : null,
                        );
                        if (error != null) {
                          set(() => timeError = error);
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.red.shade700,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          return;
                        }

                        // ── all valid — write to Firestore 8888888888888──
                        final db =
                        Provider.of<DbService>(context, listen: false);

                        if (isEditing) {
                          final updated = LectureModel(
                            id: lecture!.id,
                            course: lecture.course,
                            dated: lecture.dated,
                            start_time: startTime!,
                            end_time: endTime!,
                            present: lecture.present,
                            absent: lecture.absent,
                            room: room.text.trim(),
                            status: lecture.status,
                          );
                          await db.updateLecture(context, updated);
                        } else {
                          final courseV = courses
                              .firstWhere((e) => e.id == selectedCourse);
                          final newLecture = LectureModel(
                            course: courseV.name,
                            dated: widget.date,
                            start_time: startTime!,
                            end_time: endTime!,
                            present: [],
                            absent: [],
                            room: room.text.trim(),
                            status: "upcoming"
                          );
                          await db.addLecture(
                            context,
                            widget.insAdmin.id!,
                            widget.institute.id!,
                            widget.department.id!,
                            widget.session.id!,
                            widget.semester.id!,
                            selectedCourse!,
                            newLecture,
                          );
                        }

                        if (!context.mounted) return;
                        setState(() {
                          selectedCourse = null;
                          startTime = null;
                          endTime = null;
                          room.clear();
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: Text(
                        isEditing ? "Update Lecture" : "Add Lecture",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  String getWeekday(DateTime date) {
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[date.weekday];
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final bool hasError;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = hasError ? Colors.red : Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: hasError ? Colors.red : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  time == null ? "Tap to pick" : time!.format(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: time == null ? Colors.grey : color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}