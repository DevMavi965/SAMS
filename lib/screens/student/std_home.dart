import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/course.dart';
import 'package:smas3/screens/student/std_lecAtd.dart';


import '../../models/attendance.dart';
import '../../models/student_model.dart';
import '../../services/db_service.dart';

import '../../services/notification_helper.dart';
import '../../widgets/student_widgets/Custome_line_chart.dart';
import '../../widgets/student_widgets/att_rec_card.dart';
import '../../widgets/student_widgets/daily_status_card.dart';
import '../../widgets/student_widgets/over_all_att_card.dart';
import '../../widgets/student_widgets/std_announc_card.dart';
import '../../widgets/student_widgets/upcoming_class_card.dart';

const List<String> _monthAbbrev = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];


DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

class _ResolvedLecture {
  final LectureModel lecture;
  final DateTime start;
  final DateTime end;
  final bool conducted;

  _ResolvedLecture({
    required this.lecture,
    required this.start,
    required this.end,
    required this.conducted,
  });
}

class _MonthCount {
  final int attended; // present + late
  final int total; // all conducted lectures in the range
  const _MonthCount(this.attended, this.total);

  double get percentage => total > 0 ? (attended / total) * 100 : 0.0;
}


class _StudentStats {
  final List<LectureModel> todaysLectures;
  final int streakLectures; // consecutive present/late, most recent first
  final int presentDays; // semester-to-date
  final int lateDays;
  final int absentDays;
  final _MonthCount thisMonth;
  final double lastMonthPercentage;
  final List<String> trendMonths;
  final List<double> trendPercentages;

  const _StudentStats({
    required this.todaysLectures,
    required this.streakLectures,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.thisMonth,
    required this.lastMonthPercentage,
    required this.trendMonths,
    required this.trendPercentages,
  });

  static const empty = _StudentStats(
    todaysLectures: [],
    streakLectures: 0,
    presentDays: 0,
    lateDays: 0,
    absentDays: 0,
    thisMonth: _MonthCount(0, 0),
    lastMonthPercentage: 0,
    trendMonths: [],
    trendPercentages: [],
  );
}

class StdHome extends StatefulWidget {
  const StdHome({super.key,required this.student});

  final Student student;

  @override
  State<StdHome> createState() => _StdHomeState();
}

class _StdHomeState extends State<StdHome> {
  late Future<_StudentStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStudentStats();
  }



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
      mid_point:
      raw['mid_point'] is bool ? raw['mid_point'] as bool : null,
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
    await NotifHelper.scheduledNotification("lecture", "chek-in reminder :", " ${lecture.course} lecture starting [Room # ${lecture.room}] in 10 minutes , make sure to not be mark late", notifDate);
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
    await NotifHelper.scheduledNotification("lecture", "chek-in reminder :", " ${lecture.course} lecture started in [Room # ${lecture.room}], make sure to not be mark late", lectureStart);
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
    await NotifHelper.scheduledNotification("lecture", "chek-out remainder :", " ${lecture.course} lecture ended , make sure to check-out", lectureEnd);
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
    await NotifHelper.scheduledNotification("lecture", "chek-in remainder :", " ${lecture.course} lecture ending soon in few minutes , make sure to check-out", notifDate);
  }


  static String? _statusFor(LectureModel lecture, String studentId) {
    final record =
    (lecture.attendance ?? []).firstWhereOrNull((a) => a.sid == studentId);
    return record?.status;
  }


  static String _resolvedStatus(LectureModel lecture, String studentId) {
    return _statusFor(lecture, studentId) ?? 'absent';
  }

  static bool _isAttended(String status) => status == 'present' || status == 'late';

  // vvvv=== fetchhing std ststz
  Future<_StudentStats> _fetchStudentStats() async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final student = widget.student;
      final studentId = student.id ?? '';

      // Every course this student is enrolled in.
      final myCourses = await dbService.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: student.insAdminId)
          .where("institute_id", isEqualTo: student.instituteId)
          .where("department_id", isEqualTo: student.departId)
          .where("session_id", isEqualTo: student.sessionId)
          .where("semester_id", isEqualTo: student.semesterId)
          .get();
      debugPrint('courses: ${myCourses.docs.length}');
      if (myCourses.docs.isEmpty) return _StudentStats.empty;
      final lectureSnapshots = await Future.wait(myCourses.docs.map((courseDoc) {
        return dbService.dbref
            .collection("ins_admins")
            .doc(student.insAdminId)
            .collection("institutes")
            .doc(student.instituteId)
            .collection("departments")
            .doc(student.departId)
            .collection("sessions")
            .doc(student.sessionId)
            .collection("semesters")
            .doc(student.semesterId)
            .collection("courses")
            .doc(courseDoc.id)
            .collection("lectures")
            .get();
      }));

      final allLectures = <LectureModel>[
        for (final snap in lectureSnapshots)
          for (final doc in snap.docs) _lectureFromDoc(doc.id, doc.data()),
      ];

      for (final lecture in allLectures) {
        try {
          await scheduleLectureNotificationBeforeStart(lecture);
          await scheduleLectureNotificationStart(lecture);
          await scheduleLectureNotificationBeforeEnd(lecture);
          await scheduleLectureNotificationEnd(lecture);
        }catch(e){
          print("error-x $e");
        }
      }
      return _buildStats(allLectures, studentId);

    } catch (e) {
      debugPrint("StdHome._fetchStudentStats error: $e");
      return _StudentStats.empty;
    }
  }

  _StudentStats _buildStats(List<LectureModel> allLectures, String studentId) {
    final now = DateTime.now();

    final todaysLectures =
    allLectures.where((l) => DateUtils.isSameDay(l.dated, now)).toList();

    final resolved = allLectures.map((l) {
      final start = _combineDateAndTime(l.dated, l.start_time);
      final end = _combineDateAndTime(l.dated, l.end_time);
      return _ResolvedLecture(
        lecture: l,
        start: start,
        end: end,
        conducted: now.isAfter(end),
      );
    }).toList();

    final conducted = resolved.where((r) => r.conducted).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    var streak = 0;
    for (final r in conducted) {
      if (_isAttended(_resolvedStatus(r.lecture, studentId))) {
        streak++;
      } else {
        break;
      }
    }

    var present = 0, late = 0, absent = 0;
    for (final r in conducted) {
      switch (_resolvedStatus(r.lecture, studentId)) {
        case 'present':
          present++;
          break;
        case 'late':
          late++;
          break;
        default:
          absent++;
      }
    }

    _MonthCount countsForRange(DateTime start, DateTime endExclusive) {
      var attended = 0, total = 0;
      for (final r in conducted) {
        if (r.start.isBefore(start) || !r.start.isBefore(endExclusive)) continue;
        total++;
        if (_isAttended(_resolvedStatus(r.lecture, studentId))) attended++;
      }
      return _MonthCount(attended, total);
    }

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 1);
    final thisMonth = countsForRange(thisMonthStart, thisMonthEnd);

    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart;
    final lastMonth = countsForRange(lastMonthStart, lastMonthEnd);


    final trendMonths = <String>[];
    final trendPercentages = <double>[];
    for (var i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final rangeStart = DateTime(monthDate.year, monthDate.month, 1);
      final rangeEnd = DateTime(monthDate.year, monthDate.month + 1, 1);
      final counts = countsForRange(rangeStart, rangeEnd);
      if (counts.total == 0) continue;
      trendMonths.add(_monthAbbrev[monthDate.month - 1]);
      trendPercentages.add(counts.percentage);
    }

    return _StudentStats(
      todaysLectures: todaysLectures,
      streakLectures: streak,
      presentDays: present,
      lateDays: late,
      absentDays: absent,
      thisMonth: thisMonth,
      lastMonthPercentage: lastMonth.percentage,
      trendMonths: trendMonths,
      trendPercentages: trendPercentages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentId = widget.student.id ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(12),
      child: ListView(
        children: [
          _WelcomeHeader(studentName: widget.student.name),
          const SizedBox(height: 25),

          FutureBuilder<_StudentStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? _StudentStats.empty;
              return _TodayAttendanceCard(
                connectionState: snapshot.connectionState,
                error: snapshot.error,
                todaysLectures: stats.todaysLectures,
                studentId: studentId,
                streakLectures: stats.streakLectures,
                thisMonthPercent: stats.thisMonth.percentage.round(),
              );
            },
          ),
          const SizedBox(height: 15),

          FutureBuilder<_StudentStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? _StudentStats.empty;
              return AttRecCard(
                present_days: stats.presentDays,
                late_days: stats.lateDays,
                absent_days: stats.absentDays,
              );
            },
          ),
          const SizedBox(height: 25),

          FutureBuilder<_StudentStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? _StudentStats.empty;
              final totalDays = stats.thisMonth.total > 0 ? stats.thisMonth.total.toDouble() : 1.0;
              final thisMonthAttended = stats.thisMonth.total > 0 ? stats.thisMonth.attended.toDouble() : 0.0;
              return OverAllAttCard(
                thisMonth: thisMonthAttended,
                lastMonth: stats.lastMonthPercentage,
                totalDays: totalDays,
              );
            },
          ),
          const SizedBox(height: 20),

          FutureBuilder<_StudentStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? _StudentStats.empty;
              if (stats.trendMonths.isEmpty) return const SizedBox.shrink();
              return CustomeLineChart(
                Months: stats.trendMonths,
                StudentPersetage: stats.trendPercentages,
              );
            },
          ),
          const SizedBox(height: 20),

          const _SectionHeader(title: "Today's lectures"),
          const SizedBox(height: 7),
          FutureBuilder<_StudentStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }

              final todaysLectures = List<LectureModel>.from(
                  (snapshot.data ?? _StudentStats.empty).todaysLectures)
                ..sort((a, b) => _combineDateAndTime(a.dated, a.start_time)
                    .compareTo(_combineDateAndTime(b.dated, b.start_time)));

              if (todaysLectures.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No lectures today",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: [
                  for (final lecture in todaysLectures)
                    Column(
                      children: [
                        InkWell(
                          child: UpcomingClassCard(lectureModel: lecture, studentId: studentId),
                        ),
                        LectureAttendanceSection(lectureModel: lecture, studentId: studentId),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.studentName});

  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        children: [
          const SizedBox(width: 5),
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage("assets/icons/user.png",),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome back!",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              Text(
                RMFuncts.getSentenceCase(studentName),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                "Have a productive day!",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayAttendanceCard extends StatelessWidget {
  const _TodayAttendanceCard({
    required this.connectionState,
    required this.error,
    required this.todaysLectures,
    required this.studentId,
    required this.streakLectures,
    required this.thisMonthPercent,
  });

  final ConnectionState connectionState;
  final Object? error;
  final List<LectureModel> todaysLectures;
  final String studentId;
  final int streakLectures;
  final int thisMonthPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Attendance",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatusRow(),
          const SizedBox(height: 15),
          const Divider(thickness: 1.5, color: Colors.white),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: Colors.orange.shade400,
                  label: "Streak",
                  value: streakLectures == 1
                      ? "1 lecture"
                      : "$streakLectures lectures",
                ),
              ),
              Container(
                width: 0.5,
                height: 60,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _StatItem(
                  icon: CupertinoIcons.arrow_2_circlepath_circle,
                  iconColor: Colors.lightBlue.shade400,
                  label: "This Month",
                  value: "$thisMonthPercent%",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    if (connectionState == ConnectionState.waiting) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        ),
      );
    }
    if (error != null) {
      return Text("Error: $error", style: const TextStyle(color: Colors.white));
    }
    if (todaysLectures.isEmpty) {
      return const Text("No lectures today", style: TextStyle(color: Colors.white));
    }

    final presentCount = todaysLectures
        .where((l) => _StdHomeState._isAttended(_StdHomeState._resolvedStatus(l, studentId)))
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              for (final lecture in todaysLectures) _statusIcon(lecture),
            ],
          ),
        ),
        Text(
          "($presentCount/${todaysLectures.length})",
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _statusIcon(LectureModel lecture) {
    final rawStatus = _StdHomeState._statusFor(lecture, studentId);
    final IconData icon;
    if (rawStatus == null) {
      icon = Icons.circle_outlined; // not marked yet (upcoming/ongoing)
    } else if (rawStatus == 'present' || rawStatus == 'late') {
      icon = Icons.check_circle_outline;
    } else {
      icon = Icons.cancel_outlined;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 7),
        Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        GestureDetector(
          onTap: onViewAll,
          child: const Text(
            "view all",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

}