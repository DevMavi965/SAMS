import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/screens/management/create_update/add_faculty.dart';
import 'package:smas3/services/db_service.dart';

class FacManage extends StatefulWidget with RMFuncts{
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  const FacManage({super.key, required this.insAdmin, required this.institute, required this.department});

  @override
  State<FacManage> createState() => _FacManageState();
}

class _FacManageState extends State<FacManage> {
  List<Lecturer> lecturers=[];
  TextEditingController namex=TextEditingController();
  TextEditingController phonex=TextEditingController();

  final fkey=GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Faculty"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SafeArea(child:
      StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
          .collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
         .collection("departments").doc(widget.department.id)
          .collection("faculty").snapshots(),
          builder: (context,snapshot){
           if(snapshot.connectionState==ConnectionState.waiting){
             return Center(child: CircularProgressIndicator(),);
           }else if(snapshot.hasError){
             return Center(child: Text(snapshot.error.toString()),);
           }else if(!snapshot.hasData){
             return Center(child: Text("No data found"),);
           }else if(snapshot.hasData){
             if(snapshot.data!.docs.isEmpty){
               return Center(child: Text("No faculty found,add faculty to continue"),);
             }
             lecturers.clear();
            for(var doc in snapshot.data!.docs){
              lecturers.add(
                Lecturer(
                  id: doc.id,
                  name: doc['name'],
                    deprt: doc['depart'],
                    role: doc['role'],
                    instituteId: widget.institute.id!,
                    insAdminId: widget.insAdmin.id!,
                    departmentId: doc['department_id'],
                    designation: doc['designation'],
                    status: doc['status'],
                    email: doc['email'],
                    phone: doc['phone'],
                    semesters: List<int>.from(doc['semester']),
                    courses: List<String>.from(doc['courses']),
                    created_at: doc['created_at'].toDate(),
                )
              );
            }
            return ListView.builder(
                itemCount: lecturers.length,
                itemBuilder: (context,index){
              return Card(
                color: Colors.white,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 15
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius:28,
                            child: Text(RMFuncts.getFirstLetters(lecturers[index].name),style: TextStyle(
                              color: Colors.white,
                            ),),

                          ),),
                          Expanded(
                            flex: 4,
                            child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 9,),
                                  Text(lecturers[index].name,style: TextStyle(fontWeight: FontWeight.w600),),
                                ],
                              ),
                              SizedBox(height: 3,),
                              Row(
                                children: [
                                  SizedBox(width: 9,),
                                  Text(lecturers[index].email,style: TextStyle(color: Colors.grey),),
                                ],
                              ),
                            ],
                          ),),
                          Expanded(
                              flex: 1,
                              child: Column(children: [
                            IconButton(onPressed: (){
                              showDialog(context: context, builder: (_)=>AlertDialog(
                                title: Text("Delete Faculty"),
                                content: Text("Are you sure you want to delete this faculty?"),
                                icon: Icon(Icons.delete,color: Colors.red,size: 35,),
                                actions: [
                                  FilledButton(
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                                      ),
                                      onPressed: (){
                                    Navigator.pop(context);
                                  }, child: Text("Cancel",style: TextStyle(color: Colors.white),)),
                                  FilledButton(
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Colors.red),
                                      ),
                                      onPressed: (){
                                    Provider.of<DbService>(context,listen: false).removeFaculty(context, lecturers[index].id!);
                                    Navigator.pop(context);
                                  }, child: Text("Yes",style: TextStyle(color: Colors.white),)),
                                ],
                              ));
                            }, icon: Icon(Icons.delete,color: Colors.red,))
                          ],))
                        ],
                      ),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [

                        SizedBox(width: 9,),
                        Badge(
                          backgroundColor: Theme.of(context).primaryColor.withAlpha(40),
                          label:
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(lecturers[index].deprt,style: TextStyle(color:Theme.of(context).primaryColor,fontWeight: FontWeight.w500),),
                          ),
                        ),
                        SizedBox(width: 9,),
                        Badge(
                          backgroundColor: Theme.of(context).primaryColor.withAlpha(40),
                          label:
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(lecturers[index].designation,style: TextStyle(color:Theme.of(context).primaryColor,fontWeight: FontWeight.w500),),
                          ),
                        ),
                        SizedBox(width: 9,),
                        Badge(
                          backgroundColor: Theme.of(context).primaryColor.withAlpha(40),
                          label:
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                           child: FutureBuilder(future: getCourseCountByLecturer(lecturers[index].id!), builder: (context,snapshot){
                              if(snapshot.connectionState==ConnectionState.waiting){
                                return Text("Loading...");
                              }else if(snapshot.hasError){
                                return Text("Error: ${snapshot.error}");
                              }else if(!snapshot.hasData){
                                return Text("No data found");
                              }else{
                                return Text("${snapshot.data} Courses",style: TextStyle(color:Theme.of(context).primaryColor,fontWeight: FontWeight.w500),);
                              }
                           }),
                          ),
                        ),
                          SizedBox(width: 9,),
                          IconButton(
                              style: ButtonStyle(
                                padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                              ),
                              onPressed: (){
                            namex.text=lecturers[index].name;
                            phonex.text=lecturers[index].phone;
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
                                  Text("Update Faculty",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                                  SizedBox(height: 15,),
                                  TextFormField(
                                    controller: namex,
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
                                  TextFormField(
                                    controller: phonex,
                                    decoration: InputDecoration(
                                      labelText: "phone",
                                      prefixIcon: Icon(Icons.call),

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
                                        return "Please enter phone";
                                      }else if(v.length<10){
                                        return "name must be at least 10 characters";
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20,),
                                  ElevatedButton.icon(onPressed: (){
                                    if(fkey.currentState!.validate()){
                                      Lecturer lec=Lecturer(
                                        id: lecturers[index].id,
                                          name: namex.text.trim(),
                                          deprt: lecturers[index].deprt,
                                          role: lecturers[index].role,
                                          insAdminId:lecturers[index].insAdminId,
                                          instituteId: lecturers[index].instituteId,
                                          departmentId: lecturers[index].departmentId,
                                          designation: lecturers[index].designation,
                                          status: lecturers[index].status,
                                          email: lecturers[index].email,
                                          phone: phonex.text.trim(),
                                          semesters: lecturers[index].semesters,
                                          courses: lecturers[index].courses,
                                          created_at: lecturers[index].created_at,
                                      );
                                      Provider.of<DbService>(context,listen: false).updateFaculty(context, lec);
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

                        ],)
                    ],
                  ),
                ),
              );
            });
           }
             return Center(child: Text("No data found."),);

          })),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50)
        ),
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (_)=>AddFacultyScreen(insAdmin: widget.insAdmin, institute: widget.institute,department: widget.department)));
          // Provider.of<DbService>(context,listen: false).registerFac(
          //     widget.insAdmin.id!, widget.institute.id!,
          //     Lecturer(
          //         name: "Ayesha Zainab",
          //         deprt: "Physics",
          //         role: "faculty",
          //         instituteId: widget.institute.id!,
          //         insAdminId: widget.insAdmin.id!,
          //         designation: "Assistant Professor",
          //         status: "active",
          //         email: "az12@gmail.com",
          //         semesters: [4,6,8],
          //         courses: ["CS101","CS102","CS103","CS104"],
          //         created_at: DateTime.now(),
          //         phone: "32466676544")
          //     , "12341234", context);
      },child:
      Icon(Icons.add,color: Colors.white,fontWeight: FontWeight.bold,),
      ),
    );
  }
  Future<int> getCourseCountByLecturer(String lecturerId) async {
    try {
      final result = await FirebaseFirestore.instance
          .collectionGroup('courses')
          .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
          .where('institute_id', isEqualTo: widget.institute.id)
          .where('department_id', isEqualTo: widget.department.id)
          .where('lecturer_id', isEqualTo: lecturerId)
          .count()
          .get();
      return result.count ?? 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }
}
