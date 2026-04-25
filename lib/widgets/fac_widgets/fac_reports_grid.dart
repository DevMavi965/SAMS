import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
class FacReportsGrid extends StatelessWidget {
  final int total_students,lectures_this_week,total_records;
  final double avg_attendance;
  const FacReportsGrid({super.key, required this.total_students, required this.lectures_this_week, required this.total_records, required this.avg_attendance});

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        //classes this week
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
                  color: Colors.grey.shade300
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.calendar_today_outlined,color: Theme.of(context).primaryColor,),
              Text("$lectures_this_week",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400),),
              Text("Classes this week",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //total students
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
                  color: Colors.grey.shade300
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_outlined,color: Colors.lightBlue,),
              Text("$total_students",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400),),
              Text("total_students Students",style: TextStyle(color: Colors.grey,fontSize: 12),)
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
                  color: Colors.grey.shade300
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.trendUp,color:Theme.of(context).primaryColor,),
              Text("$avg_attendance%",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400),),
              Text("Avg Attendance",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),
        //total records in week
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
                  color: Colors.grey.shade300
              )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsDuotone.notebook,color:Colors.red,),
              Text("$total_records",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400),),
              Text("Total Records",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
        ),

      ],
    );
  }
}
