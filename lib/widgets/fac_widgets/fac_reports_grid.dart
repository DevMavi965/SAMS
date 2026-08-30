import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class FacReportsGrid extends StatelessWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const FacReportsGrid({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.lecturer,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // classes this week
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 0.5, color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.calendar_today_outlined, color: Theme.of(context).primaryColor),
              FutureBuilder<int>(
                future: getNoOfLectThisWeek(context, insAdmin.id!, institute.id!, department.id!, lecturer.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...");
                  } else if (snapshot.hasError) {
                    return const Text("0");
                  }
                  return Text(
                    (snapshot.data ?? 0).toString(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                  );
                },
              ),
              const Text("Classes this week", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        // total students
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 0.5, color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.people_alt_outlined, color: Colors.lightBlue),
              FutureBuilder<int>(
                future: getTotalStudents(context, insAdmin.id!, institute.id!, department.id!, lecturer.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...");
                  } else if (snapshot.hasError) {
                    return const Text("0");
                  }
                  return Text(
                    (snapshot.data ?? 0).toString(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                  );
                },
              ),
              const Text("Total Students", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        // avg attendance
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 0.5, color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.trendUp, color: Theme.of(context).primaryColor),
              FutureBuilder<double>(
                future: getAvgAttendance(context, insAdmin.id!, institute.id!, department.id!, lecturer.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...");
                  } else if (snapshot.hasError) {
                    return const Text("0%");
                  }
                  return Text(
                    "${(snapshot.data ?? 0).toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                  );
                },
              ),
              const Text("Avg Attendance", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        // total lectures
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 0.5, color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(PhosphorIconsDuotone.notebook, color: Colors.red),
              FutureBuilder<int>(
                future: getTotalLectures(context, insAdmin.id!, institute.id!, department.id!, lecturer.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...");
                  } else if (snapshot.hasError) {
                    return const Text("0");
                  }
                  return Text(
                    (snapshot.data ?? 0).toString(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                  );
                },
              ),
              const Text("Total Lectures", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Future<int> getNoOfLectThisWeek(
      BuildContext context,
      String insAdminId,
      String instituteId,
      String departmentId,
      String lecturerId,
      ) async {
    final db = Provider.of<DbService>(context, listen: false);

    final now = DateTime.now();
    final startOfWeek =
    DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    try {
      final courseX = await db.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdminId)
          .where("institute_id", isEqualTo: instituteId)
          .where("department_id", isEqualTo: departmentId)
          .where("lecturer_id", isEqualTo: lecturerId)
          .get();

      int count = 0;
      for (var course in courseX.docs) {
        final lectureX = await db.indexDoc
            .where("type", isEqualTo: "lecture")
            .where("ins_admin_id", isEqualTo: insAdminId)
            .where("institute_id", isEqualTo: instituteId)
            .where("department_id", isEqualTo: departmentId)
            .where("course_id", isEqualTo: course.id)
            .get();

        for (var lec in lectureX.docs) {
          final datedRaw = lec['dated'];
          final dated = datedRaw is Timestamp ? datedRaw.toDate() : datedRaw as DateTime;

          if (!dated.isBefore(startOfWeek) && dated.isBefore(endOfWeek)) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  // Distinct students across every semester this lecturer teaches in.
  // Dedups by student doc id since the lecturer may teach multiple
  // courses within the same semester.
  Future<int> getTotalStudents(
      BuildContext context,
      String insAdminId,
      String instituteId,
      String departmentId,
      String lecturerId,
      ) async {
    final db = Provider.of<DbService>(context, listen: false);
    try {
      final courseX = await db.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdminId)
          .where("institute_id", isEqualTo: instituteId)
          .where("department_id", isEqualTo: departmentId)
          .where("lecturer_id", isEqualTo: lecturerId)
          .get();

      final Set<String> studentIds = {};
      for (var course in courseX.docs) {
        final sessionId = course['session_id'];
        final semesterId = course['semester_id'];

        final studentX = await db.indexDoc
            .where("role", isEqualTo: "student")
            .where("ins_admin_id", isEqualTo: insAdminId)
            .where("institute_id", isEqualTo: instituteId)
            .where("department_id", isEqualTo: departmentId)
            .where("session_id", isEqualTo: sessionId)
            .where("semester_id", isEqualTo: semesterId)
            .get();

        for (var s in studentX.docs) {
          studentIds.add(s.id);
        }
      }
      return studentIds.length;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  // Total lecture count across all of this lecturer's courses (all-time,
  // not just this week) — counted via the index collection only, so it
  // stays cheap: no need to open each actual lecture doc for this.
  Future<int> getTotalLectures(
      BuildContext context,
      String insAdminId,
      String instituteId,
      String departmentId,
      String lecturerId,
      ) async {
    final db = Provider.of<DbService>(context, listen: false);
    try {
      final courseX = await db.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdminId)
          .where("institute_id", isEqualTo: instituteId)
          .where("department_id", isEqualTo: departmentId)
          .where("lecturer_id", isEqualTo: lecturerId)
          .get();

      int total = 0;
      for (var course in courseX.docs) {
        final lectureX = await db.indexDoc
            .where("type", isEqualTo: "lecture")
            .where("ins_admin_id", isEqualTo: insAdminId)
            .where("institute_id", isEqualTo: instituteId)
            .where("department_id", isEqualTo: departmentId)
            .where("course_id", isEqualTo: course.id)
            .get();
        total += lectureX.docs.length;
      }
      return total;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  // Weighted average attendance % across all of this lecturer's courses.
  // Needs the real "attendance" field, which only lives on the actual
  // lecture docs (not the index), so this reaches into db.dbref for
  // each course rather than staying index-only like the counts above.
  Future<double> getAvgAttendance(
      BuildContext context,
      String insAdminId,
      String instituteId,
      String departmentId,
      String lecturerId,
      ) async {
    final db = Provider.of<DbService>(context, listen: false);
    try {
      final courseX = await db.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdminId)
          .where("institute_id", isEqualTo: instituteId)
          .where("department_id", isEqualTo: departmentId)
          .where("lecturer_id", isEqualTo: lecturerId)
          .get();

      if (courseX.docs.isEmpty) return 0;

      double weightedSum = 0;
      int totalWeight = 0;

      for (var course in courseX.docs) {
        final sessionId = course['session_id'];
        final semesterId = course['semester_id'];
        final courseId = course.id;

        final studentX = await db.indexDoc
            .where("role", isEqualTo: "student")
            .where("ins_admin_id", isEqualTo: insAdminId)
            .where("institute_id", isEqualTo: instituteId)
            .where("department_id", isEqualTo: departmentId)
            .where("session_id", isEqualTo: sessionId)
            .where("semester_id", isEqualTo: semesterId)
            .get();
        final semesterStudentCount = studentX.docs.length;
        if (semesterStudentCount == 0) continue;

        final lectureSnap = await db.dbref
            .collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("departments").doc(departmentId)
            .collection("sessions").doc(sessionId)
            .collection("semesters").doc(semesterId)
            .collection("courses").doc(courseId)
            .collection("lectures")
            .get();
        if (lectureSnap.docs.isEmpty) continue;

        int presentCount = 0;
        for (var lec in lectureSnap.docs) {
          final attendanceRaw = lec['attendance'] as List<dynamic>? ?? [];
          presentCount += attendanceRaw.where((a) {
            final status = (a as Map<String, dynamic>)['status'];
            return status == "present" || status == "late";
          }).length;
        }

        final coursePercentage =
            (presentCount / (semesterStudentCount * lectureSnap.docs.length)) * 100;

        weightedSum += coursePercentage * lectureSnap.docs.length;
        totalWeight += lectureSnap.docs.length;
      }

      if (totalWeight == 0) return 0;
      return weightedSum / totalWeight;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }
}