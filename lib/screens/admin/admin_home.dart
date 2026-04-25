import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/deprt_alert.dart';
import 'package:smas3/widgets/admin_widgets/Admin_home_grid.dart';
import 'package:smas3/widgets/admin_widgets/admin_custom_lineCart.dart';
import 'package:smas3/widgets/admin_widgets/depart_att_card.dart';
import 'package:smas3/widgets/admin_widgets/deprt_aler_card.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<Map<String,dynamic>> departments=[
    {
      "name":"Computer Science",
      "attendence":87,
      "total_students":156
    },
    {
      "name":"Physics",
      "attendence":68,
      "total_students":120
    },
    {
      "name":"Information Technology",
      "attendence":93,
      "total_students":100
    },
    {
      "name":"Computer Engineering",
      "attendence":75,
      "total_students":90
    },
    {
      "name":"Electrical Engineering",
      "attendence":81,
      "total_students":513
    }
  ];
  List<DepartmentalAlerts> dept_alerts=[
    DepartmentalAlerts(id: "4ft5", content: "Cs depart has 4 new students", type: "positive", created_at: DateTime(2026,4,13)),
    DepartmentalAlerts(id: "32d4", content: "14 students have below 75% attendance", type: "negative", created_at: DateTime(2026,3,21)),
    DepartmentalAlerts(id: "654a", content: "New faculty onboarding pending", type: "neutral", created_at: DateTime(2026,4,7)),


  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(children: [
      Text("Admin Dashboard",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
      SizedBox(height: 7,),
      Text("System Overview & Management",style: TextStyle(fontSize: 15,color: Colors.grey),),
      SizedBox(height: 20,),
      AdminHomeGrid(total: 500, noOfFaculty: 210, noOfDeparts: 6, avg_attendance: 89),
      SizedBox(height: 20,),
      AdminCustomLinechart(days: ["Mon","Tue","Wed","Thu","Fri"], daily_attendance_percentage: [67,76,83,76,81]),
      SizedBox(height: 20,),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text("Department Performance",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400)),
        TextButton(onPressed: (){

        },
            child: Text("View All",style: TextStyle(color: Colors.black),))
      ],),
      SizedBox(height: 15,),
      // department performance bar chart
      SizedBox(
        height: 300,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 15),
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: true,border: Border(
                  bottom: BorderSide(color: Colors.grey,width: 1),
                  left: BorderSide(color: Colors.grey,width: 0.5),
                )),
               titlesData: FlTitlesData(
                 rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 bottomTitles: AxisTitles(sideTitles: SideTitles(
                   showTitles: true,
                   getTitlesWidget: (v,meta){

                     return Text(getFirstLetters(departments[v.toInt()]["name"]));
                   }
                 ))
               ),
              barGroups: [
                for(int i=0;i<departments.length;i++)
                BarChartGroupData(x:i,
                barRods: [
                  BarChartRodData(toY: departments[i]["attendence"].toDouble(),color: Theme.of(context).primaryColor,width: 35,borderRadius: BorderRadius.circular(0))
                ]
                )
              ]
              )
            ),
          ),
        ),
      ),
      SizedBox(height: 15,),
      for(int i=0;i<departments.length;i++)
      DepartAttCard(department: departments[i]),
      Row(children: [Text("Recent Alerts",style: TextStyle(fontWeight: FontWeight.w400,fontSize: 16),)],),
      SizedBox(height: 15,),
      for(int i=0;i<dept_alerts.length;i++)
        DeprtAlerCard(dept_alert: dept_alerts[i])
    ],));
  }

  static String getFirstLetters(String input) {
    if (input.isEmpty) return '';

    List<String> words = input.split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    // If only one word_deprtm name, return first 2letters
    if (words.length == 1) {
      String singleWord = words[0];
      if (singleWord.length == 1) return singleWord.toUpperCase();
      return singleWord.substring(0, 2).toUpperCase();
    }

    // Multiple words: return first letter of each word
    return words.map((word) => word[0]).join().toUpperCase();
  }
}
