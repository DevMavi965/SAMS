import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/screens/faculty/fac_home.dart';
import 'package:smas3/screens/faculty/course_tab.dart';
import 'package:smas3/screens/faculty/fac_mark_attendance.dart';
import 'package:smas3/screens/faculty/fac_profile_tab.dart';
import 'package:smas3/screens/faculty/fac_reports_tab.dart';

import '../../models/course.dart';
import '../../services/db_service.dart';
class FacDeshboard extends StatefulWidget {
  final Lecturer lecturer;
   FacDeshboard({super.key, required this.lecturer});

  @override
  State<FacDeshboard> createState() => _FacDeshboardState();
}

class _FacDeshboardState extends State<FacDeshboard> {
  int current=3;
 InsAdmin? insAdmin;
 Institute? institute;
 Department? department;
 bool isLoading=false;
 getInsAdminInsDep() async {
   try{
     setState(() {
       isLoading=true;
     });
     final insAdmindoc=await Provider.of<DbService>(context,listen: false).dbref
         .collection("ins_admins")
         .doc(widget.lecturer.insAdminId).get();
         insAdmin=InsAdmin(
           id: insAdmindoc.id,
             role:insAdmindoc['role'],
             name:insAdmindoc['name'],
             email:insAdmindoc['email'],
             status:insAdmindoc['status'],
           last_login:insAdmindoc['last_login'].toDate(),
           created_at:insAdmindoc['created_at'].toDate(),
         );
         final instituteDoc=await Provider.of<DbService>(context,listen: false).dbref
             .collection("ins_admins")
             .doc(widget.lecturer.insAdminId)
             .collection("institutes")
             .doc(widget.lecturer.instituteId).get();
         institute=Institute(
           id: instituteDoc.id,
             name: instituteDoc['name'],
             address: instituteDoc['address'],
             contact: instituteDoc['contact'],
             created_at: instituteDoc['created_at'].toDate(),
             location: instituteDoc['location'],
             insAdminId: widget.lecturer.insAdminId,
             logo: instituteDoc['logo'],
         );
     final depDoc=await Provider.of<DbService>(context,listen: false).dbref
         .collection("ins_admins")
         .doc(widget.lecturer.insAdminId)
         .collection("institutes").doc(widget.lecturer.instituteId)
         .collection("departments")
         .doc(widget.lecturer.departmentId).get();
     department=Department(
         id: depDoc.id,
         name: depDoc['name'],
         hod_name: depDoc['hod_name'],
       created_at: depDoc['created_at'].toDate(),
     );
   }catch(e){
     print(e.toString());
   }finally{
     setState(() {
       isLoading=false;
     });
   }
 }
  List<String> menus=[
    "Home",
    "Mark",
    "courses",
    "Reports",
    "Profile"
  ];
  late List<Widget> screens=[
    FacHomeTab(insAdmin: insAdmin!,institute: institute!,department: department!,lecturer: widget.lecturer,),
    FacMarkAttendanceTab(insAdmin: insAdmin!, institute: institute!, lecturer: widget.lecturer,),
    CourseTab(insAdmin:insAdmin!,institute: institute!,department: department!,lecturer: widget.lecturer,),
    FacReportsTab(),
    FacProfileTab(lecturer: widget.lecturer, insAdmin: insAdmin!, institute: institute!, department: department!,)
  ];
  @override
  void initState() {
    getInsAdminInsDep();
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:isLoading?Center(child: CircularProgressIndicator(),): Container(
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
            backgroundColor: Colors.white,
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
