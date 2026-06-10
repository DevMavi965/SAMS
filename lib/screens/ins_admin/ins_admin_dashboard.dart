import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/student_model.dart';

import '../../services/db_service.dart';

class InsAdminDashboard extends StatefulWidget {
  final InsAdmin insAdmin;
  const InsAdminDashboard({super.key, required this.insAdmin});

  @override
  State<InsAdminDashboard> createState() => _InsAdminDashboardState();
}

class _InsAdminDashboardState extends State<InsAdminDashboard> {
  int current=0;
  List<String> menus=[
    "Dashboard",
    "Manage",
    "Reports",
    "Announcements",
    "Profile"
  ];
  logout()async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.insAdmin.name}'s ${menus[current]}"),
        // centerTitle: true,
        actions: [
          IconButton(onPressed: (){
          setState(() {
           logout();
          });
          }, icon: Icon(Icons.logout))
        ],
      ),
      body:
      Builder(builder: (context){
        final dbref=Provider.of<DbService>(context).dbref;
        return StreamBuilder(stream: dbref.collection("ins_admins").doc(widget.insAdmin.id).collection("institutes").snapshots(), builder: (context,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(child: CircularProgressIndicator(),);
          }else if(snapshot.hasData)
          {
            List<Institute> Institute_list=snapshot.data!.docs.map((ins) => Institute(
                id: ins.id,
                insAdminId: widget.insAdmin.id,
                name: ins["name"],
                address: ins['address'],
                contact: ins['contact'],
                logo: ins['logo'],
                created_at: ins['created_at'].toDate(),
                location: ins['location']
            )).toList();
            return ListView(
              children: [
                for(var institute in Institute_list)
                  ListTile(
                    title: Text(institute.name),
                    subtitle: Text(institute.address),
                    trailing: IconButton(onPressed: (){
                      Provider.of<DbService>(context,listen: false).registerStudent(
                          widget.insAdmin.id!, institute.id!,
                          Student(
                              role: "student",
                              name: "maria",
                              insAdminId: widget.insAdmin.id!,
                              instituteId: institute.id!,
                              depart: "Computer Science",
                              semester: 4,
                              email: "maria13@gmail.com",
                              created_at: DateTime.now()
                          ),
                           "12312344", context);
                      // Provider.of<DbService>(context,listen: false).registerFac(widget.insAdmin.id!, institute.id!,
                      //     Lecturer(
                      //         name: "Ameer Muawiya",
                      //         deprt: "Business Analytics",
                      //         role: "faculty",
                      //         instituteId: institute.id!,
                      //         insAdminId: widget.insAdmin.id!,
                      //         designation: "Professor",
                      //         status: "active",
                      //         courses: ["Data Mining","Artificial Intelligence"],
                      //         semesters: [1,2,5,6,8],
                      //         email: "am1234@gmail.com",
                      //         phone: "0345231345")
                      //     , "12345678", context);
                      // Provider.of<DbService>(context,listen: false).registerAdmin(widget.insAdmin.id!, institute.id!,
                      //     Admin(name: "Ali Zachary",
                      //         insAdminId: widget.insAdmin.id!,
                      //         instituteId: institute.id!,
                      //         email: "ali67@gmail.com",
                      //         institute: institute.name,
                      //         role: "admin",
                      //         permissions: ["student_management","faculty_management","course_management"],
                      //         status: "active"),
                      //
                      //     "12341234", context);
                      // addStudent(context, widget.insAdmin.id!, institute.id!,
                      // Student(role: "student", name: "maria", insAdminId: widget.insAdmin.id!,
                      //     instituteId: institute.id!, depart: "Computer Science", semester: 4, email: "maria")
                      // );
                      // successfully tested
                      // Provider.of<DbService>(context,listen: false).
                      // removeInstitute(context,widget.insAdmin.id!,institute.id!);
                    }, icon: Icon(Icons.person_add)),
                  )
              ],
            );
          }else{
            return Center(child: Text("no data"),);
          }
        });
      }),
      floatingActionButton: FloatingActionButton(onPressed: (){
        Provider.of<DbService>(context,listen: false).
        // Provider.of<DbService>(context,listen: false).getData1(widget.insAdmin.id!);
        addInstitute(
          context,
          widget.insAdmin.id!,
          Institute(
              name: "APS-Korangi",
              address: "korangi",
              contact: 09252065743,
              logo: "png",
              insAdminId: widget.insAdmin.id!,
              created_at: DateTime.now(),
              location: {"lat":21.67,"long":7.0011})
        );
      },child: Icon(Icons.add),),
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
