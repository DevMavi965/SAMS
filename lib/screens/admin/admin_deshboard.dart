import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/screens/admin/admin_announ.dart';
import 'package:smas3/screens/admin/admin_home.dart';
import 'package:smas3/screens/admin/admin_profile.dart';
import 'package:smas3/screens/admin/admin_reports.dart';
import 'package:smas3/screens/admin/user_mng.dart';

class AdminDeshboard extends StatefulWidget {
  final Admin admin;
  const AdminDeshboard({super.key, required this.admin});

  @override
  State<AdminDeshboard> createState() => _AdminDeshboardState();
}

class _AdminDeshboardState extends State<AdminDeshboard> {
  int current=3;

  List<String> menus=[
    "Dashboard",
    "Users",
    "Reports",
    "Announcements",
    "Profile"
  ];
  late List<Widget> screens=[
   AdminHome(),
    UserMng(),
    AdminReports(),
    AdminAnnouncements(),
    AdminProfile(admin: widget.admin,)

  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
          margin:EdgeInsets.symmetric(horizontal: 15,vertical: 7),
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
                  i==4?Icon(PhosphorIconsBold.gear):
                  (i==3?Icon(PhosphorIconsBold.megaphone):
                  (i==2?Icon(PhosphorIconsBold.chartBar):
                  (i==0? Icon(Icons.dashboard_outlined):Icon(Icons.people_alt_outlined)))),
                  label: menus[i],

                ),
            ]
        )
    );
  }
}
