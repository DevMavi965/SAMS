import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/admin_announcement.dart';

class AdminAnnCard extends StatefulWidget {
  final AdminAnnouncement adminAnnouncement;
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
                    color: widget.adminAnnouncement.type=="urgent"?Colors.red:widget.adminAnnouncement.type=="event"?Colors.purple:Colors.green,
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
                backgroundColor: widget.adminAnnouncement.type=="urgent"?Colors.red.shade50:widget.adminAnnouncement.type=="event"?Colors.purple.shade50:Colors.green.shade50,
                radius: 25,
                child: Icon(widget.adminAnnouncement.type=="event"?Icons.calendar_today_outlined:PhosphorIconsBold.megaphone,color: widget.adminAnnouncement.type=="urgent"?Colors.red:widget.adminAnnouncement.type=="event"?Colors.purple:Colors.green,),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(widget.adminAnnouncement.title,style: TextStyle(fontWeight: FontWeight.w400,fontSize: 17),)
                  ],),
                  SizedBox(height: 10,),
                  Row(children: [
                    Badge(
                      backgroundColor:widget.adminAnnouncement.type=="urgent"?Colors.red:widget.adminAnnouncement.type=="event"?Colors.purple:Colors.green,
                      label: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(widget.adminAnnouncement.type),
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
                              Text(widget.adminAnnouncement.target,style: TextStyle(fontSize: 13,fontWeight: FontWeight.w500,color: Colors.black),),
                            ],
                          ),
                        ),),
                    ),
                  ],)
                ],),
              IconButton(onPressed:(){} ,
                  icon: Icon(CupertinoIcons.delete,color: Colors.red,size: 18,))
            ],),
          SizedBox(height: 7,),
          Row(
            children: [
              Expanded(child: SizedBox(width: 10,)),
              Expanded(flex: 4,child:
              Text(widget.adminAnnouncement.content,maxLines: 3,overflow: TextOverflow.ellipsis,)),
              // Expanded(child: SizedBox(height: 10,))
            ],),
          SizedBox(height: 7,),
          Row(children: [
            Expanded(child: SizedBox()),
            Expanded(flex:4,child: Text("Posted by Admin User on: ${widget.adminAnnouncement.created_at.day}/${widget.adminAnnouncement.created_at.month}/${widget.adminAnnouncement.created_at.year}",style: TextStyle(color: Colors.grey),)),
            // Expanded(child: SizedBox()),
          ],)
        ],),
      ),
    );
  }
}
