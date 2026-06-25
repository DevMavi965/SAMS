import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';
class InsAdminGrid1 extends StatelessWidget {
  // final int students,noOfFaculty,noOfDeparts,noOfAdmins,announcements;
  // final double avg_attendance;
  final InsAdmin insAdmin;
  final Institute institute;
  const InsAdminGrid1({super.key, required this.insAdmin, required this.institute, });

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        //admins
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
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_rounded,color: Theme.of(context).primaryColorDark,),
              FutureBuilder(future: getAdminCount(context, insAdmin.id!, institute.id!), builder: (context,snap){
                if(snap.connectionState==ConnectionState.waiting){
                  return Text("Loading...");
                }else if(snap.hasError){
                  return Text("Error: ${snap.error}");
                }else if(!snap.hasData || snap.data==null){
                  return Text("0");
                }else if(snap.hasData){
                  return Text("${snap.data}",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),);
                }
                return Text("0");
              }),
              Text("Total Admins",style: TextStyle(color: Colors.grey,fontSize: 10),)
            ],
          ),
        ),
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
              Text("87%",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),),
              Text("Overall Attendance",style: TextStyle(color: Colors.grey,fontSize: 10),)
            ],
          ),
        ),//overall attendance
        //active announcements
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
              Icon(PhosphorIconsBold.speakerSimpleHigh,color:Theme.of(context).primaryColor,),
              FutureBuilder(future: getAnnCount(context, insAdmin.id!, institute.id!), builder: (context,snap){
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
              Flexible(child: Text("Active Announcements",style: TextStyle(color: Colors.grey,fontSize: 10),))
            ],
          ),
        ),



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
  Future<int> getAnnCount(BuildContext context,String insAdminId,String instituteId) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .dbref.collection("ins_admins").doc(insAdminId).
      collection("institutes").doc(instituteId).collection("announcements").count().get();


      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }
}
