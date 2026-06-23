import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../../services/db_service.dart';

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
                controller: email,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          width: 0.5,
                          color: Colors.grey
                      )
                  ),
                ),
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter email";
                  }else if(v.length<3){
                    return "Please enter valid email";
                  }else if(!v.contains("@")){
                    return "Please enter valid email";
                  }else if(!v.contains(".")){
                    return "Please enter valid email";
                  }else if(!v.contains("com")){
                    return "Please enter valid email";
                  }else
                    // method II
                    // final emailRegex =
                    // RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                    // if (!emailRegex.hasMatch(v.trim())) {
                    //   return "Please enter valid email";
                    // }
                    return null;
                },
              ),//email
              SizedBox(height: 15,),
              TextFormField(
                controller: password,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter password";
                  }else if(v.length<4){
                    return "password must be at least 8 characters";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "password",
                  suffixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1
                      )
                  ),
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
              ElevatedButton.icon(onPressed: (){
                if(fkey.currentState!.validate()){
                    Provider.of<DbService>(context,listen: false).registerFac(
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
