import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smas3/models/Leave_Application_Model.dart';
class LeaveSelectionCard extends StatefulWidget {
  final List<LeaveApplication> leaveApplications;


  @override
  const LeaveSelectionCard({super.key, required this.leaveApplications});

  @override
  State<LeaveSelectionCard> createState() => _LeaveSelectionCardState();
}

class _LeaveSelectionCardState extends State<LeaveSelectionCard> {


  bool check = true;
List<LeaveApplication> pendingApplications(List<LeaveApplication> leaveApplications){
  List<LeaveApplication> pendingA = [];
  for (int i = 0; i < leaveApplications.length; i++) {
    if(leaveApplications[i].status == "pending"){
      pendingA.add(leaveApplications[i]);

    }
  }
 return pendingA;

}
  List<LeaveApplication> pendingleaveApplications = [];
@override
  void initState() {
  pendingleaveApplications = pendingApplications(widget.leaveApplications);

  // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20,),

        // Container(
        //   width: 300,
        //   decoration: BoxDecoration(
        //       color: Colors.grey.shade300,
        //       borderRadius: BorderRadius.circular(15),
        //       border: Border.all(
        //         color: Colors.grey,
        //         width: 1,
        //
        //       )
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       check?
        //       AnimatedContainer(
        //         duration: Duration(milliseconds: 1300),
        //         // height: 40,
        //         width: 140,
        //         margin: EdgeInsets.all(3),
        //         decoration: BoxDecoration(
        //             color: Colors.white,
        //             border: Border.all(
        //               color: Colors.grey,
        //               width: 1,
        //             ),
        //             borderRadius: BorderRadius.all(
        //               Radius.circular(15),
        //             )
        //         ),
        //         child: Padding(
        //           padding: const EdgeInsets.all(8.0),
        //           child: Text("Pending",textAlign: TextAlign.center,style: TextStyle(color: Colors.black),),
        //         ),
        //       ):
        //       InkWell(
        //         onTap: (){
        //           setState(() {
        //             check = !check;
        //           });
        //         },
        //         child: Container(
        //           // height: 40,
        //           width: 140,
        //           margin: EdgeInsets.all(3),
        //           decoration: BoxDecoration(
        //             // color: Colors.white,
        //               borderRadius: BorderRadius.all(
        //                 Radius.circular(15),
        //               )
        //           ),
        //           child: Padding(
        //             padding: const EdgeInsets.all(8.0),
        //             child: Text("Pending",textAlign: TextAlign.center,style: TextStyle(color: Colors.black),),
        //           ),
        //         ),
        //       ),
        //       check?
        //       InkWell(
        //         onTap: (){
        //           setState(() {
        //             check = !check;
        //           });
        //         },
        //         child: Container(
        //           // height: 40,
        //           width: 140,
        //           margin: EdgeInsets.all(3),
        //           decoration: BoxDecoration(
        //             // color: Colors.white,
        //               borderRadius: BorderRadius.all(
        //                 Radius.circular(15),
        //               )
        //           ),
        //           child: Padding(
        //             padding: const EdgeInsets.all(8.0),
        //             child: Text("History",textAlign: TextAlign.center,style: TextStyle(color: Colors.black),),
        //           ),
        //         ),
        //       ):
        //       AnimatedContainer(
        //         duration: Duration(milliseconds: 1300),
        //         // height: 40,
        //         width: 140,
        //         margin: EdgeInsets.all(3),
        //         decoration: BoxDecoration(
        //             color: Colors.white,
        //             border: Border.all(
        //               color: Colors.grey,
        //               width: 1,
        //             ),
        //             borderRadius: BorderRadius.all(
        //               Radius.circular(15),
        //             )
        //         ),
        //         child: Padding(
        //           padding: const EdgeInsets.all(8.0),
        //           child: Text("History",textAlign: TextAlign.center,style: TextStyle(color: Colors.black),),
        //         ),
        //       ),
        //
        //     ],
        //   ),
        // ),
        Container(
          width: 300,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Stack(
            children: [
              // 👇 This AnimatedAlign is the moving white box
              AnimatedAlign(
                alignment: check ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              // Text buttons on top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pending button
                  InkWell(
                    onTap: () {
                      setState(() {
                        check = true;
                      });
                    },
                    child: Container(
                      width: 140,
                      alignment: Alignment.center,
                      child: Text(
                        "History",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight:
                          check ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // History button
                  InkWell(
                    onTap: () {
                      setState(() {
                        check = false;
                      });
                    },
                    child: Container(
                      width: 140,
                      alignment: Alignment.center,
                      child: Text(
                        "Pending",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight:
                          !check ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20,),
         for (int i = 0; i < (check?widget.leaveApplications.length:pendingleaveApplications.length); i++)
           _buildLeaveApplicationCard(check?widget.leaveApplications[i]:pendingleaveApplications[i]),




      ],
    );
  }
  Widget _buildLeaveApplicationCard(LeaveApplication leaveApplication){
    return  Container(
      margin: EdgeInsets.only(
          top: 10,
          bottom: 7
      ),
      height: 130,
      // #D89A20
      decoration: BoxDecoration(
          color: leaveApplication.status=="rejected"?Colors.red.shade100:
          (leaveApplication.status=="approved"?Color.fromARGB(60, 0, 153, 136):
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(leaveApplication.status=="rejected"?CupertinoIcons.xmark_circle:(leaveApplication.status=="pending"?CupertinoIcons.clock:Icons.check_circle_outline),
                      color:leaveApplication.status=="rejected"?Colors.red:
                      (leaveApplication.status=="approved"?Color.fromARGB(255, 0, 153, 136):
                      Colors.brown) ,size: 25,),
                    SizedBox(width: 12,),
                    Text("${leaveApplication.type} Leave",style: TextStyle(fontSize: 17),),
                  ],
                ),
                // SizedBox(width: 2,),
                // SizedBox(width: 2,),
                Badge(
                  padding: EdgeInsets.all(5),
                  label: Text(leaveApplication.status,style: TextStyle(color: Colors.white,fontSize: 9),),
                  backgroundColor: leaveApplication.status=="rejected"?Colors.red:
                  (leaveApplication.status=="approved"?Color.fromARGB(255, 0, 153, 136):
                  Colors.brown),

                )
              ],
            ),
            Row(
              children: [
                SizedBox(width: 40,),
                Text("${leaveApplication.fromDate} - ${leaveApplication.tillDate}",style: TextStyle(color: Colors.grey,fontSize: 12),),
              ],
            ),
            SizedBox(height: 10,),
            Row(
              children: [
                SizedBox(width: 40,),
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
                SizedBox(width: 40,),
                Icon(Icons.calendar_today_outlined,color: Colors.grey,size: 13,),
                SizedBox(width: 5,),
                Text("applied ${leaveApplication.appliedDate}",style: TextStyle(color: Colors.grey,fontSize: 12),),
              ],
            )
          ],
        ),
      ),
    );
  }
}
