import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/services/db_service.dart';

import '../../../maxins/rm_functions.dart';


class _Palette {
  static const ink = Color(0xFF0E231F);
  static const inkSoft = Color(0xFF16342E);
  static const paper = Color(0xFFF7FAF9);
  static const slate = Color(0xFF55645F);
  static const hairline = Color(0xFFDEE6E3);
  static const teal = Color(0xFF009878);
}

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

  bool  obscure =true;
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
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "you@example.com",
                  prefixIcon: const Icon(Icons.mail_outline, color: _Palette.slate),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Enter your email";
                  if (!v.contains("@") || !v.contains(".")) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Password
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: password,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline, color: _Palette.slate),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: obscure ? _Palette.slate : _Palette.teal,
                          ),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Enter your password";
                        if (v.length < 8) return "Password must be at least 8 characters";
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 2,),
                  Flexible(
                    child:
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          //border
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12))
                          ),
                          backgroundColor:  Theme.of(context).primaryColor,
                        ),
                        onPressed: (){
                          Fluttertoast.showToast(msg: "generating password");
                          setState(() {
                            password.text = RMFuncts.generatePassword();
                          });
                        }, child: Text("generate",maxLines: 1,style: TextStyle(
                        color:Colors.white,
                        fontSize: 12
                    ),)),
                  )
                ],
              ),
              SizedBox(height: 20,),
              ElevatedButton.icon(onPressed: (){
                if(fkey.currentState!.validate()){
                  showDialog(context: context, builder: (_)=>AlertDialog(
                    title: Text("Add student"),
                    // icon: Icon(Icons.person_add,color: Theme.of(context).primaryColor,size: 24,),
                    content: Text("Are you sure you want to add this student?",style: TextStyle(
                      fontWeight: FontWeight.bold
                    ),),
                    actions: [
                      FilledButton(
                          style:FilledButton.styleFrom(
                            backgroundColor: Colors.red
                          ) ,
                          onPressed: (){

                        Navigator.pop(context);
                      }, child: Text("No",style: TextStyle(
                        color: Colors.white
                      ),)),
                      FilledButton(
                          style:FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor
                          ) ,
                          onPressed: ()async{
                      try{
                       await Provider.of<DbService>(context,listen: false).registerStudent(
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
                        Fluttertoast.showToast(msg: "Student added successfully ");
                        await RMFuncts.sendSamsCredentialsEmail(
                          email.text.trim(),
                          name.text.trim(),
                          password.text.trim(),
                        );
                        Fluttertoast.showToast(msg: "credential-Email sent successfully");
                        if(mounted){
                          Navigator.pop(context);
                        }
                      }catch(e){
                        print(e.toString());
                      }
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }, child: Text("Yes",style: TextStyle(
                        color: Colors.white
                      ),)),
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
