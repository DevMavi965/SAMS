import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class FacAttendanceDistributionChart extends StatelessWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const FacAttendanceDistributionChart({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.lecturer,
  });

  // Totals present/absent/late across every lecture in every course this
  // lecturer teaches (all-time, not scoped to a week — a distribution
  // chart benefits from the full dataset rather than a 7-day slice).
  Future<Map<String, int>> _attendanceTotals(BuildContext context) async {
    final db = Provider.of<DbService>(context, listen: false);
    int present = 0, absent = 0, late = 0;

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
          final attendanceRaw = lec['attendance'] as List<dynamic>? ?? [];
          for (var a in attendanceRaw) {
            final status = (a as Map<String, dynamic>)['status'];
            if (status == "present") present++;
            if (status == "absent") absent++;
            if (status == "late") late++;
          }
        }
      }
    } catch (e) {
      print(e.toString());
    }
    return {"present": present, "absent": absent, "late": late};
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              const Row(
                children: [
                  SizedBox(width: 10),
                  Text("Attendance Distribution", style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _attendanceTotals(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data ?? {"present": 0, "absent": 0, "late": 0};
                    final present = data["present"]!;
                    final absent = data["absent"]!;
                    final late = data["late"]!;
                    final total = present + absent + late;

                    if (total == 0) {
                      return const Center(
                        child: Text("No attendance data yet", style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: PieChart(
                              PieChartData(
                                startDegreeOffset: 50,
                                sections: [
                                  PieChartSectionData(
                                    showTitle: false,
                                    color: Theme.of(context).primaryColor.withAlpha(210),
                                    value: present.toDouble(),
                                  ),
                                  PieChartSectionData(
                                    showTitle: false,
                                    color: Colors.red.withAlpha(220),
                                    value: absent.toDouble(),
                                  ),
                                  PieChartSectionData(
                                    showTitle: false,
                                    color: Colors.brown.withAlpha(230),
                                    value: late.toDouble(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.circle, color: Theme.of(context).primaryColor, size: 14),
                                  const SizedBox(width: 5),
                                  Text("Present : $present", style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.circle, color: Colors.red, size: 14),
                                  const SizedBox(width: 5),
                                  Text("Absent : $absent", style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.circle, color: Colors.brown, size: 14),
                                  const SizedBox(width: 5),
                                  Text("Late : $late", style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}