import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/ins_admin/ins_admin_home.dart';
import 'package:smas3/screens/ins_admin/ins_admin_profile.dart';
import 'package:smas3/screens/ins_admin/ins_reports.dart';
import 'package:smas3/screens/ins_admin/manage_s.dart';

import '../../services/db_service.dart';

class InsAdminDashboard extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const InsAdminDashboard({super.key, required this.insAdmin, required this.institute});

  @override
  State<InsAdminDashboard> createState() => _InsAdminDashboardState();
}

class _InsAdminDashboardState extends State<InsAdminDashboard> {
  int current=1;
  List<String> menus=[
    "Dashboard",
    "Manage",
    "Reports",
    "Profile"
  ];
  late List<Widget> screens=[
    InsAdminHome(),
    ManageAdmins(insAdmin: widget.insAdmin,institute:widget.institute ,),
    InsReports(),
    insAdminProfile(insAdmin: widget.insAdmin,)
  ];
  logout()async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(padding: EdgeInsets.symmetric(
          horizontal: 15,vertical: 7
      ),child: screens[current],
      ),
      // Builder(builder: (context){
      //   final dbref=Provider.of<DbService>(context).dbref;
      //   return StreamBuilder(stream: dbref.collection("ins_admins").doc(widget.insAdmin.id).collection("institutes").snapshots(), builder: (context,snapshot){
      //     if(snapshot.connectionState==ConnectionState.waiting){
      //       return SizedBox();
      //       //   Center(child:
      //       // SizedBox(
      //       //     width:150,height: 150,
      //       //     child: Lottie.asset("assets/anims/m2.json")),);
      //     }else if(snapshot.hasData)
      //     {
      //       List<Institute> Institute_list=snapshot.data!.docs.map((ins) => Institute(
      //           id: ins.id,
      //           insAdminId: widget.insAdmin.id,
      //           name: ins["name"],
      //           address: ins['address'],
      //           contact: ins['contact'],
      //           logo: ins['logo'],
      //           created_at: ins['created_at'].toDate(),
      //           location: ins['location']
      //       )).toList();
      //       return Institute_list.isEmpty?Center(child: Text("no data"),): ListView(
      //         children: [
      //           for(var institute in Institute_list)
      //             ListTile(
      //               title: Text(institute.name),
      //               subtitle: Text(institute.address),
      //               trailing: IconButton(onPressed: (){
      //
      //
      //                 Provider.of<DbService>(context,listen: false).registerStudent(
      //                     widget.insAdmin.id!, institute.id!,
      //                     Student(
      //                         role: "student",
      //                         name: "maria",
      //                         insAdminId: widget.insAdmin.id!,
      //                         instituteId: institute.id!,
      //                         depart: "Computer Science",
      //                         semester: 4,
      //                         email: "wares2064@gmail.com",
      //                         created_at: DateTime.now()
      //                     ),
      //                      "12312344", context);
      //
      //
      //                 // Provider.of<DbService>(context,listen: false).registerFac(widget.insAdmin.id!, institute.id!,
      //                 //     Lecturer(
      //                 //         name: "Ameer Muawiya",
      //                 //         deprt: "Business Analytics",
      //                 //         role: "faculty",
      //                 //         instituteId: institute.id!,
      //                 //         insAdminId: widget.insAdmin.id!,
      //                 //         designation: "Professor",
      //                 //         status: "active",
      //                 //         courses: ["Data Mining","Artificial Intelligence"],
      //                 //         semesters: [1,2,5,6,8],
      //                 //         email: "am1234@gmail.com",
      //                 //         phone: "0345231345")
      //                 //     , "12345678", context);
      //
      //
      //                 // Provider.of<DbService>(context,listen: false).registerAdmin(widget.insAdmin.id!, institute.id!,
      //                 //     Admin(name: "Ali Zachary",
      //                 //         insAdminId: widget.insAdmin.id!,
      //                 //         instituteId: institute.id!,
      //                 //         email: "ali67@gmail.com",
      //                 //         institute: institute.name,
      //                 //         role: "admin",
      //                 //         permissions: ["student_management","faculty_management","course_management"],
      //                 //         status: "active"),
      //                 //
      //                 //     "12341234", context);
      //
      //
      //
      //                 // addStudent(context, widget.insAdmin.id!, institute.id!,
      //                 // Student(role: "student", name: "maria", insAdminId: widget.insAdmin.id!,
      //                 //     instituteId: institute.id!, depart: "Computer Science", semester: 4, email: "maria")
      //                 // );
      //                 // successfully tested
      //                 // Provider.of<DbService>(context,listen: false).removeInstitute(context, institute.id!);
      //               }, icon: Icon(Icons.person_add)),
      //             )
      //         ],
      //       );
      //     }else{
      //       return Center(child: Text("no data,plz add institute first"),);
      //     }
      //   });
      // }),
      // floatingActionButton: FloatingActionButton(onPressed: (){
      //   Provider.of<DbService>(context,listen: false).
      //   // Provider.of<DbService>(context,listen: false).getData1(widget.insAdmin.id!);
      //   addInstitute(
      //     context,
      //     widget.insAdmin.id!,
      //     Institute(
      //         name: "APS-Burki",
      //         address: "burki",
      //         contact: 09252065743,
      //         logo: "png",
      //         insAdminId: widget.insAdmin.id!,
      //         created_at: DateTime.now(),
      //         location: {"lat":21.67,"long":7.0011})
      //   );
      // },child: Icon(Icons.add),),
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
                    icon: Icon(i==0?Icons.home:(i==1?Icons.manage_accounts:(i==2?Icons.bar_chart:Icons.person))),
                  // icon:
                  // (i==3?Icon(PhosphorIconsBold.megaphone):
                  // (i==2?Icon(PhosphorIconsBold.chartBar):
                  // (i==0? Icon(Icons.dashboard_outlined):Icon(Icons.people_alt_outlined))),
                  label: menus[i],

                ),
            ]
        )
    );
  }
}
