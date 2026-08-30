import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/widgets/student_widgets/personal_info.dart';
import 'package:smas3/widgets/student_widgets/std_profile_card.dart';
import 'package:smas3/widgets/student_widgets/std_settings.dart';

import '../../services/db_service.dart';
class ProfileTab extends StatefulWidget {
  final Student student;
  const ProfileTab({super.key, required this.student});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
        ),
        child: ListView(
          children: [
            Column(
             mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Profile",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),

                Text("Manage your account settings",style: TextStyle(fontSize: 15,color: Colors.grey),),
                SizedBox(height: 20,),
                StdProfileCard(student: widget.student),
                SizedBox(height: 25,),
                Text("Personal Information",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                SizedBox(height: 10,),
                PersonalInfo(student: widget.student),
                SizedBox(height: 25,),
                Text("Settings",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                SizedBox(height: 10,),
                StdSettings(student: widget.student),
                SizedBox(height: 25,),






















                // SingleChildScrollView(
                //   scrollDirection: Axis.vertical,
                //   child:
                  // Table(
                  //   border: TableBorder.all(
                  //     color: Colors.grey,
                  //     width: 0.2,
                  //   ),
                  //  children: [
                  //    TableRow(
                  //      children: [
                  //        Text("Course Name"),
                  //        Text("Lecturer"),
                  //        Text("Room"),
                  //        Text("Time"),
                  //      ]
                  //    ),
                  //    for(int i=0;i<courses.length;i++)
                  //      TableRow(
                  //        children: [
                  //          Text(courses[i].name),
                  //          Text(courses[i].lecturer),
                  //          Text(courses[i].room),
                  //          Text(courses[i].time),
                  //        ]
                  //      )
                  //  ],
                  // ),
                // )
              ],
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                iconColor: Colors.red,
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red,width: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              onPressed: (){
                showDialog(context: context, builder: (_)=>
                    AlertDialog(
                      icon: Icon(Icons.logout,size: 28,color: Theme.of(context).primaryColor,),
                      title: Text("Are you sure you want to logout?",style: TextStyle(fontSize: 16),),
                      actions: [
                        Row(
                          children: [
                            ElevatedButton(onPressed: (){
                              Navigator.pop(context);
                            },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white60,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),

                                  ),),
                                child: Text("Cancel",style: TextStyle(color: Colors.black),)),
                            Spacer(),
                            ElevatedButton(onPressed: (){
                              Provider.of<DbService>(context,listen: false).signOut(context);
                              Navigator.pop(context);
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                    side: BorderSide(color: Colors.red,width: 0.5),
                                  ),),
                                child: Text("Logout",style: TextStyle(color: Colors.white),)),
                          ],
                        ),

                      ],
                    )
                );
              },
              label: Text("Logout"),
              icon: Icon(Icons.logout),
            ),
            SizedBox(height: 35,),
          ],
        ),
      ),
    );
  }
}
