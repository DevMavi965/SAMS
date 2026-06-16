import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
class InsAdminGrid1 extends StatelessWidget {
  final int students,noOfFaculty,noOfDeparts,noOfAdmins;
  final double avg_attendance;
  const InsAdminGrid1({super.key, required this.students, required this.noOfFaculty, required this.noOfDeparts, required this.avg_attendance, required this.noOfAdmins});

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        //admins
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_rounded,color: Theme.of(context).primaryColorDark,),
              Text("$noOfAdmins",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),),
              Text("Total Admins",style: TextStyle(color: Colors.grey,fontSize: 10),)
            ],
          ),
        ),
        //students
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_alt_outlined,color: Theme.of(context).primaryColor,),
              Text("$students",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),),
              Text("Total Students",style: TextStyle(color: Colors.grey,fontSize: 10),)
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
            boxShadow: [
            BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
            ),],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.school_outlined,color: Colors.lightBlue,),
              Text("$noOfFaculty",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),),
              Text("Total Faculty",style: TextStyle(color: Colors.grey,fontSize: 10),)
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
            boxShadow: [
            BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
            ),]
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
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.trendUp,color:Theme.of(context).primaryColor,),
              Text("$avg_attendance%",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),),
              Text("Overall Attendance",style: TextStyle(color: Colors.grey,fontSize: 10),)
            ],
          ),
        ),//overall attendance
        //active announcements
        Container(
          // width: 200,
          // height: 120,
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.speakerSimpleHigh,color:Theme.of(context).primaryColor,),
              Text("$avg_attendance%",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500),),
              Flexible(child: Text("Active Announcements",style: TextStyle(color: Colors.grey,fontSize: 10),))
            ],
          ),
        ),



      ],
    );
  }
}
