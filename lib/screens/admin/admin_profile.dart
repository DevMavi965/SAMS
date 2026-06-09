import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        Text("System Settings",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        admin_info_card(admin: widget._admin),
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.red
                ,content: Text("Logging out as ${widget._admin.name}")));
               Provider.of<DbService>(context,listen: false).signOut(context);
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
          label: Text("Logout"),
          icon: Icon(Icons.logout),
        ),
        SizedBox(height: 35,),
      ],
    ));
  }
}
