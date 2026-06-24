import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/screens/management/Course_ops.dart';

import '../../../models/department.dart';
import '../../../services/db_service.dart';

class CourseSemester extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session ;
  const CourseSemester({super.key, required this.insAdmin, required this.institute, required this.department, required this.session});

  @override
  State<CourseSemester> createState() => _CourseSemesterState();
}

class _CourseSemesterState extends State<CourseSemester> {
  List<Semester> semesters=[];
  DateTime? startDate,endDate;
  DateTime? startDate1,endDate1;
  int? selectedSemester;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
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
                    return InkWell(
                      onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (_)=>CourseOps(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, session: widget.session, semester: semesters[count])));
                      },
                      child: Card(
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
                                SizedBox(height: 5,),
                                //update semester
                              ],
                            ))
                          ],
                        ),),
                    );
                  });
            }
            return SizedBox();
          }),
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
}
