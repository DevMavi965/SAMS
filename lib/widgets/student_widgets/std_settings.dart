import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/student_model.dart';

import '../../providers/theme_Provider.dart' show ThemeProvider;
class StdSettings extends StatefulWidget {
  final Student student;
  const StdSettings({super.key, required this.student});

  @override
  State<StdSettings> createState() => _StdSettingsState();
}

class _StdSettingsState extends State<StdSettings> {
  bool notif_on = false,_theme = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      // height: 265,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey,
          width: 0.2,
        ),
      ),
      child:
      Table(
        border:
        TableBorder.all(
          color: Colors.grey,
          width: 0.2,
        ),
        children: [
          //profile
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child:
                  InkWell(
                    onTap: (){
                      print("updated profile");
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_2_outlined,size: 25,color: Theme.of(context).primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Edit Profile",),
                            Text("update your personal information",style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Spacer(),

                        Icon(Icons.navigate_next,size: 20,color: Colors.grey,)
                      ],
                    ),
                  ),
                )
              ]
          ),
          //push notification
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
                        child: Icon(CupertinoIcons.bell,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Push Notifications",),
                          Text("03351094534",style: TextStyle(color: Colors.grey),),
                        ],
                      ),
                      Spacer(),
                      Transform.scale(
                        scale: 0.8,
                      child:
                      Switch(

                          activeThumbColor: Theme.of(context).primaryColorLight,
                          inactiveTrackColor: Colors.white,
                          thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                //on here
                                return const Icon(Icons.check, color: Color.fromARGB(255, 0, 186, 125),);
                              }
                              // off state
                              return const Icon(Icons.close, color: Colors.white);
                            },
                          ),
                          value: notif_on, onChanged: (value){
                        setState(() {
                          notif_on =!notif_on;
                        });

                      }),
                      )
                    ],
                  ),
                )
              ]
          ),
          //Darkmode
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
                        child: Icon(CupertinoIcons.moon,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Theme Mode",),
                          Text("toggle app theme",style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Spacer(),
                      Transform.scale(
                        scale: 0.8,
                       child: Switch(

                           activeThumbColor: Theme.of(context).primaryColorLight,
                           inactiveTrackColor: Colors.white,
                           thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                                 (Set<MaterialState> states) {
                               if (states.contains(MaterialState.selected)) {
                                 //on here
                                 return const Icon(Icons.wb_sunny, color: Colors.orangeAccent);
                               }
                               // off state
                               return const Icon(Icons.nightlight_round, color: Colors.white);
                             },
                           ),
                         value: Provider.of<ThemeProvider>(context).isDarkMode,
                         onChanged: (value) {
                           Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                         },),
                      )
                    ],
                  ),
                )
              ]
          ),
          //bio metric setting
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: InkWell(
                    onTap: (){
                      print("updated biometric: ${widget.student.name}");
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(PhosphorIconsBold.shieldCheck,size: 25,color: Theme.of(context).primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Biometric Settings",),
                            Text("configure fingerprint & face id",style: TextStyle(color: Colors.grey),),
                          ],
                        ),
                        Spacer(),
                        Icon(Icons.navigate_next,size: 20,color: Colors.grey,)
                      ],
                    ),
                  ),
                )
              ]
          )
        ],
      ),
    );
  }
}
