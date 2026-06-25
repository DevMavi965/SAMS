import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class DepartManage extends StatefulWidget with RMFuncts{
  final InsAdmin insAdmin;
  final Institute institute;
  const DepartManage({super.key, required this.insAdmin, required this.institute});

  @override
  State<DepartManage> createState() => _DepartManageState();
}

class _DepartManageState extends State<DepartManage> {
  List<Department> departments=[];
  TextEditingController _name=TextEditingController();
  TextEditingController _hod=TextEditingController();
  final _formKey=GlobalKey<FormState>();
  TextEditingController name=TextEditingController();
   TextEditingController hod=TextEditingController();
  final fkey=GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    hod.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Departments"),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
          .collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").snapshots(),
          builder: (context,snapshot){
            if(snapshot.connectionState==ConnectionState.waiting){
              return Center(child: CircularProgressIndicator(),);
            }else if(snapshot.hasError){
              return Center(child: Text(snapshot.error.toString()),);
            }else if(!snapshot.hasData){
              return Center(child: Text("No data found"),);
            }else if(snapshot.data!.docs.isEmpty){
              return Center(child: Text("No departments found"),);
            }
            departments.clear();
            for(var dep in snapshot.data!.docs){
              departments.add(
                Department(
                  id: dep.id,
                    name: dep['name'],
                    hod_name: dep['hod_name'],
                    created_at: dep['created_at'].toDate()
                )
              );
            }
            return ListView.builder(
                itemCount: departments.length,
                itemBuilder: (context,count){
              return DepartmentCard(department: departments[count],);
            });
          }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        shape:RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100)
        ),
        onPressed: (){
          showDialog(context: context, builder: (_)=>AlertDialog(
            backgroundColor: Colors.white,
            icon: Icon(Icons.add_business_outlined,color: Theme.of(context).primaryColor,size: 33,),
            title: Text("Add Department"),
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10,),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Department Name",
                    ),
                    validator: (v){
                      if(v!.isEmpty){
                        return "Department name is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10,),
                  TextFormField(
                    controller: _hod,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "HOD Name",
                    ),
                    validator: (v){
                      if(v!.isEmpty){
                        return "HOD name is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10,),
                ],
              )),
            ),
            actions: [
              FilledButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red)
                ),
                onPressed: (){
                  Navigator.pop(context);
                }, child: Text("Cancel",style: TextStyle(color: Colors.white),),),
              FilledButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor)
                  ),
                  onPressed: (){
                if(_formKey.currentState!.validate()){
                  Provider.of<DbService>(context,listen: false).addDepartment(context, widget.insAdmin.id!, widget.institute.id!,
                      Department(
                          name: _name.text.trim(),
                          hod_name: _hod.text.trim(),
                          created_at: DateTime.now()

                      )
                  );
                  Navigator.pop(context);
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields"),));
                }
              }, child: Text("Add Department"))
            ],
          ));
        },child: Icon(Icons.add,color: Colors.white,),),
    );
  }
  Widget DepartmentCard({required Department department}){
    return Card(
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.only(
          top: 10,
          bottom: 15
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 15,left: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 4
                  )
                ),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  radius: 30,
                  child:Text(RMFuncts.getFirstLetters(department.name),style: TextStyle(color: Theme.of(context).primaryColor,fontWeight: FontWeight.w500),)
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(department.name,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                  SizedBox(height: 9,),
                  Row(
                    children: [
                      Text("HOD: ",style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w600),),
                      SizedBox(width: 5,),
                      Icon(CupertinoIcons.profile_circled,color: Colors.grey,size: 18,),
                      SizedBox(width: 2,),
                      Text(department.hod_name,style: TextStyle(color: Colors.grey),),
                    ],
                  ),
                  SizedBox(height: 9,),
                  Text("Created on: ${DateFormat("dd-MM-yyyy").format(department.created_at!)}",style: TextStyle(color: Colors.black54),)
                ],
              ),
            ),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // delete department
                IconButton(
                  // if(sessionCount(context, department.id!)>0)
                  onPressed: () async {
                    int sessionCount=await getSessionCount(context, department.id!);
                  if(sessionCount>0){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot delete department with sessions"),backgroundColor: Colors.red,));
                  }else{
                    showDialog(context: context, builder: (_)=>AlertDialog(
                      backgroundColor: Colors.white,
                      icon: Icon(Icons.delete,color: Colors.red,size: 33,),
                      title: Text("Delete Department"),
                      content: Text("Are you sure you want to delete this department?"),
                      actions: [
                        FilledButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.red)
                          ),
                          onPressed: (){
                            Provider.of<DbService>(context,listen: false).removeDepartment(context, department.id!);
                            Navigator.pop(context);
                          }, child: Text("Yes",style: TextStyle(color: Colors.white),),),
                        FilledButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.green)
                          ),
                          onPressed: (){
                            Navigator.pop(context);
                          }, child: Text("No",style: TextStyle(color: Colors.white),),)
                      ],
                    ));
                  }
                },
                  icon: Icon(Icons.delete,color:Colors.red,),),
                SizedBox(height: 5,),
                // update department
                IconButton(onPressed: (){
                  name.text=department.name;
                  hod.text=department.hod_name;
                  showDialog(context: context, builder: (_)=>AlertDialog(
                    backgroundColor: Colors.white,
                    icon: Icon(Icons.delete,color: Colors.red,size: 33,),
                    title: Text("Edit Department"),
                    content: Form(
                      key: fkey,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 10,),
                            TextFormField(
                              controller: name,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Department Name",
                              ),
                              validator: (v){
                                if(v!.isEmpty){
                                  return "Department name is required";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10,),
                            TextFormField(
                              controller: hod,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "HOD Name",
                              ),
                              validator: (v){
                                if(v!.isEmpty){
                                  return "HOD name is required";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10,),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      FilledButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.red)
                        ),
                        onPressed: (){
                          if(fkey.currentState!.validate()){
                            department.name=name.text.trim();
                            department.hod_name=hod.text.trim();
                            Provider.of<DbService>(context,listen: false).updateDepartment(context, department);
                          }else{
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields"),));
                          }
                          Navigator.pop(context);
                        }, child: Text("Yes",style: TextStyle(color: Colors.white),),),
                      FilledButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.green)
                        ),
                        onPressed: (){
                          Navigator.pop(context);
                        }, child: Text("No",style: TextStyle(color: Colors.white),),)
                    ],
                  ));
                }, icon: Icon(Icons.edit_calendar_sharp,color: Theme.of(context).primaryColor,),),

              ],
            ))
          ],
        ),
      ),
    );
  }

  Future<int> getSessionCount(BuildContext context,String departmentId) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .dbref.collection("ins_admins").doc(widget.insAdmin.id).
      collection("institutes").doc(widget.institute.id).collection("departments").doc(departmentId)
          .collection("sessions")
          .count().get();


      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }
}
