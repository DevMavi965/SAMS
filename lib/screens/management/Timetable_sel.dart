import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/screens/management/TimeTable_mng.dart';

import '../../services/db_service.dart';

class TimetableSel extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const TimetableSel({super.key, required this.insAdmin, required this.institute});

  @override
  State<TimetableSel> createState() => _TimetableSelState();
}

class _TimetableSelState extends State<TimetableSel> {
  List<Department> departments=[];
  List<Session> sessions =[];
  List<Semester> semesters=[];
  String? depId,sessionId,semesterId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Timetables",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10
        ),
        child: ListView(
          children: [
            SizedBox(height: 20,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white
              ),
              margin: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: StreamBuilder(
                  stream:Provider.of<DbService>(context,listen: false).dbref
                      .collection("ins_admins").doc(widget.insAdmin.id)
                      .collection("institutes").doc(widget.institute.id)
                      .collection("departments").snapshots() ,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return Center(child: CircularProgressIndicator(),);
                    }else if(snapshot.hasError){
                      return Center(child: Text(snapshot.error.toString()),);
                    }else if(!snapshot.hasData){
                      return Center(child: Text("No data found"),);
                    }else if(snapshot.hasData){
                      if(snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
                              child: Card(child: Text("No department found,add department to continue"))),);
                      }
                      departments.clear();
                      for(var doc in snapshot.data!.docs){
                        departments.add(
                            Department(
                              id: doc.id,
                                name: doc['name'],
                                hod_name: doc['hod_name'],
                                created_at: doc['created_at'].toDate(),
                            )
                        );
                      }
                      return DropdownButton(
                          value: depId,
                          hint: Text("Select Department"),
                          isExpanded: true,
                          icon: Icon(PhosphorIconsBold.buildingApartment),
                          items: [
                            for(var dep in departments)
                              DropdownMenuItem(value: dep.id,child: Text(dep.name),),
                          ],
                          onChanged: (v){
                            setState(() {
                              depId=v;
                              sessionId=null;
                              semesterId=null;
                            });
                          });
                    }
                    return SizedBox();
                  }),
            ),
            SizedBox(height: 15,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white
              ),
              margin: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: StreamBuilder(
                  stream:Provider.of<DbService>(context,listen: false).dbref
                      .collection("ins_admins").doc(widget.insAdmin.id)
                      .collection("institutes").doc(widget.institute.id)
                      .collection("departments").doc(depId)
                      .collection("sessions")
                      .snapshots() ,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return Center(child: SizedBox(
                          height: 60,
                          width: 60,
                          child: Lottie.asset("assets/anims/an1.json")),);
                    }else if(snapshot.hasError){
                      return Center(child: Text(snapshot.error.toString()),);
                    }else if(!snapshot.hasData){
                      return Center(child: Text("No data found"),);
                    }else if(snapshot.hasData){
                      if(snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,vertical: 10
                          ),
                            child: Text("No session found,add session to continue"));
                      }
                      sessions.clear();
                      for(var session in snapshot.data!.docs){
                        sessions.add(
                            Session(
                              id: session.id,
                              name: session['name'],
                              start_date: session['start_date'].toDate(),
                              end_date: session['end_date'].toDate(), )
                        );

                      }
                      return DropdownButton(
                          value: sessionId,
                          hint: Text("Select Session"),
                          isExpanded: true,
                          icon: Icon(Icons.calendar_month_rounded),
                          items: [
                            for(var ses in sessions)
                              DropdownMenuItem(value: ses.id,child: Text(ses.name),),
                          ],
                          onChanged: (v){
                            setState(() {
                              sessionId=v;
                              semesterId=null;
                            });
                          });
                    }
                    return SizedBox();
                  }),
            ),
            SizedBox(height: 15,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white
              ),
              margin: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: StreamBuilder(
                  stream:Provider.of<DbService>(context,listen: false).dbref
                      .collection("ins_admins").doc(widget.insAdmin.id)
                      .collection("institutes").doc(widget.institute.id)
                      .collection("departments").doc(depId)
                      .collection("sessions").doc(sessionId)
                      .collection("semesters")
                      .snapshots() ,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return Center(child:SizedBox(
                          height: 60,
                          width: 60,
                          child: Lottie.asset("assets/anims/an1.json")),);
                    }else if(snapshot.hasError){
                      return Center(child: Text(snapshot.error.toString()),);
                    }else if(!snapshot.hasData){
                      return Center(child: Text("No data found"),);
                    }else if(snapshot.hasData){
                      if(snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: 
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white
                            ),
                              padding: EdgeInsets.all(5),
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child: Row(
                                  children: [
                                    Text("No semester found,add semester to continue"),
                                  ],
                                ),
                              )),);
                      }
                      semesters.clear();
                      for(var sem in snapshot.data!.docs){
                        semesters.add(
                            Semester(
                                id: sem.id,
                                institute_id: sem['institute_id'],
                                ins_admin_id: sem["ins_admin_id"],
                                department_id: sem["department_id"],
                                session_id: sem["session_id"],
                                semester_no: sem["semester_no"],
                                start_date: sem["start_date"].toDate(),
                                end_date: sem["end_date"].toDate(),
                            )
                        );

                      }
                      return DropdownButton(
                          value: semesterId,
                          hint: Text("Select Semester"),
                          isExpanded: true,
                          icon: Icon(Icons.calendar_today_outlined),
                          items: [
                            for(var sem in semesters)
                              DropdownMenuItem(value: sem.id,child: Text(sem.semester_no.toString()),),
                          ],
                          onChanged: (v){
                            setState(() {
                              semesterId=v;
                            });
                          });
                    }
                    return SizedBox();
                  }),
            ),
            SizedBox(height: 25,),
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                ),
                onPressed: (){
              if(depId!=null && sessionId!=null && semesterId!=null){
                Department dep=departments.firstWhere((element) => element.id==depId);
                Session ses=sessions.firstWhere((element) => element.id==sessionId);
                Semester sem=semesters.firstWhere((element) => element.id==semesterId);
                 Navigator.push(context, MaterialPageRoute(builder: (_)=>TimetableMng(insAdmin: widget.insAdmin, institute: widget.institute, department: dep, session: ses, semester: sem,)));

              }else{
                setState(() {
                  depId=semesterId=sessionId=null;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please select all fields"),));
              }
            }, child: Text("View Timetable",style: TextStyle(color: Colors.white),))
          ],
        ),
      ),
    );
  }
}
