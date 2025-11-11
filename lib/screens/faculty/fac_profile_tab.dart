import 'package:flutter/material.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/widgets/fac_widgets/fac_personal_info_card.dart';
import 'package:smas3/widgets/fac_widgets/fac_profile_card.dart';
import 'package:smas3/widgets/fac_widgets/fac_setting_card.dart';
class FacProfileTab extends StatefulWidget {
  final Lecturer lecturer;
  const FacProfileTab({super.key, required this.lecturer});

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
        FacPersonalInfoCard(lecturer: widget.lecturer),
        SizedBox(height: 25,),
        Text("Settings",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
        SizedBox(height: 10,),
        FacSettingCard(lecturer: widget.lecturer),
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
               ,content: Text("Logging out as ${widget.lecturer.name}")));
          },
          label: Text("Logout"),
          icon: Icon(Icons.logout),
        )
      ],
    )
    );
  }
}
