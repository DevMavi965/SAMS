import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smas3/widgets/fac_widgets/fac_leave_accp_record.dart';

import '../../models/Leave_Application_Model.dart';
class FacLeaveTab extends StatefulWidget {
  const FacLeaveTab({super.key});

  @override
  State<FacLeaveTab> createState() => _FacLeaveTabState();
}

class _FacLeaveTabState extends State<FacLeaveTab> {
  List<String> appTypes = ["pending", "reviwed"];
  int selected=0;
  List<LeaveApplication> leaveApplications = [
    LeaveApplication(type: "medical", reason: "sick", fromDate: "10/12/2025", tillDate: "13/12/2025", status: "pending", appliedDate: "9/12/2025",std_name: "ahmed",std_id: 12234),
    LeaveApplication(type: "emergency", reason: "sick", fromDate: "10/12/2025", tillDate: "13/12/2025", status: "approved", appliedDate: "9/12/2025",std_name: "Hafsa",std_id: 12234),
  ];
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Leave Management",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 7),
            Text(
              "Review student leave applications",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 10,),
        FacLeaveAcceptanceRecord(approved: 3, pending: 2, rejected: 1),
        SizedBox(height: 15,),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.7),
            border: Border.all(
              width: 0.5,
              color: Theme.of(context).primaryColor.withOpacity(0.1)
            ),
            borderRadius: BorderRadius.circular(15)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for(int i=0;i<2;i++)
                InkWell(
                  onTap: (){
                    setState(() {
                      selected=i;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(2),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:selected==i ?Colors.white:Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            width: selected==i ?0:0,
                            color: selected==i ?Colors.transparent:Colors.transparent
                        )
                    ),
                    child: SizedBox(
                        width: 130,
                        child: Text(appTypes[i],style: TextStyle(fontWeight: FontWeight.w500,fontSize: 15),textAlign: TextAlign.center,)),
                  ),
                )
            ],
          ),
        ),
        SizedBox(height: 10,),
        if(selected==0)
         for(var application in leaveApplications)
          if(application.status=="pending")
            _buildFACLeaveApplicationCard(application),
        if(selected==1)
         for(var application in leaveApplications)
          if(application.status!="pending")
            _buildFACLeaveApplicationCard(application),


      ],
    );
  }
  Widget _buildFACLeaveApplicationCard(LeaveApplication leaveApplication){
    return  Container(
      margin: EdgeInsets.only(
          top: 10,
          bottom: 7
      ),
      height: leaveApplication.status=="pending"?230:190,
      // #D89A20
      decoration: BoxDecoration(
          color: leaveApplication.status=="rejected"?Color.fromARGB(40, 255, 0, 0):
          (leaveApplication.status=="approved"?Color.fromARGB(40, 0, 153, 136):
          Colors.brown.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: leaveApplication.status=="rejected"?Colors.red:
            (leaveApplication.status=="approved"?Color.fromARGB(255, 0, 153, 136):
            Colors.brown),
            width: 0.4,

          )
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color:Colors.white,
                      shape: BoxShape.circle,
                      border:Border.all(
                          width: 2,
                          color: Theme.of(context).primaryColor
                      )
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${leaveApplication.std_name[0]}${leaveApplication.std_name[1]}".toUpperCase(),textAlign: TextAlign.center,style: TextStyle(fontSize: 20,fontWeight: FontWeight.w400,color: Theme.of(context).primaryColor),),
                  ),
                ),
                SizedBox(width: 20,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${leaveApplication.std_name}",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16),),
                    Text("${leaveApplication.std_id}",style: TextStyle(color: Colors.grey),),
                    SizedBox(height: 5,),
                    Row(
                      children: [
                        Text("${leaveApplication.type} Leave",style: TextStyle(fontSize: 14),),
                        SizedBox(width: 35,),

                      ],
                    ),
                  ],
                ),
                Spacer(),
                Icon(leaveApplication.status=="rejected"?CupertinoIcons.xmark_circle:(leaveApplication.status=="pending"?CupertinoIcons.clock:Icons.check_circle_outline),
                  color:leaveApplication.status=="rejected"?Colors.red:
                  (leaveApplication.status=="approved"?Color.fromARGB(255, 0, 153, 136):
                  Colors.brown) ,size: 25,),
              ],
            ),

            Row(
              children: [
                SizedBox(width: 67,),
                Text("${leaveApplication.fromDate} - ${leaveApplication.tillDate}",style: TextStyle(color: Colors.grey,fontSize: 12),),
              ],
            ),
            SizedBox(height: 10,),
            Row(
              children: [
                SizedBox(width: 67,),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(leaveApplication.reason,maxLines: 1,overflow: TextOverflow.ellipsis,style: TextStyle(color: leaveApplication.status=="rejected"?Colors.red:
                  (leaveApplication.status=="approved"?Color.fromARGB(255, 0, 153, 136):
                  Colors.brown))),
                ),
              ],
            ),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 67,),
                Icon(Icons.calendar_today_outlined,color: Colors.grey,size: 13,),
                SizedBox(width: 5,),
                Text("applied ${leaveApplication.appliedDate}",style: TextStyle(color: Colors.grey,fontSize: 12),),
              ],
            ),
            SizedBox(height: 5,),
            leaveApplication.status=="pending"?
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(120, 35),
                    backgroundColor: Theme.of(context).primaryColor,
                      ),
                  onPressed: (){
                  setState(() {
                    leaveApplication.status="approved";
                  });

                },
                  icon: Icon(CupertinoIcons.checkmark_circle,color: Colors.white,size: 13,),
                    label: Text("Approve",style: TextStyle(color: Colors.white,fontSize: 10),),)
               ,ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(120, 35),
                    backgroundColor:Colors.red.shade400,
                  ),
                  onPressed: (){
                    setState(() {
                      leaveApplication.status="rejected";
                    });

                  },
                  icon: Icon(CupertinoIcons.xmark_circle,color: Colors.white,size: 13,),
                  label: Text("Reject",style: TextStyle(color: Colors.white,fontSize: 12),),)
              ],
            ):
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                Badge(
                  padding: EdgeInsets.all(5),
                  label: Text(leaveApplication.status,style: TextStyle(color: Colors.white,fontSize: 9),),
                  backgroundColor: leaveApplication.status=="rejected"?Colors.red:
                  (leaveApplication.status=="approved"?Color.fromARGB(255, 0, 153, 136):
                  Colors.brown),

                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
