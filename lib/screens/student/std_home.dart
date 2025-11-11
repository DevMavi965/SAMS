import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/Lecture_model.dart';
import 'package:smas3/models/announcement_model.dart';

import '../../models/student_model.dart';
import '../../widgets/student_widgets/Custome_line_chart.dart';
import '../../widgets/student_widgets/att_rec_card.dart';
import '../../widgets/student_widgets/daily_status_card.dart';
import '../../widgets/student_widgets/over_all_att_card.dart';
import '../../widgets/student_widgets/std_announc_card.dart';
import '../../widgets/student_widgets/upcoming_class_card.dart';
class StdHome extends StatelessWidget {
  final List<Announcement> announcements;
  final List<Course> courses;
  final Student student;
  final List<String> months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
   StdHome({super.key, required this.announcements, required this.courses, required this.student});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      margin: EdgeInsets.all(12),
      child: ListView(
        children: [
          Column(

            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 15,),
              Text("Welcome back ${student.name}!",textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5,),
              Text("Here's your attendance overview",
                style: TextStyle(fontSize: 11,fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 25,),
              //announcements bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 5,),
                      Icon(
                        PhosphorIcons.megaphoneSimple(),color: Colors.red,fontWeight: FontWeight.bold,
                        size: 18,
                      ),
                      SizedBox(width: 5,),
                      Text("Announcements",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),)

                    ],
                  ),
                  SizedBox(width: 50,),
                  Text("See all",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w500),)
                  // ,SizedBox(width: 3,)
                ],
              ),
              SizedBox(height: 15,),
              //anouncements
              for(var ann in announcements)
                Std_Announcement_card(ann: ann),
              SizedBox(height: 20,),
              StudentStatusCard(status: "present", checkin_time: "8:40", streak: 13,attendence_percentage: 87,),
              SizedBox(height: 10,),
              AttRecCard(present_days: 34, late_days: 3, absent_days: 2),
              SizedBox(height: 20,),

              OverAllAttCard(thisMonth: 24, lastMonth: 88, totalDays: 30),
              SizedBox(height: 20,),

              CustomeLineChart(Months: months, StudentPersetage:[67,76,89,73,92,34,67]),
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Upcoming classes",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),)
                  ,Text("view all",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w400),)
                ],
              ),
              //upcoming classes
              for(var course in courses)
                if(course.status=="upcoming")
                  UpcomingClassCard(course: course)
            ],
          )
        ],
      ),
    );
  }
}
