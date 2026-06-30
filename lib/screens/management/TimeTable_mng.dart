import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/screens/management/create_update/Daily_schedule.dart';

import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../models/semester.dart';
import '../../models/session.dart';

class TimetableMng extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;
  const TimetableMng({super.key, required this.insAdmin, required this.institute, required this.department, required this.session, required this.semester});

  @override
  State<TimetableMng> createState() => _TimetableMngState();
}
class _TimetableMngState extends State<TimetableMng> {
  late DateTime startDate=widget.semester.start_date;
  late DateTime endDate=widget.semester.end_date;

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
          horizontal: 5,vertical: 5
        ),
        child: ListView(
          children: [
            SizedBox(height: 10,),
            for(int i=0;i<get_activeDays(startDate, endDate);i++)
          startDate.add(Duration(days: i)).weekday!=DateTime.saturday && startDate.add(Duration(days: i)).weekday!=DateTime.sunday?
          InkWell(
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (_)=>DailySchedule(date: startDate.add(Duration(days: i),), insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, session: widget.session, semester: widget.semester,)));
              // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("you clicked on ${DateFormat("dd MMM yy").format(startDate.add(Duration(days: i)))}")));
            },
            child: Card(
               color: Colors.white,
               child: Container(
                 margin: EdgeInsets.symmetric(
                   horizontal: 5,vertical: 10
                 ),
                 child: Row(
                   children: [
                     Expanded(child: CircleAvatar(child: Icon(PhosphorIconsBold.chalkboardTeacher,size: 25,),)),
                     SizedBox(width: 5,),
                     Expanded(child: Text(DateFormat("dd MMM yy").format(startDate.add(Duration(days: i))))),
                     Expanded(flex:2,child: SizedBox()),
                     Expanded(flex:1,child: IconButton(onPressed: (){
                       showDialog(context: context, builder: (context)=>AlertDialog(
                         title: Text("Mark as Holiday"),
                         content: Text("Are you sure you want to mark this day as holiday?"),
                         actions: [
                           ElevatedButton(onPressed: (){
                             Navigator.pop(context);
                           }, child: Text("Yes")),
                           ElevatedButton(onPressed: (){
                             Navigator.pop(context);
                           }, child: Text("No"))
                         ],
                       ));
                     }, icon: Icon(PhosphorIconsBold.calendarX))),
                   ],
                 ),
               ),
             ),
          ):
          SizedBox(),
          ],
        ),
      ),
    );
  }
  int get_activeDays(DateTime startDate,DateTime endDate){
    int days=0;
    while(startDate.isBefore(endDate)){
      if(startDate.weekday!=DateTime.saturday && startDate.weekday!=DateTime.sunday){
        days++;
      }
      startDate=startDate.add(Duration(days: 1));
    }
    return days;
  }
}
