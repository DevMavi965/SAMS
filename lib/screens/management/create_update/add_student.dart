import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/services/db_service.dart';

class AddStudent extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;

  const AddStudent({super.key, required this.insAdmin, required this.institute, required this.department, required this.session, required this.semester});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  // Student(
  // id: std.id,
  // role: std['role'],
  // name: std['name'],
  // insAdminId: std['ins_admin_id'],
  // instituteId: std['institute_id'],
  // departId: std['department_id'],
  // sessionId: std['session_id'],
  // semesterId: std['semester_id'],
  // email: std['email'],
  // created_at: std['created_at'].toDate(),
  // )
  TextEditingController name=TextEditingController();
  TextEditingController email=TextEditingController();
  TextEditingController password=TextEditingController();

  final fkey=GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Student"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:Container(
        padding: EdgeInsets.symmetric(
            horizontal: 15
        ),
        child: Form(
          key:fkey,
          child: Column(
            children: [
              SizedBox(height: 20,),
              //name
              TextFormField(
                controller: name,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter name";
                  }else if(v.length<4){
                    return "name must be at least 4 characters";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "name",
                  prefixIcon: Icon(Icons.person),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1
                      )
                  ),
                  border: OutlineInputBorder(),
                ),

              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: email,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter email";
                  }else if(v.length<4){
                    return "email cannot be short";
                  }else if(!v.contains("@")){
                    return "Please enter valid email";
                  }else if(!v.contains(".")){
                    return "Please enter valid email";
                  }else if(!v.contains("com")){
                    return "Please enter valid email";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "email",
                  prefixIcon: Icon(Icons.email),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1
                      )
                  ),
                  border: OutlineInputBorder(),
                ),

              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: password,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter password";
                  }else if(v.length<8){
                    return "name must be at least 8 characters";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "password",
                  prefixIcon: Icon(Icons.lock),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1
                      )
                  ),
                  border: OutlineInputBorder(),
                ),

              ),
              SizedBox(height: 20,),
              ElevatedButton.icon(onPressed: (){
                if(fkey.currentState!.validate()){
                  showDialog(context: context, builder: (_)=>AlertDialog(
                    title: Text("Add student"),
                    content: Text("Are you sure you want to add this student?"),
                    actions: [
                      TextButton(onPressed: (){

                        Navigator.pop(context);
                      }, child: Text("No")),
                      TextButton(onPressed: (){
                       Provider.of<DbService>(context,listen: false).registerStudent(
                           widget.insAdmin.id!,
                           widget.institute.id!,
                           Student(
                               role: "student",
                               name: name.text.trim(),
                               insAdminId: widget.insAdmin.id!,
                               instituteId: widget.institute.id!,
                               departId: widget.department.id!,
                               sessionId: widget.session.id!,
                               semesterId: widget.semester.id!,
                               email: email.text.trim(),
                              created_at: DateTime.now()
                           ),
                           password.text.trim(), context);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }, child: Text("Yes")),
                    ],
                  ));
                }
              },
                label: Text("Add student",style: TextStyle(color: Theme.of(context).primaryColor),),
                icon: FaIcon(FontAwesomeIcons.userPlus,color: Theme.of(context).primaryColor,),
              )

            ],
          ),
        ),
      )
    );
  }
}
