import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class FacCustomLinechart extends StatelessWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const FacCustomLinechart({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.lecturer,
  });

  static const List<String> _monthNames = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  // Attendance % for each of the last 6 calendar months, computed across
  // every lecture in every course this lecturer teaches.
  Future<Map<String, double>> _monthlyTrend(BuildContext context) async {
    final db = Provider.of<DbService>(context, listen: false);
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final result = <String, double>{
      for (var m in months) _monthNames[m.month - 1]: 0,
    };

    try {
      final courseX = await db.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdmin.id)
          .where("institute_id", isEqualTo: institute.id)
          .where("department_id", isEqualTo: department.id)
          .where("lecturer_id", isEqualTo: lecturer.id)
          .get();

      // present/absent/late counts and roster size per month, accumulated
      // across all courses before computing final percentages.
      final Map<String, int> presentByMonth = {for (var m in months) _monthNames[m.month - 1]: 0};
      final Map<String, int> totalByMonth = {for (var m in months) _monthNames[m.month - 1]: 0};

      for (var course in courseX.docs) {
        final sessionId = course['session_id'];
        final semesterId = course['semester_id'];
        final courseId = course.id;

        final studentX = await db.indexDoc
            .where("role", isEqualTo: "student")
            .where("ins_admin_id", isEqualTo: insAdmin.id)
            .where("institute_id", isEqualTo: institute.id)
            .where("department_id", isEqualTo: department.id)
            .where("session_id", isEqualTo: sessionId)
            .where("semester_id", isEqualTo: semesterId)
            .get();
        final rosterSize = studentX.docs.length;
        if (rosterSize == 0) continue;

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

          final monthMatch = months.firstWhere(
                (m) => m.year == dated.year && m.month == dated.month,
            orElse: () => DateTime(0),
          );
          if (monthMatch.year == 0) continue; // outside the 6-month window

          final label = _monthNames[monthMatch.month - 1];
          final attendanceRaw = lec['attendance'] as List<dynamic>? ?? [];
          final present = attendanceRaw.where((a) {
            final status = (a as Map<String, dynamic>)['status'];
            return status == "present" || status == "late";
          }).length;

          presentByMonth[label] = (presentByMonth[label] ?? 0) + present;
          totalByMonth[label] = (totalByMonth[label] ?? 0) + rosterSize;
        }
      }

      for (var m in months) {
        final label = _monthNames[m.month - 1];
        final total = totalByMonth[label] ?? 0;
        result[label] = total == 0 ? 0 : ((presentByMonth[label] ?? 0) / total) * 100;
      }
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Card(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Row(
              children: [
                SizedBox(width: 20),
                Text("6-Month Attendance Trends",
                    textAlign: TextAlign.left,
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: _monthlyTrend(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final trend = snapshot.data ?? {};
                  final months = trend.keys.toList();
                  final percentages = trend.values.toList();

                  if (months.isEmpty) {
                    return const Center(
                      child: Text("No attendance data yet", style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: LineChart(

                      LineChartData(

                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.grey, width: 1),
                            left: BorderSide(color: Colors.grey, width: 1),
                          ),
                        ),
                        gridData: FlGridData(show: false),
                        minX: 0,
                        minY: 0,
                        maxX: (percentages.length - 1).toDouble(),
                        maxY: 100,
                        titlesData: FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                return Text(i >= 0 && i < months.length ? months[i] : "");
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              minIncluded: true,
                              reservedSize: 35,
                              interval: 25,
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            color: const Color.fromARGB(255, 0, 153, 136),
                            isCurved: false,
                            belowBarData: BarAreaData(
                              show: false,
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.fromARGB(120, 0, 153, 136),
                                  Color.fromARGB(60, 0, 153, 136),
                                ],
                              ),
                            ),
                            spots: [
                              for (int i = 0; i < percentages.length; i++)
                                FlSpot(i.toDouble(), percentages[i]),
                            ],
                          ),
                        ],
                      ),
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