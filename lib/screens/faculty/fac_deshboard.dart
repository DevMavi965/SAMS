import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/Lecture_model.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/screens/faculty/fac_home.dart';
import 'package:smas3/screens/faculty/fac_leave_tab.dart';
import 'package:smas3/screens/faculty/fac_mark_attendance.dart';
import 'package:smas3/screens/faculty/fac_profile_tab.dart';
import 'package:smas3/screens/faculty/fac_reports_tab.dart';
class FacDeshboard extends StatefulWidget {
   FacDeshboard({super.key});

  @override
  State<FacDeshboard> createState() => _FacDeshboardState();
}

class _FacDeshboardState extends State<FacDeshboard> {
  int current=0;
  Lecturer lecturer=
  Lecturer(E_id: "DS13A2", name: "Maliha Shaik", deprt:"Computer Science", designation: "Prof",
      status: "active", email:"profmshaik@gmail.com", phone: "+923456785321",
      courses: [
    Course(name: "Data Science", lecturer: "Maliha Shaik", room: "13A", time: DateTime.now(), status: "active"),
        Course(name: "ML", lecturer: "Maliha Shaik", room: "13C", time: DateTime.now(), status: "active"),
        Course(name: "DSA", lecturer: "Maliha Shaik", room: "Lab1", time: DateTime.now(), status: "active")
  ]);
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
