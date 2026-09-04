import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';
class AdminHomeGrid extends StatelessWidget {
  // final int students,noOfFaculty,noOfDeparts,noOfAdmins,announcements;
  // final double avg_attendance;
  final InsAdmin insAdmin;
  final Institute institute;
  const AdminHomeGrid({super.key, required this.insAdmin, required this.institute, });

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount:MediaQuery.of(context).size.width > 700 ? 4 : 2,
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
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_outlined,color: Theme.of(context).primaryColor,),
              FutureBuilder(future: getStudentCount(context, insAdmin.id!, institute.id!), builder: (context,snap){
                if(snap.connectionState==ConnectionState.waiting){
                  return Text("Loading...");
                }else if(snap.hasError){
                  return Text("Error: ${snap.error}");
                }else if(!snap.hasData || snap.data==null){
                  return Text("0");
                }else if(snap.hasData){
                  return Text("${snap.data}",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),);
                }return Text("0");
              }),
              Text("Total Students",style: TextStyle(color: Colors.grey,fontSize: 10),)
            ],
          ),
        ),
        //faculty
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.school_outlined,color: Colors.lightBlue,),
              FutureBuilder(future: getFacCount(context, insAdmin.id!, institute.id!), builder: (context,snap){
                if(snap.connectionState==ConnectionState.waiting){
                  return Text("Loading...");
                }else if(snap.hasError){
                  return Text("Error: ${snap.error}");
                }else if(!snap.hasData || snap.data==null){
                  return Text("0");
                }else if(snap.hasData){
                  return Text("${snap.data}",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),);
                }return Text("0");
              }),
              Text("Total Faculty",style: TextStyle(color: Colors.grey,fontSize: 10),)
            ],
          ),
        ),
        //departments
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.buildingApartment,color: Colors.purple,),
              FutureBuilder(future: getDepCount(context, insAdmin.id!, institute.id!), builder: (context,snap){
                if(snap.connectionState==ConnectionState.waiting){
                  return Text("Loading...");
                }else if(snap.hasError){
                  return Text("Error: ${snap.error}");
                }else if(!snap.hasData || snap.data==null){
                  return Text("0");
                }else if(snap.hasData){
                  return Text("${snap.data}",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),);
                }return Text("0");
              }),
              Text("Total Departments",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //overall attendance
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.trendUp,color:Theme.of(context).primaryColor,),
              FutureBuilder(future: getAvgAtt(context, insAdmin.id!, institute.id!), builder: (context,snap){
                if(snap.connectionState==ConnectionState.waiting){
                  return Text("Loading...");
                }else if(snap.hasError){
                  return Text("Error: ${snap.error}");
                }else if(!snap.hasData || snap.data==null){
                  return Text("0");
                }else if(snap.hasData){
                  return Text("${snap.data} %",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),);
                }return Text("0");
              }),
              Text("Overall Attendance",style: TextStyle(color: Colors.grey,fontSize: 10),)
            ],
          ),
        ),//overall attendance
      ],
    );
  }
  Future<int> getStudentCount(BuildContext context,String insAdminId,String instituteId) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .indexDoc.where('role', isEqualTo: 'student')
          .where('ins_admin_id', isEqualTo: insAdminId)
          .where('institute_id', isEqualTo: instituteId)
          .count().get();

      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }
  Future<int> getAdminCount(BuildContext context,String insAdminId,String instituteId) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .indexDoc.where('role', isEqualTo: 'admin')
          .where('ins_admin_id', isEqualTo: insAdminId)
          .where('institute_id', isEqualTo: instituteId)
          .count().get();

      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }
  Future<int> getFacCount(BuildContext context,String insAdminId,String instituteId) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .indexDoc.where('role', isEqualTo: 'faculty')
          .where('ins_admin_id', isEqualTo: insAdminId)
          .where('institute_id', isEqualTo: instituteId)
          .count().get();

      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }
  Future<int> getDepCount(BuildContext context,String insAdminId,String instituteId) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .dbref.collection("ins_admins").doc(insAdminId).
      collection("institutes").doc(instituteId).collection("departments").count().get();


      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }

  Future<Object?>? getAvgAtt(BuildContext context, String insAdminId, String instituteId) async {
    try {
      int totalPresentRecords = 0;
      int totalPossibleRecords = 0;

      // Get all departments
      final departmentsSnapshot = await Provider.of<DbService>(context,listen: false). dbref
          .collection("ins_admins")
          .doc(insAdminId)
          .collection("institutes")
          .doc(instituteId)
          .collection("departments")
          .get();

      for (var deptDoc in departmentsSnapshot.docs) {
        // Get all sessions for this department
        final sessionsSnapshot = await Provider.of<DbService>(context,listen: false).dbref
            .collection("ins_admins")
            .doc(insAdminId)
            .collection("institutes")
            .doc(instituteId)
            .collection("departments")
            .doc(deptDoc.id)
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
              .doc(deptDoc.id)
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
                .doc(deptDoc.id)
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
                .doc(deptDoc.id)
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
                  .doc(deptDoc.id)
                  .collection("sessions")
                  .doc(sessionDoc.id)
                  .collection("semesters")
                  .doc(semesterDoc.id)
                  .collection("courses")
                  .doc(courseDoc.id)
                  .collection("lectures")
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
