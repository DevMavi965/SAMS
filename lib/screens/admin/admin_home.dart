import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/deprt_alert.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/db_service.dart';
import 'package:smas3/widgets/admin_widgets/Admin_home_grid.dart';
import 'package:smas3/widgets/admin_widgets/admin_custom_lineCart.dart';
import 'package:smas3/widgets/admin_widgets/depart_att_card.dart';
import 'package:smas3/widgets/admin_widgets/deprt_aler_card.dart';

import '../ins_admin/Depart_select.dart';
import '../management/Ann_manage.dart';
import '../management/Course_manage.dart';
import '../management/Leave_manage.dart';
import '../management/Session_manage.dart';
import '../management/TimeTable_mng.dart';
import '../management/depart_manage.dart';
import '../management/std_manage.dart';

class AdminHome extends StatefulWidget {
  final Admin admin;
  const AdminHome({super.key, required this.admin});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {

  InsAdmin? insAdmin;
  Institute? institute;
  getR() async{
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
    }
  }
  List<String> duties=[
    "Timetable",
    "Announcements",
    "Leave_management",
    "student_management",
    "faculty_management",
    "department_management",//includes adding/removing departments & sessions & semesters
    "course_management",
    "session_management",
  ];
  List<DepartmentalAlerts> dept_alerts=[
    DepartmentalAlerts(id: "4ft5", content: "Cs depart has 4 new students", type: "positive", created_at: DateTime(2026,4,13)),
    DepartmentalAlerts(id: "32d4", content: "14 students have below 75% attendance", type: "negative", created_at: DateTime(2026,3,21)),
    DepartmentalAlerts(id: "654a", content: "New faculty onboarding pending", type: "neutral", created_at: DateTime(2026,4,7)),


  ];
  @override
  void initState() {
    getR();
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(children: [
      Text("Welcome ${widget.admin.name}!",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
      SizedBox(height: 7,),
      Text("System Overview & Management",style: TextStyle(fontSize: 15,color: Colors.grey),),
      SizedBox(height: 20,),
      AdminHomeGrid(total: 500, noOfFaculty: 210, noOfDeparts: 6, avg_attendance: 89),
      SizedBox(height: 20,),
      Row(children: [Text("You have following ${widget.admin.permissions!.length} duties:",style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16,color: Colors.black87),)],),
      SizedBox(height: 15,),
      // duties
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        shrinkWrap: true,
        childAspectRatio: 1.4,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // manage faculty
          InkWell(
            onTap: (){
              if(widget.admin.permissions!.contains("faculty_management")){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>DepartSelect(insAdmin: insAdmin!, institute: institute!,)));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage faculty"),backgroundColor: Theme.of(context).primaryColor,));
              }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color:Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(Icons.school,size: 27,color: Colors.blue,))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("Manage Faculty",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("faculty operations",style: TextStyle(color: Colors.grey),)
                        ],)
                      ],
                    ),
                  ),
                 widget.admin.permissions!.contains("faculty_management")?SizedBox()
                     : Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.6),))
                ],
              ),
            ),
          ),
          // manage students
          InkWell(
            onTap: (){
              if(widget.admin.permissions!.contains("student_management")){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>Std_manage(insAdmin: insAdmin!, institute: institute!)));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage students"),backgroundColor: Theme.of(context).primaryColor,));
              }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Color(0xffB45253).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(Icons.people_alt,size: 27,color:Color(0xffB45253)))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("Manage Students",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("students operations",style: TextStyle(color: Colors.grey),)
                        ],)
                      ],
                    ),
                  ),
                 widget.admin.permissions!.contains("student_management")?SizedBox(): Positioned(
                     right: 10,
                     top: 10,
                     child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.7),))
                ],
              ),
            ),
          ),
          // Department Management
          InkWell(
            onTap: (){
            if(widget.admin.permissions!.contains("department_management")){
              Navigator.push(context, MaterialPageRoute(builder: (_)=>DepartManage(insAdmin:insAdmin!, institute: institute!,)));
            }else{
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage departments"),backgroundColor: Theme.of(context).primaryColor,));
            }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color:Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(CupertinoIcons.building_2_fill,size: 27,color: Colors.purple,))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("Departments",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("departmental operations",style: TextStyle(color: Colors.grey),)
                        ],)
                      ],
                    ),
                  ),
                  widget.admin.permissions!.contains("Department_management")?SizedBox():  Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.7),))
                ],
              ),
            ),
          ),
          // sessions
          InkWell(
            onTap: (){
            if(widget.admin.permissions!.contains("session_management")){
              Navigator.push(context, MaterialPageRoute(builder: (_)=>SessionManage(insAdmin:insAdmin!, institute: institute!,)));
            }else{
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage sessions"),backgroundColor: Theme.of(context).primaryColor,));
            }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(Icons.calendar_today_outlined,size: 27,color: Colors.green,))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("Sessions",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Flexible(child: Text("batches & semester",style: TextStyle(color: Colors.grey),))
                        ],)
                      ],
                    ),
                  ),
                  widget.admin.permissions!.contains("session_management")?SizedBox():  Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.7),))
                ],
              ),
            ),
          ),
          //courses
          InkWell(
            onTap: (){
              if(widget.admin.permissions!.contains("course_management")){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>CourseManage(insAdmin:insAdmin!,institute: institute!,)));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage courses"),backgroundColor: Theme.of(context).primaryColor,));
              }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color:Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(PhosphorIconsFill.book,size: 27,color: Colors.deepPurple,))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("Courses",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("per semester",style: TextStyle(color: Colors.grey),)
                        ],)
                      ],
                    ),
                  ),
                  widget.admin.permissions!.contains("course_management")?SizedBox(): Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.7),))
                ],
              ),
            ),
          ),
          //timetable
          InkWell(
            onTap: (){
              if(widget.admin.permissions!.contains("Timetable")){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>TimetableMng()));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage timetables"),backgroundColor: Theme.of(context).primaryColor,));
              }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Color(0xff36ADA3).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(CupertinoIcons.clock,size: 27,color: Color(0xff36ADA3),))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("TimeTable",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("schedule lectures",style: TextStyle(color: Colors.grey),)
                        ],)
                      ],
                    ),
                  ),
                  widget.admin.permissions!.contains("Timetable")?SizedBox(): Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.7),))
                ],
              ),
            ),
          ),
          // leave applications
          InkWell(
            onTap: (){
              if(widget.admin.permissions!.contains("Leave_management")){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>Leave_manage_r(insAdmin: insAdmin!, institute: institute!,)));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage leave applications"),backgroundColor: Theme.of(context).primaryColor,));
              }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(PhosphorIconsBold.notepad,size: 27,color: Colors.red,))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("Leave Applications",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("pending leave requests",style: TextStyle(color: Colors.grey),)
                        ],)
                      ],
                    ),
                  ),
                  widget.admin.permissions!.contains("Leave_management")?SizedBox(): Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.7),))
                ],
              ),
            ),
          ),
          //announcements
          InkWell(
            onTap: (){
              if(widget.admin.permissions!.contains("Announcements")){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>AnnManage(institute:institute!,insAdmin: insAdmin!,)));
              }else{
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You don't have permission to manage announcements"),backgroundColor: Theme.of(context).primaryColor,));
              }
            },
            child: SizedBox(

              // height: MediaQuery.of(context).size.height*0.15,
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        left: 20,
                        top: 15
                    ),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ]

                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Color(0xFF39B1D1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)
                                ),
                                child: Icon(PhosphorIconsBold.megaphone,size: 27,color:Color(0xFF39B1D1),))
                          ],
                        ),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("Announcements",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
                        ],),
                        SizedBox(height: 5,),
                        Row(children: [
                          Text("schedule lectures",style: TextStyle(color: Colors.grey),)
                        ],)
                      ],
                    ),
                  ),
                  widget.admin.permissions!.contains("Announcements")?SizedBox(): Positioned(
                      right: 10,
                      top: 10,
                      child: Icon(CupertinoIcons.lock_circle_fill,size: 50,color: Theme.of(context).primaryColor.withOpacity(0.7),))
                ],
              ),
            ),
          ),

        ],
      ),
      SizedBox(height: 15,),
      Row(children: [Text("Recent Alerts",style: TextStyle(fontWeight: FontWeight.w400,fontSize: 16),)],),
      SizedBox(height: 15,),
      for(int i=0;i<dept_alerts.length;i++)
        DeprtAlerCard(dept_alert: dept_alerts[i])
    ],));
  }

  static String getFirstLetters(String input) {
    if (input.isEmpty) return '';

    List<String> words = input.split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    // If only one word_deprtm name, return first 2letters
    if (words.length == 1) {
      String singleWord = words[0];
      if (singleWord.length == 1) return singleWord.toUpperCase();
      return singleWord.substring(0, 2).toUpperCase();
    }

    // Multiple words: return first letter of each word
    return words.map((word) => word[0]).join().toUpperCase();
  }
}
