import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/screens/management/Ann_manage.dart';
import 'package:smas3/screens/management/Course_manage.dart';
import 'package:smas3/screens/management/Leave_manage.dart';
import 'package:smas3/screens/management/Session_manage.dart';
import 'package:smas3/screens/management/TimeTable_mng.dart';
import 'package:smas3/screens/management/depart_manage.dart';
import 'package:smas3/screens/management/fac_manage.dart';
import 'package:smas3/screens/management/std_manage.dart';

import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../widgets/insAdmin/IsAdminGrid.dart';

class InsAdminHome extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const InsAdminHome({super.key, required this.insAdmin, required this.institute});

  @override
  State<InsAdminHome> createState() => _InsAdminHomeState();
}

class _InsAdminHomeState extends State<InsAdminHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ListView(
        children: [
          Text("Welcome ${widget.insAdmin.name}!",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
          SizedBox(height: 7,),
          Text("System Overview & Management",style: TextStyle(fontSize: 15,color: Colors.grey),),
          SizedBox(height: 20,),
          InsAdminGrid1(students: 500, noOfFaculty: 210, noOfDeparts: 6, avg_attendance: 89, noOfAdmins: 3,),
          SizedBox(height: 20,),
          Text("Manage Institute",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600,color: Colors.grey)),
          SizedBox(height: 10,),
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
              Navigator.push(context, MaterialPageRoute(builder: (_)=>FacManage(insAdmin: widget.insAdmin, institute: widget.institute,)));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
                         Text("23 members",style: TextStyle(color: Colors.grey),)
                       ],)
                     ],
                   ),
                 ),
              ),
            ),
            // manage students
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>StdManage()));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
                        Text("500 enrolled",style: TextStyle(color: Colors.grey),)
                      ],)
                    ],
                  ),
                ),
              ),
            ),
            // Department Management
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>DepartManage()));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
                        Text("4 departments",style: TextStyle(color: Colors.grey),)
                      ],)
                    ],
                  ),
                ),
              ),
            ),
            // sessions
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>SessionManage()));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
                        Text("managing batches",style: TextStyle(color: Colors.grey),)
                      ],)
                    ],
                  ),
                ),
              ),
            ),
            //courses
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>CourseManage()));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
              ),
            ),
            //timetable
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>TimetableMng()));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
              ),
            ),
            // leave applications
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>LeaveManage()));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
              ),
            ),
            //announcements
            InkWell(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=>AnnManage()));
              },
              child: SizedBox(

                // height: MediaQuery.of(context).size.height*0.15,
                child: Container(
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
              ),
            ),

          ],
          )
        ],
      ))
    );
  }
}
