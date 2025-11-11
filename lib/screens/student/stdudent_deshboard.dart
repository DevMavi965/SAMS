import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/Lecture_model.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/announcement_model.dart';
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
 List<Course> courses =[
   Course(name: "DSA", lecturer: "prof. Aslam", room: "lab 1", time: DateTime.parse("2025-11-06T08:00:00",),status: "late"),
   Course(name: "OS", lecturer: "Mr. Waqar", room: "Room 13", time:DateTime.parse("2025-11-06T09:00:00"),status: "absent"),
   Course(name: "DBMS", lecturer: "Mrs. Atia", room: "lab 3", time: DateTime.parse("2025-11-06T10:30:00"),status: "present"),
   Course(name: "CN", lecturer: "Mrs. Afia", room: "Room 10", time:DateTime.parse("2025-11-06T11:30:00"),status: "present"),

   //day2
   Course(name: "DSA", lecturer: "prof. Aslam", room: "lab 1", time: DateTime.parse("2025-11-07T08:00:00",),status: "late"),
   Course(name: "OS", lecturer: "Mr. Waqar", room: "Room 13", time:DateTime.parse("2025-11-07T09:00:00"),status: "absent"),
   Course(name: "DBMS", lecturer: "Mrs. Atia", room: "lab 3", time: DateTime.parse("2025-11-07T10:30:00"),status: "present"),
   Course(name: "CN", lecturer: "Mrs. Afia", room: "Room 10", time:DateTime.parse("2025-11-07T11:30:00"),status: "present"),

   //day3
   Course(name: "DSA", lecturer: "prof. Aslam", room: "lab 1", time: DateTime.parse("2025-11-10T08:00:00",),status: "upcoming"),
   Course(name: "OS", lecturer: "Mr. Waqar", room: "Room 13", time:DateTime.parse("2025-11-10T09:00:00"),status: "upcoming"),
   Course(name: "DBMS", lecturer: "Mrs. Atia", room: "lab 3", time: DateTime.parse("2025-11-10T10:30:00"),status: "upcoming"),
   Course(name: "CN", lecturer: "Mrs. Afia", room: "Room 10", time:DateTime.parse("2025-11-10T11:30:00"),status: "upcoming"),

   // day4
   Course(name: "DSA", lecturer: "prof. Aslam", room: "lab 1", time: DateTime.parse("2025-11-11T08:00:00",),status: "upcoming"),
   Course(name: "OS", lecturer: "Mr. Waqar", room: "Room 13", time:DateTime.parse("2025-11-11T09:00:00"),status: "upcoming"),
   Course(name: "DBMS", lecturer: "Mrs. Atia", room: "lab 3", time: DateTime.parse("2025-11-11T10:30:00"),status:"upcoming"),
   Course(name: "CN", lecturer: "Mrs. Afia", room: "Room 10", time:DateTime.parse("2025-11-11T11:30:00"),status:"upcoming"),

   // day5
   Course(name: "DSA", lecturer: "prof. Aslam", room: "lab 1", time: DateTime.parse("2025-11-12T08:00:00",),status:"upcoming"),
   Course(name: "OS", lecturer: "Mr. Waqar", room: "Room 13", time:DateTime.parse("2025-11-12T09:00:00"),status: "upcoming"),
   Course(name: "DBMS", lecturer: "Mrs. Atia", room: "lab 3", time: DateTime.parse("2025-11-12T10:30:00"),status: "upcoming"),
   Course(name: "CN", lecturer: "Mrs. Afia", room: "Room 10", time:DateTime.parse("2025-11-12T11:30:00"),status: "upcoming"),

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
   LeaveApplication(type: "medical", reason: "sick", fromDate: "10/12/2025",
       tillDate: "13/12/2025", status: "pending", appliedDate: "9/12/2025",std_id:widget.student.id,std_name: widget.student.name ),
   LeaveApplication(type: "emergency", reason: "sick", fromDate: "10/12/2025", tillDate: "13/12/2025", status: "approved",
       appliedDate: "9/12/2025",std_id:widget.student.id,std_name: widget.student.name),
 ];
  List<In_Notification> notifications=[
    In_Notification(title: "attendance", body: "body of notification attendance ", type: "attendance", time: "10:00", is_read: false),
    In_Notification(title: "good", body: "you passed quiz #A14 ", type: "good", time: "10:00", is_read: true),
    In_Notification(title: "warning", body: "low attendance ", type: "warning", time: "10:00", is_read: false),
    In_Notification(title: "upcoming", body: "date sheet revealed for upcoming exams ", type: "upcoming", time: "10:00", is_read: true),

  ];
  late List<Widget> screens=[
    StdHome(announcements: stud_announcements, courses: courses, student: widget.student),
    Scheduletab(courses: courses),
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
