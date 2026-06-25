import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/screens/management/create_update/semester_ops.dart';

import '../../../models/department.dart';
import '../../../services/db_service.dart';

class AddUpdateSession extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  const AddUpdateSession({super.key, required this.department, required this.insAdmin, required this.institute});

  @override
  State<AddUpdateSession> createState() => _AddUpdateSessionState();
}

class _AddUpdateSessionState extends State<AddUpdateSession> {
  List<Session> sessions=[];
  DateTime? startDate,endDate;
  DateTime? startDate1,endDate1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("${widget.department.name} Sessions"),
        centerTitle: true,
      ),
      body: StreamBuilder(stream:  Provider.of<DbService>(context,listen: false).dbref
          .collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").doc(widget.department.id)
          .collection("sessions").snapshots(),
          builder: (context,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(child: CircularProgressIndicator(),);
          }else if(snapshot.hasError){
            return Center(child: Text(snapshot.error.toString()),);
          }else if(!snapshot.hasData){
            return Center(child: Text("No data found"),);
          }else if(snapshot.hasData){
            sessions.clear();
            if(snapshot.data!.docs.isEmpty){
              return Center(child: Text("No sessions found"),);
            }else{
              for(var session in snapshot.data!.docs){
              sessions.add(
                Session(
                  id: session.id,
                    name: session['name'],
                    start_date: session['start_date'].toDate(),
                    end_date: session['end_date'].toDate(), )
              );
              }
              return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context,count){
                return InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder:
                        (_)=>SemesterOps(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, session: sessions[count])));
                  },
                  child: Card(
                    color: Colors.white,
                    child:
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 5,),
                        Expanded(
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(1),
                            child: Icon(Icons.school_outlined,color:Colors.white,size: 30,),
                          ),
                        ),
                        SizedBox(width: 15,),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sessions[count].name,style: TextStyle(fontWeight: FontWeight.w600,fontSize: 18,color: Theme.of(context).primaryColor),),
                              SizedBox(height: 10,),
                              Text("Start Date: ${sessions[count].start_date.day}/${sessions[count].start_date.month}/${sessions[count].start_date.year}",style: TextStyle(color: Colors.black.withAlpha(130)),),
                              SizedBox(height: 10,),
                              Text("End Date: ${sessions[count].end_date.day}/${sessions[count].end_date.month}/${sessions[count].end_date.year}",style: TextStyle(color: Colors.black.withAlpha(130)),),
                              SizedBox(height: 10,),
                            ],
                          ),
                        ),
                        Expanded(child: Column(children: [
                          IconButton(onPressed: () async {//delete button
                             int semesterCount=await getSemesterCount(context, sessions[count].id!);
                             if(semesterCount>0){
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot delete session with semesters"),backgroundColor: Colors.red,));
                             }else{
                               showDialog(context: context, builder: (_)=>AlertDialog(
                                 backgroundColor: Colors.white,
                                 icon: Icon(Icons.delete,color: Theme.of(context).primaryColor,size: 33,),
                                 title: Text("Delete Session"),
                                 content: Text("Are you sure you want to delete this session?"),
                                 actions: [
                                   FilledButton(onPressed: (){
                                     Navigator.pop(context);
                                   },style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                                   ),child: Text("Cancel",style: TextStyle(color: Colors.white),),),
                                   FilledButton(onPressed: (){
                                     Navigator.pop(context);
                                     Provider.of<DbService>(context,listen: false).removeSession(context, sessions[count].id!);

                                   },style: ButtonStyle(backgroundColor:MaterialStateProperty.all(Colors.red), ),
                                     child: Text("Yes",style: TextStyle(color: Colors.white),),)
                                 ],
                               ));
                             }
                          },icon: Icon(Icons.delete,color: Colors.red,),),
                          SizedBox(height: 5,),
                          // update button
                          IconButton(onPressed: (){
                            startDate1=sessions[count].start_date;
                            endDate1=sessions[count].end_date;
                            showDialog(context: context, builder:
                                (_)=>StatefulBuilder(
                                    builder: (context,setState1)=>AlertDialog(
                              backgroundColor: Colors.white,
                              icon: Icon(PhosphorIconsDuotone.calendarHeart,color: Theme.of(context).primaryColor,size: 33,),
                              title: Text("Update Session"),
                              content: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                    String name=getDepartmentName(widget.department.name,startDate1!,endDate1!);
                                    if(startDate1!.isBefore(endDate1!)){
                                      if(endDate1!.difference(startDate1!).inDays>=180){
                                        Provider.of<DbService>(context,listen: false).updateSession(context,
                                            Session(
                                                id: sessions[count].id,
                                                name: name,
                                                start_date:startDate1! ,
                                                end_date: endDate1!));
                                        Navigator.pop(context);
                                        setState1((){
                                          startDate1=null;
                                          endDate1=null;
                                        });
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
                        ],))
                      ],
                    ),
                  ),),
                );
              });
            }
          }
          return SizedBox();

      }),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100)
        ),
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: (){
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
                  String name=getDepartmentName(widget.department.name,startDate!,endDate!);
                  if(startDate!.isBefore(endDate!)){
                  //   session  must be at least 6 months long
                    if(endDate!.difference(startDate!).inDays>=180){
                      Provider.of<DbService>(context,listen: false).addSession(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!,
                          Session(name: name, start_date:startDate! , end_date: endDate!));
                      Navigator.pop(context);
                      setState2((){
                        startDate=null;
                        endDate=null;
                      });
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("session must be at least 6 months long"),));
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
        },child: Icon(Icons.add,color: Colors.white,),),
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

  String getDepartmentName(String name,DateTime st,DateTime et) {
    String initial=RMFuncts.getFirstLetters(name);
    String year1=st.year.toString();
    String year2=et.year.toString();
    // i need 2nd
    String result="$initial$year1-${year2[2]}${year2[3]}".toUpperCase();
    return result;
  }
  Future<int> getSemesterCount(BuildContext context,String sessionID) async {
    try{
      final counter = await Provider.of<DbService>(context,listen: false)
          .dbref.collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").doc(widget.department.id)
          .collection("sessions").doc(sessionID)
          .collection("semesters")
          .count().get();


      return counter.count??0;
    }catch(e){
      print(e.toString());
      return 0;
    }
  }
}
