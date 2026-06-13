import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/services/db_service.dart';
import 'package:smas3/widgets/admin_widgets/admin_setting_card.dart';
import 'package:smas3/widgets/fac_widgets/admin_info_card.dart';
import 'package:smas3/widgets/insAdmin/info_card.dart';
import 'package:smas3/widgets/insAdmin/insSettingc.dart';
import 'package:smas3/widgets/insAdmin/profile_card.dart';

import '../../widgets/admin_widgets/adminProfileCard.dart';

class insAdminProfile extends StatefulWidget {
  final InsAdmin insAdmin;
  const insAdminProfile({super.key, required this.insAdmin, }) ;

  @override
  State<insAdminProfile> createState() => _insAdminProfileState();
}

class _insAdminProfileState extends State<insAdminProfile> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(
      children: [
        Text("Settings",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
        Text("System Configuration",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 10,),
        InsAdmin_ProfileCard(insAdmin: widget.insAdmin),
        SizedBox(height: 25,),
        Text("System Settings",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        Ins_info_card(insAdmin: widget.insAdmin,),
        SizedBox(height: 25,),
        Text("Preferences",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        InsAdminSetting(insAdmin: widget.insAdmin),
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
                ,content: Text("Logging out as ${widget.insAdmin.name}")));
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
