import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/screens/faculty/fac_home.dart';
import 'package:smas3/screens/faculty/fac_leave_tab.dart';
import 'package:smas3/screens/faculty/fac_mark_attendance.dart';
import 'package:smas3/screens/faculty/fac_profile_tab.dart';
import 'package:smas3/screens/faculty/fac_reports_tab.dart';

import '../../models/course.dart';
class FacDeshboard extends StatefulWidget {
  final Lecturer lecturer;
   FacDeshboard({super.key, required this.lecturer});

  @override
  State<FacDeshboard> createState() => _FacDeshboardState();
}

class _FacDeshboardState extends State<FacDeshboard> {
  int current=3;
  Lecturer lecturer=
  Lecturer(id: "6789",
    instituteId: "123456",
    insAdminId: '3476987',
    role: "faculty",
    name:"murad ali",
    deprt: "Computer Science",
    designation: "Assistant Professor",
    status: "active",
    email: "murad@gmail.com",
    phone: "03351094534",
    courses: ["CS703","CS704"],
    semesters: [1,2],);
  List<String> menus=[
    "Home",
    "Mark",
    "Leave",
    "Reports",
    "Profile"
  ];
  late List<Widget> screens=[
    FacHomeTab(lecturer: lecturer,),
    FacMarkAttendanceTab(),
    FacLeaveTab(),
    FacReportsTab(),
    FacProfileTab(lecturer: lecturer,)

  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            margin: EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 15,

            ),
            // color: Colors.grey,
            child: screens[current]),
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
            type: BottomNavigationBarType.fixed,
            items: [
              for(int i=0;i<menus.length;i++)
                BottomNavigationBarItem(
                  icon:
                  i==4?Icon(PhosphorIconsBold.user):
                  (i==3?Icon(PhosphorIconsBold.chartBar):
                  (i==2?Icon(PhosphorIconsBold.notebook):
                  (i==0? Icon(Icons.home):Icon(PhosphorIconsBold.userFocus)))),
                  label: menus[i],

                ),
            ]
        )
    );
  }
}
