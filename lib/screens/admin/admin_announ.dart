import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_card.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_grid.dart';
class AdminAnnouncements extends StatefulWidget {
  const AdminAnnouncements({super.key});

  @override
  State<AdminAnnouncements> createState() => _AdminAnnouncementsState();
}

class _AdminAnnouncementsState extends State<AdminAnnouncements> {
 List<Announcement> announcements=[
   Announcement(
       id: "124575",
       an_title: "system upgrade",
       an_message: "system going to update in upcoming days ",
       an_type: "urgent",
       target_aud: "all users",
      created_at: DateTime.now()
   ),
   Announcement(
       id: "124575",
       an_title: "system upgrade",
       an_message: "system going to update in upcoming days ",
       an_type: "urgent",
       target_aud: "all users",
       created_at: DateTime.now()
   ),
   Announcement(
       id: "124575",
       an_title: "system upgrade",
       an_message: "system going to update in upcoming days ",
       an_type: "urgent",
       target_aud: "all users",
       created_at: DateTime.now()
   )
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
