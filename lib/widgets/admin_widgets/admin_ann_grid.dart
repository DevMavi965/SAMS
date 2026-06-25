import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';

import '../../models/institute.dart';
import '../../services/db_service.dart';

class AdminAnnGrid extends StatefulWidget {
  final int total,urgent,events;

  const AdminAnnGrid({super.key, required this.total, required this.urgent, required this.events, });

  @override
  State<AdminAnnGrid> createState() => _AdminAnnGridState();
}

class _AdminAnnGridState extends State<AdminAnnGrid> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0,vertical: 1),
      child: SizedBox(
        height: MediaQuery.of(context).size.height*0.20,
        child: Row(

          children: [
            //total flex
            Expanded(child:
            Container(
              padding: EdgeInsets.all(5),
              margin: EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      width: 0.5,
                      color: Colors.grey.shade400
                  )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(height: 15,),
                  CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withAlpha(50),child:Icon(PhosphorIconsBold.megaphone,
                    color: Theme.of(context).primaryColor,),
                  ),
                  SizedBox(height: 20,),
                  Text(widget.total.toString(),style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 20,),
                  Text("Total",style: TextStyle(color: Colors.grey),),
                  SizedBox(height: 10,),
                ],
              ),
            )),
            //urgent
            Expanded(child:
            Container(
              padding: EdgeInsets.all(5),
              margin: EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      width: 0.5,
                      color: Colors.grey.shade400
                  )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(height: 15,),
                  CircleAvatar(backgroundColor: Colors.red.shade50,child: Icon(PhosphorIconsBold.megaphone,color: Colors.red,)),
                  SizedBox(height: 20,),
                  Text(widget.urgent.toString(),style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 20,),
                  Text("Urgent",style: TextStyle(color: Colors.grey),),
                  SizedBox(height: 10,),
                ],
              ),
            )),

            //Events
            Expanded(child:
            Container(
              padding: EdgeInsets.all(5),
              margin: EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      width: 0.5,
                      color: Colors.grey.shade400
                  )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(height: 15,),
                  CircleAvatar(backgroundColor: Colors.purple.shade50,child: Icon(Icons.calendar_today_outlined,color:Colors.purple,),),
                  SizedBox(height: 20,),
                  Text(widget.events.toString(),style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 20,),
                  Text("Events",style: TextStyle(color: Colors.grey),),
                  SizedBox(height: 10,),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Future<Object?>? getCount(String s, String t, String u) async {
  //   try{
  //     final result=await  Provider.of<DbService>(context, listen: false).dbref
  //         .collection("ins_admins")
  //         .doc(widget.insAdmin.id)
  //         .collection("institutes")
  //         .doc(widget.institute.id).collection("announcements")
  //         .where("type",isEqualTo:u).count().get();
  //     return result.count??0;
  //   }catch(e){
  //     print(e.toString());
  //     return null;
  //   }
  // }
  // Future<Object?>? getCount1(String s, String t) async {
  //   try{
  //     final result=await  Provider.of<DbService>(context, listen: false).dbref
  //         .collection("ins_admins")
  //         .doc(widget.insAdmin.id)
  //         .collection("institutes")
  //         .doc(widget.institute.id).collection("announcements")
  //         .count().get();
  //     return result.count??0;
  //   }catch(e){
  //     print(e.toString());
  //     return null;
  //   }
  // }
}
