import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/attendance.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class FacHomeGrid extends StatelessWidget {

  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const FacHomeGrid({super.key, required this.insAdmin, required this.institute, required this.department, required this.lecturer,});

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        //students
        Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_outlined,color: Colors.lightBlue,),
              FutureBuilder(future: getStudentCount(context, insAdmin.id!, institute.id!, lecturer.id!),
                  builder: (count,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return Text("Loading...");
                    }else if(snapshot.hasError){
                      return Text("Error: ${snapshot.error}");
                    }else if(!snapshot.hasData || snapshot.data==null){
                      return Text("0");
                    }else if(snapshot.hasData){
                      return Text("${snapshot.data}",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),);
                    } return SizedBox();
                  }),
              Text("Total Students",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //present today
        Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline,color: Theme.of(context).primaryColor,),
              FutureBuilder(
                future: getPresentTodayCount(context, insAdmin.id!, institute.id!, lecturer.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading...");
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Text("0");
                  }
                  return Text(
                    "${snapshot.data}",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  );
                },
              ),
              Text("Present Today",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //avg attendance
        Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.trendUp,color:Theme.of(context).primaryColor,),
              FutureBuilder(
                future: getAvgAtt(context, insAdmin.id!, institute.id!,department.id!, lecturer.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading...");
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Text("0");
                  }
                  final pct = snapshot.data as double;
                  return Text(
                    "${pct.toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  );
                },
              ),
              Text("Avg Attendance",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //pending classes
        Container(
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.clock,color:Colors.red,),
              FutureBuilder(
                future: getPendingClassesTodayCount(context, insAdmin.id!, institute.id!, lecturer.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading...");
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return Text("0");
                  }
                  return Text(
                    "${snapshot.data}",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  );
                },
              ),
              Text("Pending Classes",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),

      ],
    );
  }

  // ---- shared helper: resolve this lecturer's courses via the course index ----
  // Course index docs (written in DbService.addCourse) carry lecturer_id.
  // Lecture index docs do NOT carry lecturer_id, so lecture-level lookups
  // must always start from the lecturer's courses, not indexDoc type=="lecture".
  Future<List<Map<String, dynamic>>> _myCourseRefs(
      BuildContext context, String insAdminId, String instituteId, String lecId) async {
    final dbService = Provider.of<DbService>(context, listen: false);

    final myCourses = await dbService.indexDoc
        .where("type", isEqualTo: "course")
        .where("ins_admin_id", isEqualTo: insAdminId)
        .where("institute_id", isEqualTo: instituteId)
        .where("lecturer_id", isEqualTo: lecId)
        .get();

    return myCourses.docs
        .map((doc) => {
      "course_id": doc.id,
      "session_id": doc.data()['session_id'],
      "semester_id": doc.data()['semester_id'],
    })
        .where((c) => c['session_id'] != null && c['semester_id'] != null)
        .toList();
  }

  Future<int> getPendingClassesTodayCount(BuildContext context, String insAdminId, String instituteId, String lecId) async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final courseRefs = await _myCourseRefs(context, insAdminId, instituteId, lecId);
      if (courseRefs.isEmpty) return 0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      int totalPending = 0;

      for (var c in courseRefs) {
        final lecturesSnap = await dbService.dbref
            .collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("departments").doc(department.id!)
            .collection("sessions").doc(c['session_id'])
            .collection("semesters").doc(c['semester_id'])
            .collection("courses").doc(c['course_id'])
            .collection("lectures")
            .where("dated", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where("dated", isLessThan: Timestamp.fromDate(endOfDay))
            .where("status", isEqualTo: "upcoming")
            .get();

        totalPending += lecturesSnap.docs.length;
      }

      return totalPending;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  Future<int> getPresentTodayCount(BuildContext context, String insAdminId, String instituteId, String lecId) async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final courseRefs = await _myCourseRefs(context, insAdminId, instituteId, lecId);
      if (courseRefs.isEmpty) return 0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      int totalPresent = 0;

      for (var c in courseRefs) {
        final lecturesSnap = await dbService.dbref
            .collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("departments").doc(department.id!)
            .collection("sessions").doc(c['session_id'])
            .collection("semesters").doc(c['semester_id'])
            .collection("courses").doc(c['course_id'])
            .collection("lectures")
            .where("dated", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where("dated", isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        for (var lectureDoc in lecturesSnap.docs) {
          final rawAttendance = lectureDoc.data()['attendance'];
          if (rawAttendance is List) {
            // Counts anyone currently marked present or late for today's
            // lectures, whether or not they've checked out yet — this is a
            // same-day "who showed up" tile, not a completed-attendance stat
            // (compare to the stricter weekly-stats card, which requires
            // checkout != null before counting someone as present).
            final attendanceList = rawAttendance
                .whereType<Map<String, dynamic>>()
                .map((m) => Attendance.fromMap(m));
            totalPresent += attendanceList
                .where((attendance) =>
            attendance.status == 'present' || attendance.status == 'late')
                .length;
          }
        }
      }

      return totalPresent;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  Future<int> getStudentCount(BuildContext context, String insAdminId, String instituteId, String lecId) async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);
      final courseRefs = await _myCourseRefs(context, insAdminId, instituteId, lecId);
      if (courseRefs.isEmpty) return 0;

      // Dedupe session/semester pairs — multiple courses can share the same semester,
      // and we don't want to count those students more than once.
      final Set<String> uniquePairs = {};
      final List<Map<String, String>> sessionSemesterPairs = [];

      for (var c in courseRefs) {
        final key = "${c['session_id']}/${c['semester_id']}";
        if (uniquePairs.add(key)) {
          sessionSemesterPairs.add({
            "session_id": c['session_id'] as String,
            "semester_id": c['semester_id'] as String,
          });
        }
      }

      int totalCount = 0;

      for (var pair in sessionSemesterPairs) {
        final counter = await dbService.indexDoc
            .where('role', isEqualTo: 'student')
            .where('ins_admin_id', isEqualTo: insAdminId)
            .where('institute_id', isEqualTo: instituteId)
            .where('department_id', isEqualTo: department.id!)
            .where('session_id', isEqualTo: pair['session_id'])
            .where('semester_id', isEqualTo: pair['semester_id'])
            .count()
            .get();

        totalCount += counter.count ?? 0;
      }

      return totalCount;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  Future<Object?>? getAvgAtt(BuildContext context, String insAdminId, String instituteId,String depId,String lecturerId) async {
    try {
      int totalPresentRecords = 0;
      int totalPossibleRecords = 0;

      // Get all departments
      // final departmentsSnapshot = await Provider.of<DbService>(context,listen: false). dbref
      //     .collection("ins_admins")
      //     .doc(insAdminId)
      //     .collection("institutes")
      //     .doc(instituteId)
      //     .collection("departments")
      //     .get();


        // Get all sessions for this department
        final sessionsSnapshot = await Provider.of<DbService>(context,listen: false).dbref
            .collection("ins_admins")
            .doc(insAdminId)
            .collection("institutes")
            .doc(instituteId)
            .collection("departments")
            .doc(depId)
            .collection("sessions")
            .get();

        for (var sessionDoc in sessionsSnapshot.docs) {
          // Get all semesters
          final semestersSnapshot = await Provider.of<DbService>(context,listen: false).dbref
              .collection("ins_admins")
              .doc(insAdminId)
              .collection("institutes")
              .doc(instituteId)
              .collection("departments")
              .doc(depId)
              .collection("sessions")
              .doc(sessionDoc.id)
              .collection("semesters")
              .get();

          for (var semesterDoc in semestersSnapshot.docs) {
            // Get students in this semester
            final studentsSnapshot = await Provider.of<DbService>(context,listen: false).dbref
                .collection("ins_admins")
                .doc(insAdminId)
                .collection("institutes")
                .doc(instituteId)
                .collection("departments")
                .doc(depId)
                .collection("sessions")
                .doc(sessionDoc.id)
                .collection("semesters")
                .doc(semesterDoc.id)
                .collection("students")
                .get();

            // Get courses in this semester
            final coursesSnapshot = await Provider.of<DbService>(context,listen: false).dbref
                .collection("ins_admins")
                .doc(insAdminId)
                .collection("institutes")
                .doc(instituteId)
                .collection("departments")
                .doc(depId)
                .collection("sessions")
                .doc(sessionDoc.id)
                .collection("semesters")
                .doc(semesterDoc.id)
                .collection("courses")

                .get();

            // Process each course's lectures
            for (var courseDoc in coursesSnapshot.docs) {
              final lecturesSnapshot = await Provider.of<DbService>(context,listen: false).dbref
                  .collection("ins_admins")
                  .doc(insAdminId)
                  .collection("institutes")
                  .doc(instituteId)
                  .collection("departments")
                  .doc(depId)
                  .collection("sessions")
                  .doc(sessionDoc.id)
                  .collection("semesters")
                  .doc(semesterDoc.id)
                  .collection("courses")
                  .doc(courseDoc.id)
                  .collection("lectures")
                  .where("lecturer_id", isEqualTo: lecturerId)
                  .get();

              // Process each lecture's attendance
              for (var lectureDoc in lecturesSnapshot.docs) {
                final lectureData = lectureDoc.data() as Map;
                final attendanceList = lectureData['attendance'] as List? ?? [];

                // Add to total possible records
                totalPossibleRecords += studentsSnapshot.docs.length;

                // Count present students
                for (var record in attendanceList) {
                  if (record is Map) {
                    final status = record['status']?.toString() ?? '';
                    final midPoint = record['mid_point'] ?? false;

                    // Consider student present if status is present/late or mid_point is true
                    if (status == 'present' ||
                        status == 'late' ||
                        midPoint == true) {
                      totalPresentRecords++;
                    }
                  }
                }
              }
            }
          }
        }


      // Calculate average
      if (totalPossibleRecords == 0) {
        return 0.0;
      }

      double avgAttendance = (totalPresentRecords / totalPossibleRecords) * 100;
      return double.parse(avgAttendance.toStringAsFixed(2));

    } catch(e) {
      print(e.toString());
      return 0;
    }
  }
}