import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../../services/db_service.dart';

class AddFacultyScreen extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const AddFacultyScreen({super.key, required this.insAdmin, required this.institute});

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
  TextEditingController department=TextEditingController();
  String? selectedDepartment;
  final fkey=GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Faculty"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          ElevatedButton.icon(onPressed: (){
            Provider.of<DbService>(context,listen: false).addDepartment(context, widget.insAdmin.id!, widget.institute.id!,
                Department(name: "Computer Science", hod_name: "Madiha Saoud",created_at: DateTime.now()));
          },
            label: Text("Add institute",style: TextStyle(color: Theme.of(context).primaryColor),),
            icon: Icon(Icons.add_business_rounded,color: Theme.of(context).primaryColor,),
          )
        ],
      ),
      body: StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref.collection("ins_admins").doc(widget.insAdmin.id).collection("institutes")
          .doc(widget.institute.id).collection("departments").snapshots(), builder: (context,snapshot){
        if(snapshot.connectionState==ConnectionState.waiting){
          return Center(child: CircularProgressIndicator(),);
        }else if(snapshot.hasError){
          return Center(child: Text(snapshot.error.toString()),);
        }else if(!snapshot.hasData){
          return Center(child: Text("No data found"),);
        }else if(snapshot.data!.docs.isEmpty){
          return Center(child: Text("no departments,add a department first"),);
        }
        List<String> departments=[];
        for(var doc in snapshot.data!.docs){
          departments.add(doc['name']);
        }
        return Container(
          padding: EdgeInsets.symmetric(
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
                departments.isEmpty?SizedBox():Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        width: 1,
                        color: Colors.grey
                      )
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 5
                    ),
                    child: DropdownButton(
                      itemHeight: 55,
                      icon: Icon(CupertinoIcons.building_2_fill),
                      isExpanded: true,
                        value: selectedDepartment,
                        hint: Text("select department"),
                        items: [
                      for(var depart in departments.toSet().toList())
                        DropdownMenuItem(
                          value: depart,
                          child: Text(depart,style: TextStyle(fontSize: 14,color: Colors.black87),),
                        )

                    ], onChanged: (v){
                      setState(() {
                        selectedDepartment=v;
                      });
                    }),
                  ),
                ),
                SizedBox(height: 20,),
                ElevatedButton.icon(onPressed: (){
                 Provider.of<DbService>(context,listen: false).addDepartment(context, widget.insAdmin.id!, widget.institute.id!,
                     Department(name: "Computer Science", hod_name: "Madiha Saoud"));
                },
                  label: Text("Add institute",style: TextStyle(color: Theme.of(context).primaryColor),),
                  icon: Icon(Icons.add_business_rounded,color: Theme.of(context).primaryColor,),
                )

              ],
            ),
          ),
        );
      })
    );
  }
}
