import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/student_model.dart';

import '../../../models/department.dart';
import '../../../models/ins_admin.dart';
import '../../../models/institute.dart';
import '../../../models/semester.dart';
import '../../../models/session.dart';
import '../../../services/db_service.dart';
import 'add_student.dart';

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
  TextEditingController name=TextEditingController();
  final fkey=GlobalKey<FormState>();
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
            ListView.builder(
                itemCount: students.length,
                itemBuilder: (_,i){
              return Card(
                color: Colors.white,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(
                      horizontal: 5,vertical: 5
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),


                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius:28,
                          child: Text(RMFuncts.getFirstLetters(students[i].name),style: TextStyle(
                            color: Colors.white,
                          ),),
                        ),
                      ),
                      SizedBox(width: 10,),
                      Flexible(
                        flex: 7,
                        child: Column(
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
                                Expanded(
                                  child: Badge(label: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(widget.department.name,style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      fontSize: 10
                                    ),),
                                  ),backgroundColor: Color(0xfff1f5f9),),
                                ),
                                SizedBox(width: 10,),
                                Expanded(
                                  child: Badge(label: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(widget.session.name,style: TextStyle(color: Colors.black),),
                                  ),backgroundColor:Color(0xfff1f5f9),),
                                ),
                                SizedBox(width: 10,),
                                Expanded(
                                  child: Badge(label: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text("semester ${widget.semester.semester_no}",style: TextStyle(color: Colors.black),),
                                  ),backgroundColor: Color(0xfff1f5f9),),
                                ),

                              ],
                            )
                          ],),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(onPressed: (){//delete button

                              showDialog(context: context, builder: (_)=>AlertDialog(
                                backgroundColor: Colors.white,
                                icon: Icon(Icons.delete,color: Theme.of(context).primaryColor,size: 33,),
                                title: Text("Delete Student"),
                                content: Text("Are you sure you want to delete this student?"),
                                actions: [
                                  FilledButton(onPressed: (){
                                    Navigator.pop(context);
                                  },style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                                  ),child: Text("Cancel",style: TextStyle(color: Colors.white),),),
                                  FilledButton(onPressed: () async {

                                    await Provider.of<DbService>(context,listen: false).removeStudent(context, students[i].id!);
                                   Navigator.pop(context);
                                  },style: ButtonStyle(backgroundColor:MaterialStateProperty.all(Colors.red), ),
                                    child: Text("Yes",style: TextStyle(color: Colors.white),),)
                                ],
                              ));
                            },icon: Icon(Icons.delete,color: Colors.red,),),
                            SizedBox(height: 10,),
                            IconButton(onPressed: (){
                              name.text=students[i].name;
                              showModalBottomSheet(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                  showDragHandle: true,
                                  context: context, builder: (context)=>StatefulBuilder(builder: (context,set)=>Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,vertical: 10,
                              ),child: Form(
                                  key: fkey,
                                  child: Column(children: [
                                    Text("Update Student",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                                    SizedBox(height: 15,),
                                    TextFormField(
                                  controller: name,
                                  decoration: InputDecoration(
                                    labelText: "name",
                                    prefixIcon: Icon(Icons.person),

                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Theme.of(context).primaryColor,
                                            width: 1
                                        )
                                    ),
                                  ),
                                  validator: (v){
                                    if(v!.isEmpty){
                                      return "Please enter name";
                                    }else if(v.length<4){
                                      return "name must be at least 4 characters";
                                    }
                                    return null;
                                  },
                                ),
                                    SizedBox(height: 20,),
                                    ElevatedButton.icon(onPressed: (){
                                      if(fkey.currentState!.validate()){
                                        Student std=Student(
                                          id: students[i].id,
                                          role: students[i].role,
                                          name: name.text.trim(),
                                          insAdminId: students[i].insAdminId,
                                          instituteId: students[i].instituteId,
                                          departId: students[i].departId,
                                          sessionId: students[i].sessionId,
                                          semesterId: students[i].semesterId,
                                          email: students[i].email,
                                          created_at: students[i].created_at,);
                                        Provider.of<DbService>(context,listen: false).updateStudent(context, std);
                                        Navigator.pop(context);

                                      }else{
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("enter valid values")));
                                      }




                                    }, label: Text("Update",style: TextStyle(color: Theme.of(context).primaryColor),),),
                              ],)),
                              )
                              ));
                            }, icon: FaIcon(FontAwesomeIcons.userPen,color: Theme.of(context).primaryColor,size: 20,)),
                          ],
                        ),
                      )
                    ],),
                ),
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
          Navigator.push(context, MaterialPageRoute(builder: (_)=>AddStudent(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, session: widget.session, semester: widget.semester,)));
        },child: Icon(Icons.person_add_alt_1_rounded,color: Colors.white,),),
    );
  }
}
