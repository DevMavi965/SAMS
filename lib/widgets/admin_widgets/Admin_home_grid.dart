import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
class AdminHomeGrid extends StatelessWidget {
  final int total,noOfFaculty,noOfDeparts;
  final double avg_attendance;
  const AdminHomeGrid({super.key, required this.total, required this.noOfFaculty, required this.noOfDeparts, required this.avg_attendance});

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
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

          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_outlined,color: Theme.of(context).primaryColor,),
              Text("$total",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Total Students",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //faculty
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),

          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.school_outlined,color: Colors.lightBlue,),
              Text("$noOfFaculty",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Total Faculty",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //departments
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),

          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.buildingApartment,color: Colors.purple,),
              Text("$noOfDeparts",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Total Departments",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //overall attendance
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),

          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.trendUp,color:Theme.of(context).primaryColor,),
              Text("$avg_attendance%",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
              Text("Overall Attendance",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        

      ],
    );
  }
}
