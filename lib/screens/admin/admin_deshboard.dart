import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/screens/admin/admin_announ.dart';
import 'package:smas3/screens/admin/admin_home.dart';
import 'package:smas3/screens/admin/admin_profile.dart';
import 'package:smas3/screens/admin/admin_reports.dart';

import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../services/db_service.dart';
class AdminDeshboard extends StatefulWidget {
  final Admin admin;
  const AdminDeshboard({super.key, required this.admin});

  @override
  State<AdminDeshboard> createState() => _AdminDeshboardState();
}

class _AdminDeshboardState extends State<AdminDeshboard> {
  int current=0;

  List<String> menus=[
    "Dashboard",
    "Reports",
    "Announcements",
    "Profile"
  ];
  late List<Widget> screens=[
   AdminHome(insAdmin:insAdmin!,institute:institute!,admin: widget.admin,),
    AdminReports(),
    AdminAnnouncements(insAdmin:insAdmin!,institute: institute!,),
    AdminProfile(admin: widget.admin,)

  ];
  bool loading=false;
  InsAdmin? insAdmin;
  Institute? institute;
  getR() async{
    setState(() {
      loading=true;
    });
    try{
      final doc=await Provider.of<DbService>(context,listen: false).dbref.collection("ins_admins").doc(widget.admin.insAdminId).get();
      insAdmin=InsAdmin(
        id: doc.id,
        role: doc["role"],
        name: doc["name"],
        email: doc["email"],
        status: doc["status"],
        created_at: doc["created_at"].toDate(),
        last_login: doc["last_login"].toDate(),
      );
      final ins=await Provider.of<DbService>(context,listen: false).dbref.collection("ins_admins").doc(widget.admin.insAdminId)
          .collection("institutes").doc(widget.admin.instituteId).get();
      institute=Institute(
          id: ins.id,
          insAdminId: widget.admin.insAdminId,
          name: ins['name'],
          address: ins['address'],
          contact: ins['contact'],
          logo: ins['logo'],
          created_at: ins['created_at'].toDate(),
          location: ins['location']
      );
    }catch(e){
      print(e);
    }finally{
      setState(() {
        loading=false;
      });
    }
  }
  @override
  initState(){
    getR();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body:loading?Center(child: SizedBox(
          height: 60,
          width: 60,
          child: Lottie.asset("assets/anims/an1.json")),): Container(
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
                  (i==3?Icon(PhosphorIconsBold.gear):
                  (i==2?Icon(PhosphorIconsBold.megaphone):
                  (i==0? Icon(Icons.dashboard_outlined):Icon(PhosphorIconsBold.chartBar)))),
                  label: menus[i],

                ),
            ]
        )
    );
  }
}
