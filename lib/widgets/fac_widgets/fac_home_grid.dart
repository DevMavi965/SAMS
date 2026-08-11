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
          // width: 200,
          // height: 120,
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
          // width: 200,
          // height: 120,
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
          // width: 200,
          // height: 120,
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
                future: getPercentageAttendanceToday(context, insAdmin.id!, institute.id!, lecturer.id!),
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
              Text("Avg Attendance",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //pending classes
        Container(
          // width: 200,
          // height: 120,
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
  Future<int> getPendingClassesTodayCount(BuildContext context, String insAdminId, String instituteId, String lecId) async {
    try {
      final dbService = Provider.of<DbService>(context, listen: false);

      final myCourses = await dbService.indexDoc
          .where("type", isEqualTo: "lecture")
          .where("ins_admin_id", isEqualTo: insAdminId)
          .where("institute_id", isEqualTo: instituteId)
          .where("lecturer_id", isEqualTo: lecId)
          .get();

      if (myCourses.docs.isEmpty) return 0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      int totalPending = 0;

      for (var courseDoc in myCourses.docs) {
        final data = courseDoc.data();
        final sessionId = data['session_id'];
        final semesterId = data['semester_id'];
        final courseId = courseDoc.id;

        if (sessionId == null || semesterId == null) continue;

        final lecturesSnap = await dbService.dbref
            .collection("ins_admins")
            .doc(insAdminId)
            .collection("institutes")
            .doc(instituteId)
            .collection("departments")
            .doc(department.id!)
            .collection("sessions")
            .doc(sessionId)
            .collection("semesters")
            .doc(semesterId)
            .collection("courses")
            .doc(courseId)
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

      final myCourses = await dbService.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdminId)
          .where("institute_id", isEqualTo: instituteId)
          .where("lecturer_id", isEqualTo: lecId)
          .get();

      if (myCourses.docs.isEmpty) return 0;

      // Build today's start/end boundaries for a date-range query on "dated".
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      int totalPresent = 0;

      for (var courseDoc in myCourses.docs) {
        final data = courseDoc.data();
        final sessionId = data['session_id'];
        final semesterId = data['semester_id'];
        final courseId = courseDoc.id;

        if (sessionId == null || semesterId == null) continue;

        final lecturesSnap = await dbService.dbref
            .collection("ins_admins")
            .doc(insAdminId)
            .collection("institutes")
            .doc(instituteId)
            .collection("departments")
            .doc(department.id!)
            .collection("sessions")
            .doc(sessionId)
            .collection("semesters")
            .doc(semesterId)
            .collection("courses")
            .doc(courseId)
            .collection("lectures")
            .where("dated", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where("dated", isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        for (var lectureDoc in lecturesSnap.docs) {
          final lectureData = lectureDoc.data();
          final presentList = lectureData['present'];
          if (presentList is List) {
            totalPresent += presentList.length;
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

      final myCourses = await dbService.indexDoc
          .where("type", isEqualTo: "course")
          .where("ins_admin_id", isEqualTo: insAdminId)
          .where("institute_id", isEqualTo: instituteId)
          .where("lecturer_id", isEqualTo: lecId)
          .get();

      if (myCourses.docs.isEmpty) return 0;

      // Dedupe session/semester pairs — multiple courses can share the same semester,
      // and we don't want to count those students more than once.
      final Set<String> uniquePairs = {};
      final List<Map<String, String>> sessionSemesterPairs = [];

      for (var courseDoc in myCourses.docs) {
        final data = courseDoc.data();
        final sessionId = data['session_id'];
        final semesterId = data['semester_id'];

        if (sessionId == null || semesterId == null) continue;

        final key = "$sessionId/$semesterId";
        if (uniquePairs.add(key)) {
          // add() returns true only if it wasn't already present
          sessionSemesterPairs.add({
            "session_id": sessionId,
            "semester_id": semesterId,
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
  Future<double> getPercentageAttendanceToday(BuildContext context, String insAdminId, String instituteId, String lecId) async {
    try {
      final studentCount = await getStudentCount(context, insAdminId, instituteId, lecId);
      final presentToday = await getPresentTodayCount(context, insAdminId, instituteId, lecId);

      if (studentCount == 0) return 0.0;

      return (presentToday / studentCount) * 100;
    } catch (e) {
      print(e.toString());
      return 0.0;
    }
  }
}
