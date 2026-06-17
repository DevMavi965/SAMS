import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/deprt_alert.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/widgets/admin_widgets/Admin_home_grid.dart';
import 'package:smas3/widgets/admin_widgets/admin_custom_lineCart.dart';
import 'package:smas3/widgets/admin_widgets/depart_att_card.dart';
import 'package:smas3/widgets/admin_widgets/deprt_aler_card.dart';

class AdminHome extends StatefulWidget {
  final Admin admin;
  const AdminHome({super.key, required this.admin});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {

  List<DepartmentalAlerts> dept_alerts=[
    DepartmentalAlerts(id: "4ft5", content: "Cs depart has 4 new students", type: "positive", created_at: DateTime(2026,4,13)),
    DepartmentalAlerts(id: "32d4", content: "14 students have below 75% attendance", type: "negative", created_at: DateTime(2026,3,21)),
    DepartmentalAlerts(id: "654a", content: "New faculty onboarding pending", type: "neutral", created_at: DateTime(2026,4,7)),


  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(children: [
      Text("Welcome ${widget.admin.name}!",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
      SizedBox(height: 7,),
      Text("System Overview & Management",style: TextStyle(fontSize: 15,color: Colors.grey),),
      SizedBox(height: 20,),
      AdminHomeGrid(total: 500, noOfFaculty: 210, noOfDeparts: 6, avg_attendance: 89),
      SizedBox(height: 20,),
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
