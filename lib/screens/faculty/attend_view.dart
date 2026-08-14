import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/lecture.dart';

import '../../models/student_model.dart';
import '../../services/db_service.dart';

class AttendView extends StatefulWidget {
  final LectureModel lecture;
  final String insAdminId, instituteId, departmentId, sessionId, semesterId, courseId;
  const AttendView({
    super.key,
    required this.lecture,
    required this.insAdminId,
    required this.instituteId,
    required this.departmentId,
    required this.sessionId,
    required this.semesterId,
    required this.courseId});

  @override
  State<AttendView> createState() => _AttendViewState();
}

class _AttendViewState extends State<AttendView> {
  // lecture: lecture,
  // insAdminId: widget.insAdmin.id!,
  // instituteId: widget.institute.id!,
  // departmentId: entry.departmentId,
  // sessionId: entry.sessionId,
  // semesterId: entry.semesterId,
  // courseId: entry.courseId,
  List<Student> students=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title: Text("${widget.lecture.course}  ${DateFormat("dd MMM yyyy").format(widget.lecture.dated)} attendance",style: TextStyle(
        fontSize: 15,
      ),),
    ),
      body: StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
          .collection("ins_admins").doc(widget.insAdminId)
          .collection("institutes").doc(widget.instituteId)
          .collection("departments").doc(widget.departmentId)
          .collection("sessions").doc(widget.sessionId)
          .collection("semesters").doc(widget.semesterId)
          .collection("students")
          .snapshots(),
          builder: (context,snapshot){
            if(snapshot.connectionState==ConnectionState.waiting){
              return Center(child: CircularProgressIndicator(),);
            }else if(snapshot.hasError){
              return Center(child: Text(snapshot.error.toString()),);
            }else if(!snapshot.hasData){
              return Center(child: Text("No data found"),);
            }else if(snapshot.hasData){
              students.clear();
              for(var std in snapshot.data!.docs){
                students.add(
                    Student(
                      id: std.id,
                      role: std['role'],
                      name: std['name'],
                      insAdminId: std['ins_admin_id'],
                      instituteId: std['institute_id'],
                      departId: std['department_id'],
                      sessionId: std['session_id'],
                      semesterId: std['semester_id'],
                      email: std['email'],
                      created_at: std['created_at'].toDate(),
                    )
                );
              }
              return students.isEmpty?Center(child: Text("no students found,Add first"),):
              ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_,i){
                    return Card(
                      color: Colors.white,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(
                            horizontal: 5,vertical: 10
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 2,vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(7),


                        ),
                        child:
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    radius:21,
                                    child: Icon(PhosphorIconsDuotone.student,color: Colors.white,size: 32,),
                                  ),
                                ),
                                SizedBox(width:5,),
                                Expanded(
                                  flex:4,
                                  child: Column(
                                    // mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(RMFuncts.getSentenceCase(students[i].name),style: TextStyle(fontWeight: FontWeight.w600),),
                                      SizedBox(height: 3,),
                                      Text(students[i].email,style: TextStyle(color: Colors.grey),),
                                      SizedBox(height: 10,),
                                    ],),
                                ),
                                Expanded(child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.grey,
                                      child: Text("A",style: TextStyle(
                                        color: Colors.white
                                      ),),
                                    )
                                  ],
                                ))
                              ],),
                            SizedBox(height: 15,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(width: 10,),
                                Expanded(child: Row(
                                  children: [
                                    Icon(CupertinoIcons.time,size: 15,),
                                    SizedBox(width: 2,),
                                    Flexible(child: Text("in:   06:10",style: TextStyle(fontSize: 13),)),
                                  ],
                                )),
                                SizedBox(width: 10,),
                                Expanded(child: Row(
                                  children: [
                                    Icon(Icons.verified,size: 14,),
                                    SizedBox(width: 2,),
                                    Flexible(child: Text("mid-point:   06:10",style: TextStyle(fontSize: 12),)),
                                  ],
                                )),
                                SizedBox(width: 10,),
                                Expanded(child: Row(
                                  children: [
                                    Icon(CupertinoIcons.time,size: 15,),
                                    SizedBox(width: 2,),
                                    Flexible(child: Text("out:   08:15",style: TextStyle(fontSize: 13),)),
                                  ],
                                )),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  });
            }
            return SizedBox();
          })
    );
  }
}
