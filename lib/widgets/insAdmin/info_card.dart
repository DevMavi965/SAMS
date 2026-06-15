import 'package:flutter/material.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/screens/ins_admin/ins_selection.dart';

import '../../models/admin_model.dart';
class Ins_info_card extends StatefulWidget {
  final InsAdmin insAdmin;
  const Ins_info_card({super.key, required this.insAdmin});

  @override
  State<Ins_info_card> createState() => _Ins_info_cardState();
}

class _Ins_info_cardState extends State<Ins_info_card> {
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
          //semester current
          TableRow(
              children: [
                InkWell(
                  onTap: (){
                   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>InsSelection(insAdmin: widget.insAdmin)), (t)=>false);
                  },
                  child: Padding(
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
                          child: Icon(Icons.school,size: 25,color: Theme.of(context).primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Institute Settings",),
                            Text("Switch & Configure Institute Settings",style: TextStyle(color: Colors.grey),),
                          ],
                        )
                        ,Spacer(),
                        Icon(Icons.arrow_forward_ios,color: Colors.grey,)
                      ],
                    ),
                  ),
                )
              ]
          ),
          //email
          TableRow(
              children: [
                InkWell(
                  onTap: (){

                  },
                  child: Padding(
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
                          child: Icon(Icons.people_alt_outlined,size: 25,color: Theme.of(context).primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("User Management",),
                            Text("Add,Remove,Manage Users",style: TextStyle(color: Colors.grey),),
                          ],
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios,color: Colors.grey,)
                      ],
                    ),
                  ),
                )
              ]
          ),
          //phone
          TableRow(
              children: [
                InkWell(
                  onTap: (){

                  },
                  child: Padding(
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
                          child: Icon(PhosphorIconsBold.buildingApartment,size: 25,color: Theme.of(context).primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Department Settings",),
                            Text("Configure Departments & Classes",style: TextStyle(color: Colors.grey),),
                          ],
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios,color: Colors.grey,)
                      ],
                    ),
                  ),
                )
              ]
          ),
          //course enrolled date
          TableRow(
              children: [
                InkWell(
                  onTap: (){

                  },
                  child: Padding(
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
                          child: Icon(Icons.shield_outlined,size: 25,color: Theme.of(context).primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Security & Permissions",),
                            Text("Manage access control",style: TextStyle(color: Colors.grey),),
                          ],
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios,color: Colors.grey,)
                      ],
                    ),
                  ),
                )
              ]
          ),

        ],
      ),
    );
  }
}
