import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/student_model.dart';

import '../../../models/department.dart';
import '../../../models/ins_admin.dart';
import '../../../models/institute.dart';
import '../../../models/semester.dart';
import '../../../models/session.dart';
import '../../../services/db_service.dart';

class StdView extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;
  const StdView({super.key, required this.insAdmin, required this.institute, required this.department, required this.session, required this.semester});

  @override
  State<StdView> createState() => _StdViewState();
}

class _StdViewState extends State<StdView> {
  List<Student> students=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Students of ${widget.department.name} ${widget.session.name} Semester ${widget.semester.semester_no}"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
          .collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").doc(widget.department.id)
          .collection("sessions").doc(widget.session.id)
          .collection("semesters").doc(widget.semester.id)
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
            ListView.builder(itemBuilder: (_,i){
              return Container(
                margin: EdgeInsets.symmetric(
                    horizontal: 5,vertical: 5
                ),
                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),


                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(70),
                      radius:28,
                      child: Text(RMFuncts.getFirstLetters(students[i].name),style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(students[i].name,style: TextStyle(fontWeight: FontWeight.w600),),
                        SizedBox(height: 3,),
                        Text(students[i].email,style: TextStyle(color: Colors.grey),),
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Badge(label: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text(students[i].departId,style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black
                              ),),
                            ),backgroundColor: Colors.grey.withAlpha(70),),
                            SizedBox(width: 10,),
                            Badge(label: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text("semester ${students[i].semesterId}",style: TextStyle(color: Colors.black),),
                            ),backgroundColor: Color(0xfff1f5f9),),

                          ],
                        )
                      ],),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Badge(label: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Text(students[i].id!,style: TextStyle(color: Colors.black),),
                        ),backgroundColor:Color(0xfff1f5f9),),
                        SizedBox(height: 10,),
                        Icon(Icons.more_vert,color: Colors.grey,),
                      ],
                    )
                  ],),
              );
            });
          }
          return SizedBox();
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(200)
        ),

        onPressed: (){

        },child: Icon(Icons.person_add_alt_1_rounded,color: Colors.white,),),
    );
  }
}
