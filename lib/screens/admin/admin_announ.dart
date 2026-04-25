import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_card.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_grid.dart';

import '../../models/admin_announcement.dart';

class AdminAnnouncements extends StatefulWidget {
  const AdminAnnouncements({super.key});

  @override
  State<AdminAnnouncements> createState() => _AdminAnnouncementsState();
}

class _AdminAnnouncementsState extends State<AdminAnnouncements> {
  List<AdminAnnouncement> announcements=[
    AdminAnnouncement(id: "124575", title: "system upgrade", content: "system going to update in upcoming days ", type: "urgent", target: "all users", created_at: DateTime.now()),
    AdminAnnouncement(id: "564441", title: "new registrations", content: "open for addminssionns now ", type: "general", target: "all students", created_at: DateTime.now()),
    AdminAnnouncement(id: "124676", title: "Annual Tech Fest 2025", content: "system going to update in upcoming days ", type: "event", target: "all users", created_at: DateTime.now()),


  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(
      children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text("Announcements",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                 Text("Manage system-wide announcements",style: TextStyle(color: Colors.grey),)
               ],
             ),
             SizedBox(
               height: 50,

               child: Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Theme.of(context).primaryColor,
                     ),
                     onPressed: (){

                 },icon: Icon(CupertinoIcons.add,color: Colors.white,), label: Text("New",style: TextStyle(color: Colors.white),)),
               ),
             )
           ],
         ),
        SizedBox(height: 20,),
        AdminAnnGrid(total: 15, urgent:8, events: 7),
        SizedBox(height: 10,),
        for(int i=0;i<announcements.length;i++)
        AdminAnnCard(adminAnnouncement: announcements[i])
        
      ],
    ));
  }
}
