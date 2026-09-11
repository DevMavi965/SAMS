import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../../maxins/rm_functions.dart';
import '../../../services/db_service.dart';


class _Palette {
  static const ink = Color(0xFF0E231F);
  static const inkSoft = Color(0xFF16342E);
  static const paper = Color(0xFFF7FAF9);
  static const slate = Color(0xFF55645F);
  static const hairline = Color(0xFFDEE6E3);
  static const teal = Color(0xFF009878);
}


class AddFacultyScreen extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  const AddFacultyScreen({super.key, required this.insAdmin, required this.institute, required this.department});

  @override
  State<AddFacultyScreen> createState() => _AddFacultyScreenState();
}

class _AddFacultyScreenState extends State<AddFacultyScreen> {
  // Lecturer(
  // name: "Ayesha Zainab",
  // deprt: "Physics",
  // role: "faculty",
  // instituteId: widget.institute.id!,
  // insAdminId: widget.insAdmin.id!,
  // designation: "Assistant Professor",
  // status: "active",
  // email: "az12@gmail.com",
  // semesters: [4,6,8],
  // courses: ["CS101","CS102","CS103","CS104"],
  // created_at: DateTime.now(),
  // phone: "32466676544")
  // , "12341234", context);

  TextEditingController name=TextEditingController();
  TextEditingController email=TextEditingController();
  TextEditingController password=TextEditingController();
  TextEditingController phone=TextEditingController();
  TextEditingController designation=TextEditingController();
  String? selectedDepartment;
  final fkey=GlobalKey<FormState>();
  bool obscure=true;

  @override
  void dispose() {
    // TODO: implement dispose
    name.dispose();
    email.dispose();
    password.dispose();
    phone.dispose();
    designation.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Faculty"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        margin: EdgeInsetsGeometry.symmetric(
          horizontal: 15
        ),
        child: Form(
          key:fkey,
          child: Column(
            children: [
              SizedBox(height: 20,),
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
                  labelText: "faculty name",
                  suffixIcon: Icon(Icons.school),
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
                controller: phone,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter contact";
                  }else if(v.length<10){
                    return "contact must be at least 10 characters";
                  }else if(v.contains(" ")){
                    return "contact must not contain spaces";
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "phone",
                  suffixIcon: Icon(Icons.phone),
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
                controller: designation,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter designation";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "designation",
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1
                      )
                  ),
                  suffixIcon: Icon(Icons.edit_location_alt),
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
              ElevatedButton.icon(onPressed: ()async{
                if(fkey.currentState!.validate()){
                    try{
                     await Provider.of<DbService>(context,listen: false).registerFac(
                          widget.insAdmin.id!, widget.institute.id!,widget.department.id!,
                          Lecturer(
                              name: name.text.trim(),
                              deprt: widget.department.name,
                              role: "faculty",
                              insAdminId: widget.insAdmin.id!,
                              instituteId: widget.institute.id!,
                              departmentId: widget.department.id!,
                              designation: designation.text.trim(),
                              status: "active",
                              email: email.text.trim(),
                              phone: phone.text.trim(),
                              semesters: [],
                              courses: [],
                              created_at: DateTime.now()
                          ),
                          password.text.trim(), context);
                      Fluttertoast.showToast(msg: "Faculty added successfully ");
                      await RMFuncts.sendSamsCredentialsEmail(
                        email.text.trim(),
                        name.text.trim(),
                        password.text.trim(),
                      );
                      Fluttertoast.showToast(msg: "credential-Email sent successfully");
                      if(mounted){
                        Navigator.pop(context);
                      }


                      Navigator.pop(context);
                    }catch(e){
                      print(e.toString());
                    }
                    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Faculty added successfully"),));
                   Navigator.pop(context);
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields"),));
                }
              },
                label: Text("Add faculty",style: TextStyle(color: Theme.of(context).primaryColor),),
                icon: Icon(Icons.person_add,color: Theme.of(context).primaryColor,),
              )

            ],
          ),
        ),
      ),
    );
  }
}
