import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/student_model.dart';
class PersonalInfo extends StatelessWidget {
  final Student student;
  const PersonalInfo({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return
      Container(
      clipBehavior: Clip.hardEdge,
      // height: 265,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey,
          width: 0.2,
        ),
      ),
      child:
      Table(
        border:
        TableBorder.all(
          color: Colors.grey,
          width: 0.2,
        ),
        children: [
          //email
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.email_outlined,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email",style: TextStyle(color: Colors.grey),),
                          Text(student.email),
                        ],
                      )
                    ],
                  ),
                )
              ]
          ),
          //phone
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone_outlined,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone",style: TextStyle(color: Colors.grey),),
                          Text("03351094534"),
                        ],
                      )
                    ],
                  ),
                )
              ]
          ),
          //course enrolled date
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(PhosphorIconsBold.calendarBlank,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Enrolled Since",style: TextStyle(color: Colors.grey),),
                          Text("${student.created_at!.day}/${student.created_at!.month}/${student.created_at!.year}"),
                        ],
                      )
                    ],
                  ),
                )
              ]
          ),
          //semester current
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.menu_book_sharp,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Current Semster",style: TextStyle(color: Colors.grey),),
                          FutureBuilder(future: getSemesterNo(student.id!), builder: (context,snapshot){
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
                              return Text("Semester  ${snapshot.data.toString()}",style: TextStyle(fontSize: 11,color: Colors.black),);
                            }
                            return SizedBox();
                          })
                          ,
                        ],
                      )
                    ],
                  ),
                )
              ]
          )
        ],
      ),
    );
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
