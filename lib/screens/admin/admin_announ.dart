import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_card.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_grid.dart';

import '../../services/db_service.dart';
class AdminAnnouncements extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const AdminAnnouncements({super.key, required this.insAdmin, required this.institute});

  @override
  State<AdminAnnouncements> createState() => _AdminAnnouncementsState();
}

class _AdminAnnouncementsState extends State<AdminAnnouncements> {
 List<Announcement> announcements=[];
  @override
  Widget build(BuildContext context) {
    return  SafeArea(child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 5,
      ),
      child: StreamBuilder(stream:  Provider.of<DbService>(context, listen: false).dbref
          .collection("ins_admins")
          .doc(widget.insAdmin.id)
          .collection("institutes")
          .doc(widget.institute.id).collection("announcements").snapshots(),
          builder: (StreamContext,snapshot){
            if(snapshot.connectionState==ConnectionState.waiting){
              return Center(child: SizedBox(
                  height: 60,
                  width: 60,
                  child: Lottie.asset("assets/anims/an1.json")),);
            }else if(snapshot.hasError){
              return Center(child: Text(snapshot.error.toString()),);
            }else if(!snapshot.hasData){
              return Center(child: Text("No data found"),);
            }else if(snapshot.hasData){
              if(snapshot.data!.docs.isEmpty){
                return Column(
                    children: [
                      SizedBox(height: 20,),
                      AdminAnnGrid(total: 0, urgent:0, events: 0),
                      SizedBox(height: 15,),
                      Center(child: Text("New announcements will appear here...",style: TextStyle(color: Colors.grey),))
                    ]
                );
              }
              announcements.clear();
              for(var doc in snapshot.data!.docs){
                announcements.add(
                    Announcement(
                      id: doc.id,
                      an_title: doc['title'],
                      an_message: doc['content'],
                      an_type: doc['type'],
                      target_aud: doc['target'],
                      created_at: doc['created_at'].toDate(),
                    )
                );
              }
              int total=announcements.length;
              int urgent=announcements.where((element) => element.an_type=="urgent").length;
              int events=announcements.where((element) => element.an_type=="event").length;
              return ListView(
                children: [
                  Text("Announcements",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
                  SizedBox(height: 7,),
                  Text("View Announcements",style: TextStyle(fontSize: 15,color: Colors.grey),),
                  SizedBox(height: 20,),
                  AdminAnnGrid(total: total, urgent:urgent, events: events),
                  SizedBox(height: 15,),
                  ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: announcements.length,
                      itemBuilder: (tcontext,index)=>InkWell(
                          child: AdminAnnCard(adminAnnouncement: announcements[index]))),
                ],
              );
            }
            return SizedBox();
          }),

      // child: ListView(
      //   children: [
      //     SizedBox(height: 20,),
      //     AdminAnnGrid(total: 15, urgent:8, events: 7),
      //     SizedBox(height: 10,),
      //     for(int i=0;i<announcements.length;i++)
      //       AdminAnnCard(adminAnnouncement: announcements[i])
      //
      //   ],
      // ),
    ));
  }
}
