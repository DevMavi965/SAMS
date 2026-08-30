import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class FacWeeklyAttendanceChart extends StatelessWidget {
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

  // Returns 5 buckets (Mon..Fri), each [present, absent, late] — summed
  // across every lecture this lecturer's courses held this week.
  Future<List<List<int>>> _weeklyAttendanceByDay(BuildContext context) async {
    final db = Provider.of<DbService>(context, listen: false);
    final buckets = List.generate(5, (_) => [0, 0, 0]); // Mon..Fri

    final now = DateTime.now();
    final startOfWeek =
    DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    try {
      final courseX = await db.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdmin.id)
          .where("institute_id", isEqualTo: institute.id)
          .where("department_id", isEqualTo: department.id)
          .where("lecturer_id", isEqualTo: lecturer.id)
          .get();

      for (var course in courseX.docs) {
        final sessionId = course['session_id'];
        final semesterId = course['semester_id'];
        final courseId = course.id;

        final lectureSnap = await db.dbref
            .collection("ins_admins").doc(insAdmin.id)
            .collection("institutes").doc(institute.id)
            .collection("departments").doc(department.id)
            .collection("sessions").doc(sessionId)
            .collection("semesters").doc(semesterId)
            .collection("courses").doc(courseId)
            .collection("lectures")
            .get();

        for (var lec in lectureSnap.docs) {
          final datedRaw = lec['dated'];
          final dated = datedRaw is Timestamp ? datedRaw.toDate() : datedRaw as DateTime;

          // skip lectures outside this week or on Sat/Sun
          if (dated.isBefore(startOfWeek) || !dated.isBefore(endOfWeek)) continue;
          if (dated.weekday > 5) continue;

          final dayIndex = dated.weekday - 1; // Mon=0 .. Fri=4
          final attendanceRaw = lec['attendance'] as List<dynamic>? ?? [];

          for (var a in attendanceRaw) {
            final status = (a as Map<String, dynamic>)['status'];
            if (status == "present") buckets[dayIndex][0]++;
            if (status == "absent") buckets[dayIndex][1]++;
            if (status == "late") buckets[dayIndex][2]++;
          }
        }
      }
      return buckets;
    } catch (e) {
      print(e.toString());
      return buckets; // all zeros on failure
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 17),
            SizedBox(
              height: 250,
              child: FutureBuilder<List<List<int>>>(
                future: _weeklyAttendanceByDay(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bar = snapshot.data ?? List.generate(5, (_) => [0, 0, 0]);

                  return BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: Colors.grey, width: 1),
                          left: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, meta) {
                              const days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
                              final i = v.toInt();
                              return Text(i >= 0 && i < days.length ? days[i] : "");
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(bar.length, (i) {
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(toY: bar[i][0].toDouble(), color: Colors.green, borderRadius: BorderRadius.circular(0), width: 10),
                          BarChartRodData(toY: bar[i][1].toDouble(), color: Colors.red, borderRadius: BorderRadius.circular(0), width: 10),
                          BarChartRodData(toY: bar[i][2].toDouble(), color: Colors.brown, borderRadius: BorderRadius.circular(0), width: 10),
                        ]);
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}