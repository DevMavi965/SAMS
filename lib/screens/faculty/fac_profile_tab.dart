import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/widgets/fac_widgets/fac_personal_info_card.dart';
import 'package:smas3/widgets/fac_widgets/fac_profile_card.dart';
import 'package:smas3/widgets/fac_widgets/fac_setting_card.dart';

import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../services/db_service.dart';
class FacProfileTab extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const FacProfileTab({super.key, required this.lecturer, required this.insAdmin, required this.institute, required this.department});

  @override
  State<FacProfileTab> createState() => _FacProfileTabState();
}

class _FacProfileTabState extends State<FacProfileTab> {


  @override
  Widget build(BuildContext context) {
    return SafeArea(child:ListView(
      children: [
        Text("Profile",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),

        Text("Manage your account settings",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        Fac_profile_Card(lecturer: widget.lecturer),
        SizedBox(height: 25,),
        Text("Personal Information",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        FacPersonalInfoCard(lecturer: widget.lecturer, insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department,),
        SizedBox(height: 25,),
        Text("Settings",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        FacSettingCard(lecturer: widget.lecturer, insAdmin: widget.insAdmin, institute: widget.institute,),
        SizedBox(height: 25,),
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
                        OutlinedButton(onPressed: (){
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
        )
      ],
    )
    );
  }
}
