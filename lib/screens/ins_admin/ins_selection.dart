import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/screens/auth_screens/login_screen.dart';
import 'package:smas3/screens/ins_admin/add_institute.dart';
import 'package:smas3/screens/ins_admin/ins_admin_dashboard.dart';
import 'package:smas3/screens/ins_admin/update_ins.dart';

import '../../services/db_service.dart';

class InsSelection extends StatefulWidget {
  final InsAdmin insAdmin;
  const InsSelection({super.key, required this.insAdmin});

  @override
  State<InsSelection> createState() => _InsSelectionState();
}

class _InsSelectionState extends State<InsSelection> {
  List<Institute> institutes_list=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("My Institutes",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 22),),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("ins_admins").doc(widget.insAdmin.id).collection("institutes").snapshots(),
          builder: (context,snapshot){
            if(snapshot.connectionState==ConnectionState.waiting){
             return Center(child:
             SizedBox(
                 width:150,height: 150,
                 child: Lottie.asset("assets/anims/m2.json")),);
            }else if(snapshot.hasError){
              return Center(child: Text("snapshot error"),);
            }else if(!snapshot.hasData){
              return Center(child: Text("no data"),);
            }else{
              institutes_list.clear();
              if(snapshot.data!.docs.isEmpty){
                return Center(child: Text("no data , plz add institute first"),);
              }else{
                for(var ins in snapshot.data!.docs){
                  institutes_list.add(
                    Institute(
                        id: ins.id,
                        insAdminId: widget.insAdmin.id,
                        name: ins['name'],
                        address: ins['address'],
                        contact: ins['contact'],
                        logo: ins['logo'],
                        created_at: ins['created_at'].toDate(),
                        location: ins['location']
                    )
                  );
                }
                return !snapshot.hasData?Center(child: Text("no data,"),):
                ListView.builder(
                  itemCount: institutes_list.length,
                  itemBuilder: (BuildContext context, int index) {
                    return FutureBuilder<InstituteStats>(
                      future: getStats(institutes_list[index].id!),
                      builder: (context, statsSnapshot) {

                        if (!statsSnapshot.hasData) {
                          return
                            Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: SizedBox(
                                    height: 60,
                                    width: 60,
                                    child: Lottie.asset("assets/anims/an1.json")),
                              ),
                            ),
                          );
                        }

                        final stats = statsSnapshot.data!;

                        return InstituteCard(
                          insAdmin: widget.insAdmin,
                          institute: institutes_list[index],
                          students: stats.students,
                          faculty: stats.faculty,
                          admins: stats.admins,
                          departments: stats.departments,
                        );
                      },
                    );


                  },

                );
              }
            }
      }),
      floatingActionButton: FloatingActionButton(onPressed: (){
        // Provider.of<DbService>(context,listen: false).signOut(context);
        // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>LoginScreen()), (i)=>false);
        Navigator.push(context, MaterialPageRoute(builder: (_)=>AddInstitute(insAdmin: widget.insAdmin,)));
      },backgroundColor: Colors.white60,child: Icon(Icons.add_business_rounded,color: Theme.of(context).primaryColor,),),
    );
  }

  Future<InstituteStats> getStats(String instituteId) async {

    final studentsFuture = FirebaseFirestore.instance
        .collection("SAMS")
        .doc("SAMS_DB")
        .collection("index")
        .where("institute_id", isEqualTo: instituteId)
        .where("role", isEqualTo: "student")
        .count()
        .get();


    final facultyFuture = FirebaseFirestore.instance
        .collection("SAMS") .doc("SAMS_DB")
        .collection("index")
        .where("institute_id", isEqualTo: instituteId)
        .where("role", isEqualTo: "faculty")
        .count()
        .get();

    final adminsFuture = FirebaseFirestore.instance
        .collection("SAMS")
        .doc("SAMS_DB").collection("ins_admins").doc(widget.insAdmin.id)
        .collection("institutes")
        .doc(instituteId)
        .collection("admins")
        .count()
        .get();

    final departmentsFuture = FirebaseFirestore.instance
        .collection("SAMS")
        .doc("SAMS_DB").collection("ins_admins").doc(widget.insAdmin.id)
        .collection("institutes")
        .doc(instituteId)
        .collection("departments")
        .count()
        .get();

    final results = await Future.wait([
      studentsFuture,
      facultyFuture,
      adminsFuture,
      departmentsFuture,
    ]);
    print(results[2].count);
    return InstituteStats(
      students: results[0].count ?? 0,
      faculty: results[1].count ?? 0,
      admins: results[2].count ?? 0,
      departments: results[3].count ?? 0,
    );
  }
}

class InstituteCard extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final int students;
  final int faculty;
  final int admins;
  final int departments;

  const InstituteCard({
    super.key,
    required this.institute,
    required this.students,
    required this.faculty,
    required this.admins,
    required this.departments, required this.insAdmin,
  });

  @override
  State<InstituteCard> createState() => _InstituteCardState();
}

class _InstituteCardState extends State<InstituteCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onDoubleTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>Update_Institute(insAdmin: widget.insAdmin, institute: widget.institute)));
      },
      child: Card(
        color: Colors.white,
        elevation: 4,
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(1),
                    // fontawseome icon
                    child: FaIcon(FontAwesomeIcons.buildingColumns,size: 28,color: Colors.white,)
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.institute.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "ID: ${widget.institute.id}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: (){
                    showDialog(context: context, builder: (_)=>AlertDialog(
                      title: Text("Delete institute"),
                      content: Text("Are you sure you want to delete this institute?"),
                     actions: [
                       TextButton(onPressed: (){
                         Navigator.pop(context);
                       }, child: Text("No")),
                       TextButton(onPressed: (){
                         Provider.of<DbService>(context,listen: false).removeInstitute(context, widget.institute.id!);
                         Navigator.pop(context);
                       }, child: Text("Yes")),
                     ],
                    ));

                  }, icon: Icon(CupertinoIcons.delete,color: Theme.of(context).primaryColor,))
                ],
              ),

              const SizedBox(height: 16),

              /// address.
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.institute.address),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// contacthere
              Row(
                children: [
                  const Icon(Icons.phone_outlined),
                  const SizedBox(width: 8),
                  Text(widget.institute.contact.toString()),
                ],
              ),

              const SizedBox(height: 16),

              Divider(color: Colors.grey.shade300),

              const SizedBox(height: 12),

              /// otherstats
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  _stat(
                    Icons.school,
                    widget.students.toString(),
                    "Students",
                  ),
                  _stat(
                    Icons.person,
                    widget.faculty.toString(),
                    "Faculty",
                  ),
                  _stat(
                    Icons.admin_panel_settings,
                    widget.admins.toString(),
                    "Admins",
                  ),
                  _stat(
                    Icons.apartment,
                    widget.departments.toString(),
                    "Departments",
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// footerHere
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Created on :${DateFormat('dd MMM yyyy').format(widget.institute.created_at)}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  FilledButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>
                          InsAdminDashboard(insAdmin: widget.insAdmin,institute: widget.institute,)), (t)=>false);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Open"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(
      IconData icon,
      String value,
      String label,
      ) {
    return Column(
      children: [
        Icon(icon,),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
class InstituteStats {
  final int students;
  final int faculty;
  final int admins;
  final int departments;

  InstituteStats({
    required this.students,
    required this.faculty,
    required this.admins,
    required this.departments,
  });
}