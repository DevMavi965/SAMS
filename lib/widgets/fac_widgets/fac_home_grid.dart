import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
class FacHomeGrid extends StatelessWidget {
  final int total,present,pending_classes;
  final double avg_attendance;
  const FacHomeGrid({super.key, required this.total, required this.present, required this.pending_classes, required this.avg_attendance});

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2,
      shrinkWrap: true,
      children: [
        //students
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  width: 0.5,
                  color: Colors.grey
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_outlined,color: Colors.lightBlue,),
              Text("$total",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Total Students",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //present today
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  width: 0.5,
                  color: Colors.grey
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline,color: Theme.of(context).primaryColor,),
              Text("$present",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Present Today",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //avg attendance
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  width: 0.5,
                  color: Colors.grey
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.trendUp,color:Theme.of(context).primaryColor,),
              Text("$avg_attendance%",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Avg Attendance",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //pending classes
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  width: 0.5,
                  color: Colors.grey
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.clock,color:Colors.red,),
              Text("$pending_classes",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Pending Classes",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),

      ],
    );
  }
}
