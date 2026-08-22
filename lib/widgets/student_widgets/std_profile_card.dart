import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smas3/models/student_model.dart';

import '../../maxins/rm_functions.dart';
class StdProfileCard extends StatefulWidget {
  final Student student;
  const StdProfileCard({super.key, required this.student});

  @override
  State<StdProfileCard> createState() => _StdProfileCardState();
}

class _StdProfileCardState extends State<StdProfileCard> {
  String getLogo(String name) {
    name = name.trim();
    List<String> parts = name.split(' ');
    return parts.first[0].toUpperCase() +
        (parts.length > 1 ? parts.last[0].toUpperCase() : '');
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,

      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        // color: Colors.green,
          gradient: LinearGradient(
              end: AlignmentGeometry.topLeft,
              begin: AlignmentGeometry.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey,
            width: 0.2,
          )

      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 4,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Theme.of(context).primaryColor,

                    // backgroundImage: AssetImage("assets/images/img.png"),
                    child: Text(getLogo(widget.student.name),style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
                  ),
                ),
                SizedBox(width: 15,),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(RMFuncts.getSentenceCase(widget.student.name),style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
                      Expanded(
                        child: FutureBuilder(future: getInstituteName(widget.student.id!), builder: (context,snapshot){
                          if(snapshot.connectionState==ConnectionState.waiting){
                            return  SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: Lottie.asset("assets/anims/an1.json"));
                          }else if(snapshot.hasError){
                            return Text(snapshot.error.toString());
                          }else if(!snapshot.hasData){
                            return Text("no data found");
                          }else if(snapshot.hasData){
                            return Text(snapshot.data.toString(),style: TextStyle(fontSize: 11,color: Colors.white),);
                          }
                          return SizedBox();
                        }),
                      )
                    ],

                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 20,),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      style: ButtonStyle(
                        fixedSize: MaterialStateProperty.all(Size(130, 35)),
                        minimumSize: MaterialStateProperty.all(Size(120, 35)),
                        maximumSize: MaterialStateProperty.all(Size(150, 35)),
                        padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),

                        )),
                        side: MaterialStateProperty.all(BorderSide(
                          color: Colors.white,
                          width:1,
                        )),
                      ),
                      onPressed: () {

                      }, child:
                  FutureBuilder(future: getDepartmentName(widget.student.id!), builder: (context,snapshot){
                        if(snapshot.connectionState==ConnectionState.waiting){
                        return  SizedBox(
                                    height: 60,
                                    width: 60,
                                    child: Lottie.asset("assets/anims/an1.json"));
                        }else if(snapshot.hasError){
                          return Text(snapshot.error.toString());
                        }else if(!snapshot.hasData){
                          return Text("no data found");
                        }else if(snapshot.hasData){
                          return Text(snapshot.data.toString(),style: TextStyle(fontSize: 11,color: Colors.white),);
                        }
                        return SizedBox();
                  })
                  ),
                ),
                SizedBox(width: 20,),
                OutlinedButton(
                    style: ButtonStyle(
                      fixedSize: MaterialStateProperty.all(Size(100, 35)),
                      minimumSize: MaterialStateProperty.all(Size(100, 35)),
                      padding: MaterialStateProperty.all(EdgeInsets.all(5)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),

                      )),
                      side: MaterialStateProperty.all(BorderSide(
                        color: Colors.white,
                        width: 1,
                      )),
                    ),//padding
                    onPressed: () {

                    }, child:
                FutureBuilder(future: getSessionName(widget.student.id!), builder: (context,snapshot){
                  if(snapshot.connectionState==ConnectionState.waiting){
                    return  SizedBox(
                        height: 60,
                        width: 60,
                        child: Lottie.asset("assets/anims/an1.json"));
                  }else if(snapshot.hasError){
                    return Text(snapshot.error.toString());
                  }else if(!snapshot.hasData){
                    return Text("no data found");
                  }else if(snapshot.hasData){
                    return Text(snapshot.data.toString(),style: TextStyle(fontSize: 11,color: Colors.white),);
                  }
                  return SizedBox();
                })
                )
              ],
            ),
          )
        ],
      ),

    );
  }
  getInstituteName(String id) async {
    final doX=await FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("index").doc(id).get();
    String insAdminId= doX['ins_admin_id'];
    String instituteId= doX['institute_id'];
    final instituteFuture = FirebaseFirestore.instance
        .collection("SAMS")
        .doc("SAMS_DB").collection("ins_admins").doc(insAdminId)
        .collection("institutes")
        .doc(instituteId)
        .get();
     String instituteName = (await instituteFuture).data()!['name'];
    return instituteName;
  }
  getDepartmentName(String id) async {
    final doX=await FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("index").doc(id).get();
    String insAdminId= doX['ins_admin_id'];
    String instituteId= doX['institute_id'];
    String departmentId= doX['department_id'];
    final departmentFuture = FirebaseFirestore.instance.collection("SAMS")
        .doc("SAMS_DB").collection("ins_admins").doc(insAdminId)
        .collection("institutes").doc(instituteId)
        .collection("departments").doc(departmentId)
        .get();
    String departmentName = (await departmentFuture).data()!['name'];
    return departmentName;
  }
  getSessionName(String id) async {
    final doX=await FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("index").doc(id).get();
    String insAdminId= doX['ins_admin_id'];
    String instituteId= doX['institute_id'];
    String departmentId= doX['department_id'];
    String sessionId= doX['session_id'];
    final sessionFuture = FirebaseFirestore.instance.collection("SAMS")
        .doc("SAMS_DB").collection("ins_admins").doc(insAdminId)
        .collection("institutes").doc(instituteId)
        .collection("departments").doc(departmentId)
        .collection("sessions").doc(sessionId)
        .get();
    String sessionName = (await sessionFuture).data()!['name'];
    return sessionName;
  }
  getSemesterNo(String id) async {
    final doX=await FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("index").doc(id).get();
    String insAdminId= doX['ins_admin_id'];
    String instituteId= doX['institute_id'];
    String departmentId= doX['department_id'];
    String sessionId= doX['session_id'];
    String semesterId= doX['semester_id'];
    final semesterFuture = FirebaseFirestore.instance.collection("SAMS")
        .doc("SAMS_DB").collection("ins_admins").doc(insAdminId)
        .collection("institutes").doc(instituteId)
        .collection("departments").doc(departmentId)
        .collection("sessions").doc(sessionId)
        .collection("semesters").doc(semesterId)
        .get();
    String semesterName = (await semesterFuture).data()!['semester_no'].toString();
    return semesterName;
  }
  }

