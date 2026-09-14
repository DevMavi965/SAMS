import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/models/student_model.dart';

import '../../models/attendance.dart';
import '../../services/db_service.dart';
import '../../widgets/student_widgets/upcoming_class_card.dart';

DateTime _combine(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

class Scheduletab extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;
  final Student student;
  const Scheduletab({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.session,
    required this.semester, required this.student,
  });

  @override
  State<Scheduletab> createState() => _ScheduletabState();
}

class _ScheduletabState extends State<Scheduletab> {
  static const List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri"];

  int _selected = _defaultSelectedDay();
  late Future<List<LectureModel>> _weekLecturesFuture;

  // Weekends default to the upcoming Monday (index 0), not Friday — see
  // _computeStartOfWeek below for why.
  static int _defaultSelectedDay() {
    final todayWeekday = DateTime.now().weekday; // Mon=1..Sun=7
    return (todayWeekday >= 1 && todayWeekday <= 5) ? todayWeekday - 1 : 0;
  }

  
  late final DateTime _startOfWeek = _computeStartOfWeek();

  static DateTime _computeStartOfWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (now.weekday == DateTime.saturday) return today.add(const Duration(days: 2));
    if (now.weekday == DateTime.sunday) return today.add(const Duration(days: 1));
    return today.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _weekLecturesFuture = _fetchThisWeekLectures();
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
      attendance: (data['attendance'] as List<dynamic>? ?? [])
          .map((m) => Attendance.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      room: data['room'],
      status: data['status'],
      course: data['course_name'] ?? '',
    );
  }

  Future<List<LectureModel>> _fetchThisWeekLectures() async {
    try {
      final db = Provider.of<DbService>(context, listen: false);

      final courseIdx = await db.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
          .where("institute_id", isEqualTo: widget.institute.id)
          .where("department_id", isEqualTo: widget.department.id)
          .where("session_id", isEqualTo: widget.session.id)
          .where("semester_id", isEqualTo: widget.semester.id)
          .get();

      if (courseIdx.docs.isEmpty) return [];

      final startOfWeek = _startOfWeek;
      final endOfWeek = startOfWeek.add(const Duration(days: 7)); // exclusive

      // One lectures query per course, scoped server-side to this week and
      // run in parallel, rather than pulling every lecture ever and
      // filtering client-side.
      final lectureSnapshots = await Future.wait(courseIdx.docs.map((courseDoc) {
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
            .collection("courses")
            .doc(courseDoc.id)
            .collection("lectures")
            .where("dated", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .where("dated", isLessThan: Timestamp.fromDate(endOfWeek))
            .get();
      }));

      return [
        for (final snap in lectureSnapshots)
          for (final doc in snap.docs) _lectureFromDoc(doc.id, doc.data()),
      ];
    } catch (e) {
      debugPrint("Scheduletab._fetchThisWeekLectures error: $e");
      return [];
    }
  }

  List<LectureModel> _lecturesForDay(List<LectureModel> weekLectures, int dayIndex) {
    final dayDate = _startOfWeek.add(Duration(days: dayIndex));
    final matching = weekLectures
        .where((l) => DateUtils.isSameDay(l.dated, dayDate))
        .toList()
      ..sort((a, b) =>
          _combine(a.dated, a.start_time).compareTo(_combine(b.dated, b.start_time)));
    return matching;
  }
//progress
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: ListView(
          children: [
            const Text(
              "Class Schedule",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            const SizedBox(height: 3),
            const Text("Your Weekly Timetable", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 9),
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColorDark,
                    Theme.of(context).primaryColor,
                  ],
                  end: Alignment.topRight,
                  begin: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: const Text("Today", style: TextStyle(color: Colors.white, fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    DateFormat("dd MMMM, yyyy").format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                trailing: const Icon(PhosphorIconsBold.calendarBlank, color: Colors.white70, size: 39),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int i = 0; i < _days.length; i++)
                    InkWell(
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                          color: _selected == i
                              ? Theme.of(context).primaryColor.withOpacity(0.8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _selected == i ? Colors.grey.shade300 : Colors.white,
                          ),
                        ),
                        child: Text(
                          _days[i],
                          style: TextStyle(color: _selected == i ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<LectureModel>>(
              future: _weekLecturesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: RMFuncts.loadingAnimation(context),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text("Error: ${snapshot.error}")),
                  );
                }

                final dayLectures = _lecturesForDay(snapshot.data ?? [], _selected);

                if (dayLectures.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No lectures scheduled for this day",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final lecture in dayLectures)
                      UpcomingClassCard(lectureModel: lecture,studentId: widget.student.id,),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}