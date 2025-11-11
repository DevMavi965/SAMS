import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/widgets/in_Notif_model.dart';
class AlertTab extends StatefulWidget {
  final List<In_Notification> notifications;
  const AlertTab({super.key, required this.notifications});

  @override
  State<AlertTab> createState() => _AlertTabState();
}

class _AlertTabState extends State<AlertTab> {
  int unread_count=0;
  int countOfunread(){
    for(int i=0;i<widget.notifications.length;i++){
      if(!widget.notifications[i].is_read){
        unread_count++;
      }
    }
    return unread_count;
  }
  @override
  void initState() {
    unread_count=countOfunread();
    // TODO: implement initState
    super.initState();
  }
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
            ListTile(
              title: Text("Notifications",style: TextStyle(fontSize: 21,fontWeight: FontWeight.bold),),
              subtitle: Text("$unread_count unread messages",style: TextStyle(color: Colors.grey),),
              trailing: InkWell(
                onTap: (){
                setState(() {
                  for(int i=0;i<widget.notifications.length;i++){
                    widget.notifications[i].is_read=true;
                  }
                  unread_count=0;
                });
                },
                child: Badge(

                  backgroundColor: Colors.white,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey,
                        width: 0.7,
                      )
                    ),
                    child: Text("Mark all as read",style: TextStyle(fontWeight: FontWeight.w600,fontSize: 10),),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20,),
            Row(
              children: [

                   Text("New",style: TextStyle(fontWeight: FontWeight.w700),),
                   SizedBox(width: 10,),
                   Badge(
                    backgroundColor: Colors.green,
                    label: Text("$unread_count"),
                  ),

              ],
            ),
            SizedBox(height: 10,),
            //notifications
            for(int i=0;i<widget.notifications.length;i++)...[
              if(!widget.notifications[i].is_read)
                Notif_card(widget.notifications[i]),

            ]
            ,
            SizedBox(height: 10,),
            Row(
              children: [

                Text("Earlier",style: TextStyle(fontWeight: FontWeight.w700),),



              ],
            ),
            SizedBox(height: 10,),
            for(int i=0;i<widget.notifications.length;i++)...[
              if(widget.notifications[i].is_read)
                Notif_card(widget.notifications[i]),

            ]
          ],
        ),
      ),
    );
  }

  Widget Notif_card(In_Notification in_notif){
    return InkWell(
      onTap: (){
        setState(() {
          in_notif.is_read=true;
          unread_count--;
        });
      },
      child: Opacity(
        opacity: in_notif.is_read?0.6:1,
        child: Container(

          margin: EdgeInsets.only(
            bottom: 8
          ),
          height: 105,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              width: 0.8,
              color: Colors.grey
            )
          ),
          child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(

                height:40,
                width: 40,
                decoration: BoxDecoration(
                  color:in_notif.type=="upcoming"?Colors.purple.shade500:(in_notif.type=="good"?Colors.green.shade500:in_notif.type=="warning"?Colors.orange.shade500:Colors.blue.shade500),
                  shape: BoxShape.circle
                ),
                child:in_notif.type=="good"?Icon(PhosphorIconsBold.shootingStar,color: Colors.white,size: 17,):(in_notif.type=="warning"?Icon(CupertinoIcons.exclamationmark_octagon,size: 17,color: Colors.white,):(in_notif.type=="upcoming"?Icon(PhosphorIconsBold.calendarBlank,size: 17,color:
                Colors.white,): Icon(CupertinoIcons.checkmark_circle,color: Colors.white,))),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(in_notif.title,style: TextStyle(fontWeight: FontWeight.w600),),
                  Expanded(child: Text(in_notif.body,maxLines: 2,overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.grey,fontSize: 12),)),
                  Text(in_notif.time)
                ],
              ),
             in_notif.is_read?SizedBox(): Icon(Icons.circle,size: 10,color: Colors.green,)
            ],
          ),
        ),
      ),
    );
  }
}
