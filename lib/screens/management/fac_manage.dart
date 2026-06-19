import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/screens/management/create_update/add_faculty.dart';
import 'package:smas3/services/db_service.dart';

class FacManage extends StatefulWidget with RMFuncts{
  final InsAdmin insAdmin;
  final Institute institute;
  const FacManage({super.key, required this.insAdmin, required this.institute});

  @override
  State<FacManage> createState() => _FacManageState();
}

class _FacManageState extends State<FacManage> {
  List<Lecturer> lecturers=[];
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
               return Center(child: Text("No data found"),);
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
                            child: Text("${lecturers[index].courses!.length} courses",style: TextStyle(color:Theme.of(context).primaryColor,fontWeight: FontWeight.w500),),
                          ),
                        )
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
          Navigator.push(context, MaterialPageRoute(builder: (_)=>AddFacultyScreen(insAdmin: widget.insAdmin, institute: widget.institute,)));
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
}
