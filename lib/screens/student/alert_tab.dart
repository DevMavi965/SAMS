import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/widgets/in_Notif_model.dart';

import '../../models/announcement_model.dart';
import '../../widgets/student_widgets/std_announc_card.dart';
class AlertTab extends StatefulWidget {
  final List<In_Notification> notifications;
  const AlertTab({super.key, required this.notifications});

  @override
  State<AlertTab> createState() => _AlertTabState();
}

class _AlertTabState extends State<AlertTab> {
  final List<Announcement> announcements=[
    Announcement(an_title: "system maintainance",
        an_message:"this  an_message dedicated to students of field to improve ets egh   hiu   fff  f yufd dytdydyd fdd",
        an_type: "urgent", target_aud: "All users"),
    Announcement(an_title: "Anuaual Sports gala",
        an_message:"this  an_message dedicated to students of field to improve ets egh   hiu   fff  f yufd dytdydyd fdd",
        an_type: "general", target_aud: "Students"),
    Announcement(an_title: "Anuaual Sports gala",
        an_message:"this  an_message dedicated to students of field to improve ets egh   hiu   fff  f yufd dytdydyd fdd",
        an_type: "event", target_aud: "Students")
  ];
  @override

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsetsGeometry.symmetric(
          horizontal: 15,
          vertical: 15,
        ),

        child: ListView(
          children: [
            SizedBox(height: 5,),
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
                // Text("See all",style: TextStyle(fontSize: 12,fontWeight: FontWeight.w500),)
                // ,SizedBox(width: 3,)
              ],
            ),
            SizedBox(height: 15,),
            // anouncements
            for(var ann in announcements)
              Std_Announcement_card(ann: ann),
          ],
        ),
      ),
    );
  }


}
