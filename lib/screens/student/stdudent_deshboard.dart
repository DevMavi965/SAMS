import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/admin/admin_deshboard.dart';
import 'package:smas3/screens/student/alert_tab.dart';
import 'package:smas3/screens/student/leave_tab.dart';
import 'package:smas3/screens/student/profile_tab.dart';
import 'package:smas3/screens/student/scheduleTab.dart';
import 'package:smas3/screens/student/std_home.dart';
import 'package:smas3/widgets/in_Notif_model.dart';
import 'package:smas3/widgets/student_widgets/Custome_line_chart.dart';
import 'package:smas3/widgets/student_widgets/att_rec_card.dart';
import 'package:smas3/widgets/student_widgets/daily_status_card.dart';
import 'package:smas3/widgets/student_widgets/over_all_att_card.dart';
import 'package:smas3/widgets/student_widgets/std_announc_card.dart';
import 'package:smas3/widgets/student_widgets/upcoming_class_card.dart';

import '../../models/Leave_Application_Model.dart';

class StudentDeshboard extends StatefulWidget {
  final Student student;
  const StudentDeshboard({super.key, required this.student});

  @override
  State<StudentDeshboard> createState() => _StudentDeshboardState();
}

class _StudentDeshboardState extends State<StudentDeshboard> {
 int current=0;
  List<String> menus=["home","schedule","leave","alerts","profile"];
 List<LectureModel> lectures =[
   LectureModel(dated: DateTime.parse("2025-11-06T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-06T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-06T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),


   //day3
   LectureModel(dated: DateTime.parse("2025-11-10T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-10T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-10T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),


   // day4
   LectureModel(dated: DateTime.parse("2025-11-11T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-11T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-11T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),

   // day5
   LectureModel(dated: DateTime.parse("2025-11-12T08:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-12T09:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-12T10:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),
   LectureModel(dated: DateTime.parse("2025-11-12T11:00:00"), start_time: TimeOfDay.now(), end_time: TimeOfDay.now(), students: null, present: null, absent: null, room: "16A"),

 ];
  List<Announcement> stud_announcements = [
    Announcement(an_title: "system maintainance",
  an_message:"this  an_message dedicated to students of field to improve ets egh   hiu   fff  f yufd dytdydyd fdd",
  an_type: "urgent", target_aud: "All users"),
    Announcement(an_title: "Anuaual Sports gala",
  an_message:"this  an_message dedicated to students of field to improve ets egh   hiu   fff  f yufd dytdydyd fdd",
  an_type: "general", target_aud: "Students"),
    Announcement(an_title: "Anuaual Sports gala",
        an_message:"this  an_message dedicated to students of field to improve ets egh   hiu   fff  f yufd dytdydyd fdd",
        an_type: "event", target_aud: "Students")
  ];

 late List<LeaveApplication> leaveApplications = [
   LeaveApplication(appliedDate:DateTime.now(), type: "academic", fromDate:DateTime.now(), tillDate: DateTime.now().add(Duration(days: 3)), reason: "reason of application", status: "pending", std_name: "arslan masoud", std_id: '505778', approvedby: null),

 ];
  List<In_Notification> notifications=[
    In_Notification(title: "attendance", body: "body of notification attendance ", type: "attendance", time: "10:00", is_read: false),
    In_Notification(title: "good", body: "you passed quiz #A14 ", type: "good", time: "10:00", is_read: true),
    In_Notification(title: "warning", body: "low attendance ", type: "warning", time: "10:00", is_read: false),
    In_Notification(title: "upcoming", body: "date sheet revealed for upcoming exams ", type: "upcoming", time: "10:00", is_read: true),

  ];
  late List<Widget> screens=[
    StdHome(announcements: stud_announcements, lectures: lectures, student: widget.student),
    Scheduletab(lectures: lectures,),
    LeaveTab(leaveApplications: leaveApplications,student: widget.student,),
    AlertTab(notifications: notifications,),
    ProfileTab(student: widget.student,)

  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[current],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex:current,

        onTap: (v){
          setState(() {
            current=v;
          });
          print("tapped$v");
        },
        items: [
          for(int i=0;i<menus.length;i++)
          BottomNavigationBarItem(
            icon:
            i==4?Icon(CupertinoIcons.profile_circled):
            (i==3?Icon(PhosphorIconsBold.bell):
            (i==2?Icon(PhosphorIconsBold.notebook):
            (i==0? Icon(Icons.home):Icon(PhosphorIconsBold.calendarBlank)))),
            label: menus[i],

            ),
        ]
      )
    );
  }
}
