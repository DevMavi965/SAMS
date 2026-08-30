import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/services/db_service.dart';
import 'package:smas3/widgets/admin_widgets/adminProfileCard.dart';
import 'package:smas3/widgets/admin_widgets/admin_setting_card.dart';
import 'package:smas3/widgets/fac_widgets/admin_info_card.dart';

class AdminProfile extends StatefulWidget {
  final Admin _admin;
  const AdminProfile({super.key, required Admin admin}) : _admin = admin;

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(
      children: [
        Text("Settings",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
        Text("System Configuration",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 10,),
        Admin_profile_Card(admin: widget._admin),
        SizedBox(height: 25,),
        Text("My Duties",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        // admin_info_card(admin: widget._admin),
        InkWell(
          onTap: (){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Access it from dashboard "),backgroundColor: Theme.of(context).primaryColor,));
          },
          child: Container(
            clipBehavior: Clip.hardEdge,
            // height: 265,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              // border: Border.all(
              //   color: Colors.grey,
              //   width: 0.2,
              // ),
            ),
            child: Table(
              border:
            TableBorder.all(
              color: Colors.white,
              width: 0.2,
            ),
              children: [
                for(int i=0;i<widget._admin.permissions!.length;i++)
                  TableRow(
                      children: [
                         Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(PhosphorIconsBold.scroll,size: 25,color: Theme.of(context).primaryColor,),
                                ),
                                SizedBox(width: 10,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget._admin.permissions![i].split("_").join(" "),),
                                    Text("Manage ${widget._admin.permissions![i].split("_").join(" ")} operations",style: TextStyle(color: Colors.grey),),
                                  ],
                                ),

                              ],
                            ),
                          ),

                      ]
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 25,),
        Text("Preferences",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        AdminSettingCard(admin: widget._admin),
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
    ));
  }
}
