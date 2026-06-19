import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../maxins/rm_functions.dart';
import '../../models/department.dart';
class DepartmentCard extends StatefulWidget {
  final Department department;
  const DepartmentCard({super.key, required this.department});

  @override
  State<DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<DepartmentCard> {
  @override
  Widget build(BuildContext context) {
    
      return Card(
        color: Colors.white,
        child: Container(
          padding: EdgeInsets.only(
              top: 10,
              bottom: 15
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 15,left: 5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          width: 4
                      )
                  ),
                  child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      radius: 30,
                      child:Text(RMFuncts.getFirstLetters(widget.department.name),style: TextStyle(color: Theme.of(context).primaryColor,fontWeight: FontWeight.w500),)
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(widget.department.name,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                    SizedBox(height: 9,),
                    Row(
                      children: [
                        Text("HOD: ",style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w600),),
                        SizedBox(width: 5,),
                        Icon(CupertinoIcons.profile_circled,color: Colors.grey,size: 18,),
                        SizedBox(width: 2,),
                        Text(widget.department.hod_name,style: TextStyle(color: Colors.grey),),
                      ],
                    ),
                    SizedBox(height: 9,),
                    Text("Created on: ${DateFormat("dd-MM-yyyy").format(widget.department.created_at!)}",style: TextStyle(color: Colors.black54),)
                  ],
                ),
              ),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // delete department
                  SizedBox(height: 5,),
                  // update department

                ],
              ))
            ],
          ),
        ),
      );
   
  }
}
