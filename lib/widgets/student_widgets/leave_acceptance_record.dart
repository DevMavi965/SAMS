import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
class LeaveAcceptanceRecord extends StatelessWidget {
  final int approved,pending,rejected;
  const LeaveAcceptanceRecord({super.key, required this.approved, required this.pending, required this.rejected});

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
              height: 160,
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
                  Text(approved.toString(),style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
                  Text("Approved",style: TextStyle(color: Colors.grey),)
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: 120,
              height: 160,
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
                  Text(pending.toString(),style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
                  Text("Pending",style: TextStyle(color: Colors.grey),)
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: 120,
              height: 160,
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
                  Text(rejected.toString(),style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
                  Text("Rejected",style: TextStyle(color: Colors.grey),)
                ],
              ),
            ),

          )
        ],
      ),
    );
  }
}
