import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/widgets/fac_widgets/fac_course_card2.dart';
import 'package:smas3/widgets/fac_widgets/fac_custom_lineChart.dart';
import 'package:smas3/widgets/fac_widgets/fac_pie_week.dart';
import 'package:smas3/widgets/fac_widgets/fac_reports_grid.dart';
import 'package:smas3/widgets/fac_widgets/fac_week_graph.dart';

import '../../models/fac_model.dart';
class FacReportsTab extends StatefulWidget {
  final Lecturer lecturer;
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  const FacReportsTab({super.key, required this.lecturer, required this.insAdmin, required this.institute, required this.department});

  @override
  State<FacReportsTab> createState() => _FacReportsTabState();
}

class _FacReportsTabState extends State<FacReportsTab> {
  List<String> opts=[
    "Weekly","Monthly","Course-wise"
  ];
  int selected_opt=0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
   selected_opt==0?
   ListView(
     children: [
       Text("Reports & Analytics",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
       SizedBox(height: 7,),
       Text("View detailed Attendance insights",style: TextStyle(fontSize: 15,color: Colors.grey),),
       SizedBox(height: 20,),
       // selector panel
       Container(
         margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
         padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
         decoration: BoxDecoration(
             color:Color(0xfff1f5f9) ,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(
                 color: Colors.grey.shade300,
                 width: 0.9
             )
         ),
         child: Row(
           children: [
             for(int i=0;i<opts.length;i++)
               Expanded(
                 child: InkWell(
                   onTap: (){
                     setState(() {
                       selected_opt=i;
                     });
                   },
                   child: Container(
                     margin: EdgeInsets.symmetric(vertical: 2),
                     decoration: BoxDecoration(
                         color:i==selected_opt? Colors.white:Colors.transparent,
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(
                             width:i==selected_opt? 0.1:0,
                             color: i==selected_opt? Colors.grey.shade200:Colors.transparent
                         )
                     ),

                     child: Padding(
                       padding: const EdgeInsets.all(4.0),
                       child: Text(opts[i],textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                     ),
                   ),
                 ),
               )
           ],
         ),
       ),
       SizedBox(height: 20,),
       FacReportsGrid(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, lecturer: widget.lecturer,),
       SizedBox(height: 15,),
       // week overview bar graph
       FacWeeklyAttendanceChart(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, lecturer: widget.lecturer,),
       SizedBox(height: 15,),
       SizedBox(height: 15,),
       //   Pie chart distributiom
       FacAttendanceDistributionChart(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, lecturer: widget.lecturer,)
     ],
   )//weekly
       :(selected_opt==1?
   ListView(
      children: [
        Text("Reports & Analytics",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
        SizedBox(height: 7,),
        Text("View detailed Attendance insights",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        // selector panel
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
          padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
          decoration: BoxDecoration(
            color:Color(0xfff1f5f9) ,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 0.9
            )
          ),
          child: Row(
            children: [
              for(int i=0;i<opts.length;i++)
                Expanded(
                  child: InkWell(
                    onTap: (){
                      setState(() {
                        selected_opt=i;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color:i==selected_opt? Colors.white:Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          width:i==selected_opt? 0.1:0,
                          color: i==selected_opt? Colors.grey.shade200:Colors.transparent
                        )
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(opts[i],textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
        SizedBox(height: 20,),
       FacCustomLinechart(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, lecturer: widget.lecturer,)

      ],
    ):
   ListView(//lecture-wise
     children: [
       Text("Reports & Analytics",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
       SizedBox(height: 7,),
       Text("View detailed Attendance insights",style: TextStyle(fontSize: 15,color: Colors.grey),),
       SizedBox(height: 20,),
       // selector panel
       Container(
         margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
         padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
         decoration: BoxDecoration(
             color:Color(0xfff1f5f9) ,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(
                 color: Colors.grey.shade300,
                 width: 0.9
             )
         ),
         child: Row(
           children: [
             for(int i=0;i<opts.length;i++)
               Expanded(
                 child: InkWell(
                   onTap: (){
                     setState(() {
                       selected_opt=i;
                     });
                   },
                   child: Container(
                     margin: EdgeInsets.symmetric(vertical: 2),
                     decoration: BoxDecoration(
                         color:i==selected_opt? Colors.white:Colors.transparent,
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(
                             width:i==selected_opt? 0.1:0,
                             color: i==selected_opt? Colors.grey.shade200:Colors.transparent
                         )
                     ),

                     child: Padding(
                       padding: const EdgeInsets.all(4.0),
                       child: Text(opts[i],textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                     ),
                   ),
                 ),
               )
           ],
         ),
       ),
       SizedBox(height: 20,),
       // courses with thier data
       FacCourseWiseList(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, lecturer: widget.lecturer)
     ],
   )));//lecture-wise
  }

 _getBarGroups() {
    final _data = [
      [45,7,3],
      [56,6,3],
      [35,17,8],
      [44,9,0],
      [39,12,3],
    ];
   return  List.generate(_data.length, (index){
     return BarChartGroupData(x: index,

     barRods: [
       BarChartRodData(toY: _data[index][0].toDouble(),color: Colors.green,borderRadius: BorderRadius.circular(0),width: 10),
       BarChartRodData(toY: _data[index][1].toDouble(),color: Colors.red,borderRadius: BorderRadius.circular(0),width: 10),
       BarChartRodData(toY: _data[index][2].toDouble(),color: Colors.brown,borderRadius: BorderRadius.circular(0),width: 10),
     ]
     );
   });
  }
  // Future<void> fetchLecturerLectures(String lecturerId) async {
  //   loading = true;
  //   notifyListeners();
  //   try {
  //     final myCourses = courses.where((c) => c.lecturer_id == lecturerId).toList();
  //     List<LectureModel> fetched = [];
  //
  //     for (var c in myCourses) {
  //       final snap = await dbref
  //           .collection("ins_admins").doc(c.insAdminId)
  //           .collection("institutes").doc(c.institute_id)
  //           .collection("departments").doc(c.department_id)
  //           .collection("sessions").doc(c.session_id)
  //           .collection("semesters").doc(c.semester_id)
  //           .collection("courses").doc(c.id)
  //           .collection("lectures").get();
  //
  //       for (var lec in snap.docs) {
  //         fetched.add(LectureModel(
  //           id: lec.id,
  //           course: lec['course_name'],
  //           dated: (lec['dated'] as Timestamp).toDate(),
  //           start_time: TimeOfDay.fromDateTime((lec['start_time'] as Timestamp).toDate()),
  //           end_time: TimeOfDay.fromDateTime((lec['end_time'] as Timestamp).toDate()),
  //           room: lec['room'],
  //           status: lec['status'],
  //           attendance: (lec['attendance'] as List<dynamic>? ?? [])
  //               .map((a) => Attendance.fromMap(a as Map<String, dynamic>))
  //               .toList(),
  //         ));
  //       }
  //     }
  //     lectures = fetched;
  //   } catch (e) {
  //     print(e.toString());
  //   } finally {
  //     loading = false;
  //     notifyListeners();
  //   }
  // }
}
