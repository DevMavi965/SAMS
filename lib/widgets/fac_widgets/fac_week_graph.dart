import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class FacWeeklyAttendanceChart extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;

  const FacWeeklyAttendanceChart({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.lecturer,
  });

  @override
  State<FacWeeklyAttendanceChart> createState() => _FacWeeklyAttendanceChartState();
}

class _FacWeeklyAttendanceChartState extends State<FacWeeklyAttendanceChart> {
  StreamSubscription<QuerySnapshot>? _courseIndexSub;
  final Map<String, StreamSubscription<QuerySnapshot>> _lectureSubs = {};
  final Map<String, List<QueryDocumentSnapshot>> _lecturesByCourse = {};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listenToCourses();
  }

  void _listenToCourses() {
    final db = Provider.of<DbService>(context, listen: false);

    _courseIndexSub = db.indexDoc
        .where("type", isEqualTo: "course")
        .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
        .where("institute_id", isEqualTo: widget.institute.id)
        .where("department_id", isEqualTo: widget.department.id)
        .where("lecturer_id", isEqualTo: widget.lecturer.id)
        .snapshots()
        .listen((courseSnap) {
      final currentIds = courseSnap.docs.map((d) => d.id).toSet();

      // Stop listening to courses no longer assigned to this lecturer
      final staleIds = _lectureSubs.keys.where((id) => !currentIds.contains(id)).toList();
      for (final id in staleIds) {
        _lectureSubs.remove(id)?.cancel();
        _lecturesByCourse.remove(id);
      }

      // Start listening to any newly-seen course's lectures
      for (final courseDoc in courseSnap.docs) {
        final courseId = courseDoc.id;
        if (_lectureSubs.containsKey(courseId)) continue;

        final data = courseDoc.data() as Map<String, dynamic>;
        final sessionId = data['session_id'];
        final semesterId = data['semester_id'];
        if (sessionId == null || semesterId == null) continue;

        final lecturesRef = db.dbref
            .collection("ins_admins").doc(widget.insAdmin.id)
            .collection("institutes").doc(widget.institute.id)
            .collection("departments").doc(widget.department.id)
            .collection("sessions").doc(sessionId)
            .collection("semesters").doc(semesterId)
            .collection("courses").doc(courseId)
            .collection("lectures");

        _lectureSubs[courseId] = lecturesRef.snapshots().listen((lecSnap) {
          _lecturesByCourse[courseId] = lecSnap.docs;
          if (mounted) setState(() => _loading = false);
        }, onError: (e) {
          if (mounted) setState(() {
            _error = e.toString();
            _loading = false;
          });
        });
      }

      if (currentIds.isEmpty && mounted) {
        setState(() => _loading = false);
      }
    }, onError: (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _courseIndexSub?.cancel();
    for (final sub in _lectureSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  // 5 buckets (Mon..Fri), each [present, absent, late]
  List<List<int>> _computeBuckets() {
    final buckets = List.generate(5, (_) => [0, 0, 0]);

    final now = DateTime.now();
    final startOfWeek =
    DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (final lectures in _lecturesByCourse.values) {
      for (final lecDoc in lectures) {
        final data = lecDoc.data() as Map<String, dynamic>;

        final datedRaw = data['dated'];
        if (datedRaw == null) continue;
        final dated = datedRaw is Timestamp ? datedRaw.toDate() : datedRaw as DateTime;

        if (dated.isBefore(startOfWeek) || !dated.isBefore(endOfWeek)) continue;
        if (dated.weekday > 5) continue; // skip Sat/Sun

        final dayIndex = dated.weekday - 1; // Mon=0 .. Fri=4
        final attendanceRaw = data['attendance'] as List<dynamic>? ?? [];

        for (final a in attendanceRaw) {
          if (a is! Map) continue;
          // trim + lowercase so "Present ", "PRESENT", etc. all match
          final status = (a['status'] as String?)?.trim().toLowerCase();
          switch (status) {
            case "present":
              buckets[dayIndex][0]++;
              break;
            case "absent":
              buckets[dayIndex][1]++;
              break;
            case "late":
              buckets[dayIndex][2]++;
              break;
          }
        }
      }
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final bar = _computeBuckets();
    final maxCount = bar.expand((b) => b).fold<int>(0, (m, v) => v > m ? v : m);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          children: [
            const Row(
              children: [
                Text("This Week Overview", style: TextStyle(fontWeight: FontWeight.w400)),
              ],
            ),
            const SizedBox(height: 10),
            const _Legend(),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Text(
                  "Couldn't load attendance",
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
                  : BarChart(
                BarChartData(
                  maxY: maxCount == 0 ? 5 : (maxCount + 1).toDouble(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey, width: 1),
                      left: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  titlesData: FlTitlesData(
                    rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          if (v != v.roundToDouble()) return const SizedBox.shrink();
                          return Text(
                            v.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          const days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
                          final i = v.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(i >= 0 && i < days.length ? days[i] : ""),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(bar.length, (i) {
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: bar[i][0].toDouble(),
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2),
                        width: 10,
                      ),
                      BarChartRodData(
                        toY: bar[i][1].toDouble(),
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(2),
                        width: 10,
                      ),
                      BarChartRodData(
                        toY: bar[i][2].toDouble(),
                        color: Colors.brown,
                        borderRadius: BorderRadius.circular(2),
                        width: 10,
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(Colors.green, "Present"),
        const SizedBox(width: 14),
        dot(Colors.red, "Absent"),
        const SizedBox(width: 14),
        dot(Colors.brown, "Late"),
      ],
    );
  }
}