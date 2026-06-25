import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';

import '../../../models/department.dart';
import '../../../services/db_service.dart';

class SemesterOps extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session ;
  const SemesterOps({super.key, required this.insAdmin, required this.institute, required this.department, required this.session});

  @override
  State<SemesterOps> createState() => _SemesterOpsState();
}

class _SemesterOpsState extends State<SemesterOps> {
  List<Semester> semesters=[];
  DateTime? startDate,endDate;
  DateTime? startDate1,endDate1;
  int? selectedSemester;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Semesters of ${widget.session.name}",style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
          .collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").doc(widget.department.id)
          .collection("sessions").doc(widget.session.id)
          .collection("semesters")
          .snapshots(),
          builder: (context,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(child: CircularProgressIndicator(),);
          }else if(snapshot.hasError){
            return Center(child: Text(snapshot.error.toString()),);
          }else if(!snapshot.hasData){
            return Center(child: Text("No data found"),);
          }else if(snapshot.hasData){
            semesters.clear();
           for(var sems in snapshot.data!.docs){
             semesters.add(Semester(
               id: sems.id,
                 institute_id: widget.institute.id!,
                 ins_admin_id: widget.insAdmin.id!,
                 department_id: widget.department.id!,
                 session_id: widget.session.id!,
                 semester_no: sems['semester_no'],
                 start_date: sems['start_date'].toDate(),
                 end_date: sems['end_date'].toDate()
             ));
           }
           return semesters.isEmpty?Center(child: Text("No semesters found, Add first"),): ListView.builder(
               itemCount: semesters.length,
               itemBuilder: (_,count){
             return Card(
               color: Colors.white,
               child:
             Row(
               children: [
                 SizedBox(width: 10,),
                 Expanded(
                   child: CircleAvatar(
                     radius: 30,
                     backgroundColor: Theme.of(context).primaryColor.withOpacity(1),
                     child: Icon(PhosphorIconsDuotone.folderUser,color:Colors.white,size: 30,),
                   ),
                 ),
                 SizedBox(width: 15,),
                 Expanded(
                   flex: 5,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                     SizedBox(height: 10,),
                     Text("Semester ${semesters[count].semester_no}",style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16),),
                     SizedBox(height: 10,),
                     Text("Start Date: ${semesters[count].start_date.day}/${semesters[count].start_date.month}/${semesters[count].start_date.year}",style: TextStyle(color: Colors.black87,fontSize: 12),),
                     SizedBox(height: 10,),
                     Text("End Date: ${semesters[count].end_date.day}/${semesters[count].end_date.month}/${semesters[count].end_date.year}",style: TextStyle(color: Colors.black87,fontSize: 12),),
                     SizedBox(height: 10,),
                   ],),
                 ),
                 Expanded(child: Column(
                   children: [
                     IconButton(onPressed: () async {//delete button
                        int studentCount=await getStudentsCount(context, semesters[count].id!);
                        if(studentCount>0){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot delete semester with students"),backgroundColor: Colors.red,));
                        }else{
                       showDialog(context: context, builder: (_)=>AlertDialog(
                         backgroundColor: Colors.white,
                         icon: Icon(Icons.delete,color: Theme.of(context).primaryColor,size: 33,),
                         title: Text("Delete Semester"),
                         content: Text("Are you sure you want to delete this semester?"),
                         actions: [
                           FilledButton(onPressed: (){
                             Navigator.pop(context);
                           },style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                           ),child: Text("Cancel",style: TextStyle(color: Colors.white),),),
                           FilledButton(onPressed: (){
                             Navigator.pop(context);
                             Provider.of<DbService>(context,listen: false).removeSemester(context, semesters[count].id!);

                           },style: ButtonStyle(backgroundColor:MaterialStateProperty.all(Colors.red), ),
                             child: Text("Yes",style: TextStyle(color: Colors.white),),)
                         ],
                       ));}
                     },icon: Icon(Icons.delete,color: Colors.red,),),
                     SizedBox(height: 5,),
                     //update semester
                     IconButton(onPressed: (){//
                       startDate1=semesters[count].start_date;
                       endDate1=semesters[count].end_date;
                       selectedSemester=semesters[count].semester_no;
                       showDialog(context: context, builder:
                           (_)=>StatefulBuilder(
                           builder: (context,setState1)=>AlertDialog(
                             backgroundColor: Colors.white,
                             icon: Icon(PhosphorIconsDuotone.calendarHeart,color: Theme.of(context).primaryColor,size: 33,),
                             title: Text("Update Semester"),
                             content: Container(
                               padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                               child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [

                                   SizedBox(height: 10,),
                                   DropdownButton(
                                       value: selectedSemester,
                                       items: [
                                         for(int i=1;i<=8;i++)
                                           // if(!semesters.any((element) => element.semester_no==i))
                                             DropdownMenuItem(
                                               value: i,
                                               child: Text("Semester $i"),
                                             )
                                       ], onChanged: (v){
                                     setState1((){
                                       selectedSemester=v;
                                     });
                                   }),
                                   SizedBox(height: 10,),
                                   Text("Start date"),
                                   SizedBox(height: 10,),
                                   // stratrd date
                                   InkWell(
                                       onTap: ()async{
                                         await getFirstDate1();
                                         setState1((){});
                                       },
                                       child: Row(
                                         children: [
                                           Icon(Icons.calendar_month,color: Theme.of(context).primaryColor,),
                                           SizedBox(width: 10,),
                                           Text(startDate1==null?"select Start Date":DateFormat("dd/MM/yyyy").format(startDate1!).toString().replaceAll("/", "-")),
                                         ],
                                       )
                                   ),
                                   SizedBox(height: 10,),
                                   Text("End date"),
                                   SizedBox(height: 10,),
                                   // last date
                                   InkWell(
                                       onTap:()async{
                                         await getLastDate1();
                                         setState1((){});
                                       },
                                       child: Row(
                                         children: [
                                           Icon(Icons.calendar_month,color: Theme.of(context).primaryColor,),
                                           SizedBox(width: 10,),
                                           Text(endDate1==null?"select Start Date":DateFormat("dd/MM/yyyy").format(endDate1!)),
                                         ],
                                       )),
                                   SizedBox(height: 10,),
                                 ],
                               ),
                             ),
                             actions: [
                               FilledButton(onPressed: (){
                                 if(startDate1!=null && endDate1!=null){
                                   // making session name like cs2022-26
                                   if(startDate1!.isBefore(endDate1!)){
                                     //   session  must be at least 6 months long
                                     if(endDate1!.difference(startDate1!).inDays>=180){
                                       if(selectedSemester!=null){
                                         if(semesters.any((element) => element.semester_no==selectedSemester! && element.id != semesters[count].id)){
                                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester already exists"),));
                                           return;
                                         }else{
                                         Provider.of<DbService>(context,listen: false).updateSemester(context,
                                             Semester(
                                               id: semesters[count].id,
                                                 institute_id: widget.institute.id!,
                                                 ins_admin_id: widget.insAdmin.id!,
                                                 department_id: widget.department.id!,
                                                 session_id: widget.session.id!,
                                                 semester_no: selectedSemester!,
                                                 start_date: startDate1!,
                                                 end_date: endDate1!
                                             )
                                         );
                                         Navigator.pop(context);
                                         setState1((){
                                           startDate1=null;
                                           endDate1=null;
                                           selectedSemester=null;
                                         });}
                                       }else{
                                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please select semester"),));
                                       }
                                     }
                                     else if(endDate1!.difference(startDate1!).inDays<180){
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be at least 6 months long"),));
                                     }
                                     else if(startDate!.isBefore(widget.session.start_date) || startDate!.isAfter(widget.session.end_date)){
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be within session start and end date"),));
                                     }
                                     else if(endDate1!.difference(startDate1!).inDays>400){
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be at most 1 years long"),));
                                     }
                                     else{
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be at least 6 months long"),));
                                     }
                                   }else{
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("start date must be before end date"),));
                                   }
                                 }else{
                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please select start and end date"),));
                                 }
                               }, child: Text("update"),),
                               FilledButton(onPressed: (){
                                 Navigator.pop(context);
                               }, child: Text("Cancel"),),
                             ],
                           )));
                     },icon: Icon(Icons.edit_calendar,color: Theme.of(context).primaryColor,),),
                   ],
                 ))
               ],
             ),);
           });
          }
          return SizedBox();
          }),
      floatingActionButton: FloatingActionButton(onPressed: (){
        showDialog(context: context, builder:(context)=>StatefulBuilder(builder:
            (_,setState2)=>AlertDialog(
          backgroundColor: Colors.white,
          icon: Icon(PhosphorIconsDuotone.calendarHeart,color: Theme.of(context).primaryColor,size: 33,),
          title: Text("Add Session"),
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10,),//delete
                DropdownButton(
                    value: selectedSemester,
                    items: [
                  for(int i=1;i<=8;i++)
                    if(!semesters.any((element) => element.semester_no==i))
                    DropdownMenuItem(
                      value: i,
                      child: Text("Semester $i"),
                    )
                ], onChanged: (v){
                      setState2((){
                      selectedSemester=v;
                    });
                }),
                SizedBox(height: 10,),
                Text("Start date"),
                SizedBox(height: 10,),
                // stratrd date
                InkWell(
                    onTap: ()async{
                      await getFirstDate();
                      setState2((){});
                    },
                    child:
                    Row(
                      children: [
                        Icon(Icons.calendar_month,color: Theme.of(context).primaryColor,),
                        SizedBox(width: 10,),
                        Text(startDate==null?"select Start Date":DateFormat("dd/MM/yyyy").format(startDate!).toString().replaceAll("/", "-")
                        ),
                      ],
                    )
                )
                ,
                SizedBox(height: 10,),
                Text("End date"),
                SizedBox(height: 10,),
                // last date
                InkWell(
                    onTap: ()async{
                      await getLastDate();
                      setState2((){});
                    },
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month,color: Theme.of(context).primaryColor,),
                        SizedBox(width: 10,),
                        Text(endDate==null?"select Start Date":DateFormat("dd/MM/yyyy").format(endDate!).replaceAll("/", "-")
                        ),
                      ],
                    )),
                SizedBox(height: 10,),
              ],
            ),
          ),
          actions: [
            FilledButton(onPressed: (){
              if(startDate!=null && endDate!=null){
                // making session name like cs2022-26
                if(startDate!.isBefore(endDate!)){
                  //   session  must be at least 6 months long
                  if(endDate!.difference(startDate!).inDays>=180){
                    if(selectedSemester!=null){
                      Provider.of<DbService>(context,listen: false).addSemester(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!, widget.session.id!,
                          Semester(
                              institute_id: widget.institute.id!,
                              ins_admin_id: widget.insAdmin.id!,
                              department_id: widget.department.id!,
                              session_id: widget.session.id!,
                              semester_no: selectedSemester!,
                              start_date: startDate!,
                              end_date: endDate!
                          )
                      );
                      Navigator.pop(context);
                      setState2((){
                        startDate=null;
                        endDate=null;
                        selectedSemester=null;
                      });
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please select semester"),));
                    }
                  }else if(startDate!.isBefore(widget.session.start_date) || startDate!.isAfter(widget.session.end_date)){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be within session start and end date"),));
                  }
                  else if(endDate!.difference(startDate!).inDays<180){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be at least 6 months long"),));
                  }else if(endDate!.difference(startDate!).inDays>400){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be at most 1 years long"),));
                  }
                  else{
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester must be at least 6 months long"),));
                  }
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("start date must be before end date"),));
                }
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please select start and end date"),));
              }


            }, child: Text("Add"),),
            FilledButton(onPressed: (){
              Navigator.pop(context);
            }, child: Text("Cancel"),),
          ],
        )
        ));
      },
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100)
        ),
        child: Icon(Icons.add,color: Colors.white,),),
    );

  }
  getFirstDate() async {
    // can be three+ year session so we need to checkit
    DateTime firstDate=DateTime.now().subtract(Duration(days: 395*4));
    DateTime lastDate=DateTime.now();
    startDate=await showDatePicker(
        context: context,
        firstDate: firstDate,
        initialDate: DateTime.now(),
        lastDate: lastDate);
  }
  getFirstDate1() async {
    // can be three+ year session so we need to checkit
    DateTime firstDate=DateTime.now().subtract(Duration(days: 395*4));
    DateTime lastDate=DateTime.now();
    startDate1=await showDatePicker(
        context: context,
        firstDate: firstDate,
        initialDate: DateTime.now(),
        lastDate: lastDate);
  }
  getLastDate() async {

    DateTime firstDate=DateTime.now();
    // can be three+ year session so we need to checkit
    DateTime lastDate=DateTime.now().add(Duration(days: 365*6));
    endDate=await showDatePicker(
        context: context,
        firstDate: firstDate,
        initialDate: DateTime.now().add(Duration(days: 185)),
        lastDate: lastDate);
  }
  getLastDate1() async {

    DateTime firstDate=DateTime.now();
    // can be three+ year session so we need to checkit
    DateTime lastDate=DateTime.now().add(Duration(days: 365*6));
    endDate1=await showDatePicker(
        context: context,
        firstDate: firstDate,
        initialDate: DateTime.now().add(Duration(days: 185)),
        lastDate: lastDate);
  }
  Future<int> getStudentsCount(BuildContext context,String semesterID) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .dbref.collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").doc(widget.department.id)
          .collection("sessions").doc(widget.session.id)
          .collection("semesters").doc(semesterID)
          .collection("students")
          .count().get();


      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }
}
