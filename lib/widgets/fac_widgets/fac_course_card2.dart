import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class _CourseReportData {
  final String name;
  final String courseCode;
  final String sessionName;
  final int semesterNo;
  final int studentCount;
  final double avgAttendance; // 0..100
  // kept so "View Details" can re-query this exact course's roster
  final String sessionId;
  final String semesterId;
  final String courseId;

  _CourseReportData({
    required this.name,
    required this.courseCode,
    required this.sessionName,
    required this.semesterNo,
    required this.studentCount,
    required this.avgAttendance,
    required this.sessionId,
    required this.semesterId,
    required this.courseId,
  });
}

class FacCourseWiseList extends StatelessWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const FacCourseWiseList({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.lecturer,
  });

  Future<List<_CourseReportData>> _fetchCourseData(BuildContext context) async {
    final db = Provider.of<DbService>(context, listen: false);
    final List<_CourseReportData> result = [];

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

        final courseDoc = await db.dbref
            .collection("ins_admins").doc(insAdmin.id)
            .collection("institutes").doc(institute.id)
            .collection("departments").doc(department.id)
            .collection("sessions").doc(sessionId)
            .collection("semesters").doc(semesterId)
            .collection("courses").doc(courseId)
            .get();

        if (!courseDoc.exists) continue;
        final courseName = courseDoc['name'] ?? "Untitled Course";
        final courseCode = courseDoc['course_code'] ?? "";

        final sessionDoc = await db.dbref
            .collection("ins_admins").doc(insAdmin.id)
            .collection("institutes").doc(institute.id)
            .collection("departments").doc(department.id)
            .collection("sessions").doc(sessionId)
            .get();
        final sessionName = sessionDoc.exists ? (sessionDoc['name'] ?? "") : "";

        final semesterDoc = await db.dbref
            .collection("ins_admins").doc(insAdmin.id)
            .collection("institutes").doc(institute.id)
            .collection("departments").doc(department.id)
            .collection("sessions").doc(sessionId)
            .collection("semesters").doc(semesterId)
            .get();
        final semesterNo = semesterDoc.exists ? (semesterDoc['semester_no'] ?? 0) : 0;

        final studentX = await db.indexDoc
            .where("role", isEqualTo: "student")
            .where("ins_admin_id", isEqualTo: insAdmin.id)
            .where("institute_id", isEqualTo: institute.id)
            .where("department_id", isEqualTo: department.id)
            .where("session_id", isEqualTo: sessionId)
            .where("semester_id", isEqualTo: semesterId)
            .get();
        final rosterSize = studentX.docs.length;

        final lectureSnap = await db.dbref
            .collection("ins_admins").doc(insAdmin.id)
            .collection("institutes").doc(institute.id)
            .collection("departments").doc(department.id)
            .collection("sessions").doc(sessionId)
            .collection("semesters").doc(semesterId)
            .collection("courses").doc(courseId)
            .collection("lectures")
            .get();

        int presentCount = 0;
        for (var lec in lectureSnap.docs) {
          final attendanceRaw = lec['attendance'] as List<dynamic>? ?? [];
          presentCount += attendanceRaw.where((a) {
            final status = (a as Map<String, dynamic>)['status'];
            return status == "present" || status == "late";
          }).length;
        }

        final avgAttendance = (rosterSize > 0 && lectureSnap.docs.isNotEmpty)
            ? (presentCount / (rosterSize * lectureSnap.docs.length)) * 100
            : 0.0;

        result.add(_CourseReportData(
          name: courseName,
          courseCode: courseCode,
          sessionName: sessionName,
          semesterNo: semesterNo,
          studentCount: rosterSize,
          avgAttendance: avgAttendance,
          sessionId: sessionId,
          semesterId: semesterId,
          courseId: courseId,
        ));
      }
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  // Only called when "View Details" is tapped — real student docs (name,
  // email) aren't fetched up front for every card, since that would mean
  // N extra reads per course just to populate a list nobody may open.
  Future<List<Map<String, dynamic>>> _fetchRoster(
      BuildContext context,
      String sessionId,
      String semesterId,
      ) async {
    final db = Provider.of<DbService>(context, listen: false);
    final snap = await db.dbref
        .collection("ins_admins").doc(insAdmin.id)
        .collection("institutes").doc(institute.id)
        .collection("departments").doc(department.id)
        .collection("sessions").doc(sessionId)
        .collection("semesters").doc(semesterId)
        .collection("students")
        .get();

    return snap.docs
        .map((d) => {
      "name": d['name'] ?? "Unnamed student",
      "email": d['email'] ?? "",
    })
        .toList()
      ..sort((a, b) => (a["name"] as String).compareTo(b["name"] as String));
  }

  void _showRosterSheet(BuildContext context, _CourseReportData c, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xffE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${c.studentCount} students enrolled",
                                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xffF0F1F4)),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchRoster(context, c.sessionId, c.semesterId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final roster = snapshot.data ?? [];
                        if (roster.isEmpty) {
                          return const Center(
                            child: Text("No students found", style: TextStyle(color: Colors.grey)),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: roster.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xffF5F5F5)),
                          itemBuilder: (context, i) {
                            final s = roster[i];
                            final initial = (s["name"] as String).isNotEmpty
                                ? (s["name"] as String)[0].toUpperCase()
                                : "?";
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.12),
                                child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                              ),
                              title: Text(s["name"], style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: (s["email"] as String).isNotEmpty ? Text(s["email"]) : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _attendanceColor(double pct) {
    if (pct >= 75) return const Color.fromARGB(255, 67, 186, 125); // green
    if (pct >= 50) return const Color(0xffF59E0B); // amber
    return const Color(0xffE53935); // red
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_CourseReportData>>(
      future: _fetchCourseData(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text("No courses found", style: TextStyle(color: Colors.grey))),
          );
        }

        return Column(
          children: [
            for (var c in courses) ...[
              Builder(builder: (context) {
                final color = _attendanceColor(c.avgAttendance);
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xffF0F1F4), width: 1),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(PhosphorIconsBold.bookOpen, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xff1A1D1F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (c.courseCode.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.courseCode,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xff64748B),
                                          ),
                                        ),
                                      ),
                                    if (c.semesterNo > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Sem ${c.semesterNo}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    if (c.sessionName.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.calendar_month_rounded,
                                              size: 12, color: Colors.grey.shade500),
                                          const SizedBox(width: 3),
                                          Text(
                                            c.sessionName,
                                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.people_alt_rounded, size: 13, color: Colors.grey.shade500),
                                    const SizedBox(width: 3),
                                    Text(
                                      "${c.studentCount} students",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${c.avgAttendance.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Average Attendance",
                              style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                          Text(
                            "${c.avgAttendance.toStringAsFixed(0)}%",
                            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: (c.avgAttendance / 100).clamp(0, 1),
                          backgroundColor: const Color(0xffF1F5F9),
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showRosterSheet(context, c, color),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xfff8fafc),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffE2E8F0), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "View Details",
                                style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}