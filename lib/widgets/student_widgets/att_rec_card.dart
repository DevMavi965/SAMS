import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
class AttRecCard extends StatelessWidget {
  final int present_days,late_days,absent_days;
  const AttRecCard({super.key, required this.present_days, required this.late_days, required this.absent_days});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: 100,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey,
                  width: 0.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.checkmark_circle,color: Theme.of(context).primaryColor,size: 30,),
                  Text(present_days.toString(),style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
                  Text("Present",style: TextStyle(color: Colors.grey),)
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey,
                  width: 0.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.clock,color: Colors.brown,size: 30,),
                  Text(late_days.toString(),style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
                  Text("Late",style: TextStyle(color: Colors.grey),)
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey,
                  width: 0.4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.xCircle(),color:Colors.red,size: 30,),
                  Text(absent_days.toString(),style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
                  Text("Absent",style: TextStyle(color: Colors.grey),)
                ],
              ),
            ),

          )
        ],
      ),
    );
  }
}
