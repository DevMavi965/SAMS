import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/announcement_model.dart';

import '../../services/db_service.dart';

class AdminAnnCard extends StatefulWidget {
  final Announcement adminAnnouncement;
  const AdminAnnCard({super.key, required this.adminAnnouncement});

  @override
  State<AdminAnnCard> createState() => _AdminAnnCardState();
}

class _AdminAnnCardState extends State<AdminAnnCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border(
                left: BorderSide(
                    color: widget.adminAnnouncement.an_type=="urgent"?Colors.red:widget.adminAnnouncement.an_type=="event"?Colors.purple:Colors.green,
                    width: 5
                )
            )
        ),
        padding: EdgeInsets.symmetric(vertical: 10,horizontal: 15),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: widget.adminAnnouncement.an_type=="urgent"?Colors.red.shade50:widget.adminAnnouncement.an_type=="event"?Colors.purple.shade50:Colors.green.shade50,
                radius: 25,
                child: Icon(widget.adminAnnouncement.an_type=="event"?Icons.calendar_today_outlined:PhosphorIconsBold.megaphone,color: widget.adminAnnouncement.an_type=="urgent"?Colors.red:widget.adminAnnouncement.an_type=="event"?Colors.purple:Colors.green,),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(widget.adminAnnouncement.an_title,style: TextStyle(fontWeight: FontWeight.w400,fontSize: 17),)
                  ],),
                  SizedBox(height: 10,),
                  Row(children: [
                    Badge(
                      backgroundColor:widget.adminAnnouncement.an_type=="urgent"?Colors.red:widget.adminAnnouncement.an_type=="event"?Colors.purple:Colors.green,
                      label: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(widget.adminAnnouncement.an_type),
                      ),),
                    SizedBox(width: 15,),
                    Container(
                      decoration: BoxDecoration(
                          color: Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.grey.shade400,
                              width: 0.3
                          )
                      ),
                      child: Badge(
                        backgroundColor: Color(0xfff1f5f9),
                        label: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Row(
                            children: [
                              Icon(Icons.people_alt_outlined,size: 20,),
                              SizedBox(width: 7,),
                              Text(widget.adminAnnouncement.target_aud!=null?widget.adminAnnouncement.target_aud!:"all users",style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500,color: Colors.black),),
                            ],
                          ),
                        ),),
                    ),
                  ],)
                ],),
              IconButton(onPressed:(){
                showDialog(context: context, builder: (context)=>AlertDialog(
                  title: Text("Delete Announcement"),
                  content: Text("Are you sure you want to delete this announcement?"),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: (){
                      Navigator.pop(context);
                    },child: Text("Cancel",style: TextStyle(color: Colors.white),),),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: (){
                      Provider.of<DbService>(context,listen: false).removeAnnouncement(context, widget.adminAnnouncement.id!);
                      Navigator.pop(context);
                    },child: Text("Yes",style: TextStyle(color: Colors.white),),),
                  ],
                ));
              } ,
                  icon: Icon(CupertinoIcons.delete,color: Colors.red,size: 18,))
            ],),
          SizedBox(height: 7,),
          Row(
            children: [
              Expanded(child: SizedBox(width: 10,)),
              Expanded(flex: 4,child:
              Text(widget.adminAnnouncement.an_message,maxLines: 3,overflow: TextOverflow.ellipsis,)),
              // Expanded(child: SizedBox(height: 10,))
            ],),
          SizedBox(height: 7,),
          Row(children: [
            Expanded(child: SizedBox()),
            Expanded(flex:4,child: Text("Posted by Admin User on: ${widget.adminAnnouncement.created_at!.day}/${widget.adminAnnouncement.created_at!.month}/${widget.adminAnnouncement.created_at!.year}",style: TextStyle(color: Colors.grey),)),
            // Expanded(child: SizedBox()),
          ],)
        ],),
      ),
    );
  }
}
