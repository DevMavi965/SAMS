import 'package:flutter/material.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/admin_model.dart';
class admin_info_card extends StatefulWidget {
  final Admin admin;
  const admin_info_card({super.key, required this.admin});

  @override
  State<admin_info_card> createState() => _admin_info_cardState();
}

class _admin_info_cardState extends State<admin_info_card> {
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
          //semester current
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
                          child: Icon(PhosphorIconsBold.database,size: 25,color: Theme.of(context).primaryColor,),
                        ),
                        SizedBox(width: 10,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Database backup",),
                            Text("Configure Automatic backups",style: TextStyle(color: Colors.grey),),
                          ],
                        )
                        ,Spacer(),
                        Icon(Icons.arrow_forward_ios,color: Colors.grey,)
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
