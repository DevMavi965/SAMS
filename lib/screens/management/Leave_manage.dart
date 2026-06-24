import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/db_service.dart';
import 'package:smas3/widgets/fac_widgets/fac_leave_accp_record.dart';

import '../../models/Leave_Application_Model.dart';

class Leave_manage_r extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const Leave_manage_r({super.key, required this.insAdmin, required this.institute});

  @override
  State<Leave_manage_r> createState() => _Leave_manage_rState();
}

class _Leave_manage_rState extends State<Leave_manage_r> {
  List<String> appTypes = [ "pending","reviewed"];
  int selected = 0;
  List<LeaveApplication> leaveApplications = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leave Management",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        children: [
          SizedBox(height: 20),
          StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
              .collection("ins_admins").doc(widget.insAdmin.id)
              .collection("institutes").doc(widget.institute.id)
              .collection("leave_applications")
              .snapshots(), builder:(context,snapshot){
            if(snapshot.connectionState==ConnectionState.waiting){
              return Center(
                child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Lottie.asset("assets/anims/an1.json")),
              );
            }else if(snapshot.hasError){
              return Center(child: Text("Error"),);
            }else if(!snapshot.hasData){
              return Center(child: Text("no data"),);
            }else if(snapshot.hasData){
              if(snapshot.data!.docs.isEmpty){
                return FacLeaveAcceptanceRecord(approved: 0, pending: 0, rejected: 0);
              }
              leaveApplications.clear();
              for(var doc in snapshot.data!.docs){
                leaveApplications.add(
                    LeaveApplication(
                      id: doc.id,
                      appliedDate: doc['applied_date'].toDate(),
                      type: doc['type'],
                      fromDate:doc['start_date'].toDate(),
                      tillDate: doc['end_date'].toDate(),
                      reason: doc['reason'],
                      status: doc['status'],
                      std_name: doc['student_name'],
                      std_id: doc['student_id'],
                      approvedby: doc['approved_by'],
                    )
                );
              }
              int approved=leaveApplications.where((element) => element.status=="approved").length;
              int pending=leaveApplications.where((element) => element.status=="pending").length;
              int rejected=leaveApplications.where((element) => element.status=="rejected").length;
              return FacLeaveAcceptanceRecord(approved: approved, pending: pending, rejected: rejected);
            }
            return SizedBox();
          }),
          // FacLeaveAcceptanceRecord(approved: 3, pending: 2, rejected: 1),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border.all(
                width: 0.5,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < 2; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selected = i;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.all(2),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected == i
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            width: selected == i ? 0 : 0,
                            color: selected == i
                                ? Colors.transparent
                                : Colors.transparent,
                          ),
                        ),
                        child: SizedBox(
                          width: 130,
                          child: Text(
                            appTypes[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10),
          StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
              .collection("ins_admins").doc(widget.insAdmin.id)
              .collection("institutes").doc(widget.institute.id)
              .collection("leave_applications")
              .snapshots(), builder:(context,snapshot){
            if(snapshot.connectionState==ConnectionState.waiting){
              return Center(
                child: SizedBox(
                    height: 60,
                    width: 60,
                    child: Lottie.asset("assets/anims/an1.json")),
              );
            }else if(snapshot.hasError){
              return Center(child: Text("Error"),);
            }else if(!snapshot.hasData){
            return Center(child: Text("no data"),);
            }else if(snapshot.hasData){
              if(snapshot.data!.docs.isEmpty){
                return SizedBox(height: 100,);
              }
              leaveApplications.clear();
              for(var doc in snapshot.data!.docs){
                leaveApplications.add(
                  LeaveApplication(
                      id: doc.id,
                      appliedDate: doc['applied_date'].toDate(),
                      type: doc['type'],
                      fromDate:doc['start_date'].toDate(),
                      tillDate: doc['end_date'].toDate(),
                      reason: doc['reason'],
                      status: doc['status'],
                      std_name: doc['student_name'],
                      std_id: doc['student_id'],
                    approvedby: doc['approved_by'],
                  )
                );
              }
             return Container(
                padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 10
                ),
                child: Column(
                  children: [
                    if (selected == 0)
                      for (var application in leaveApplications)
                        if (application.status == "pending")
                          _buildFACLeaveApplicationCard(application),
                    if (selected == 1)
                      for (var application in leaveApplications)
                        if (application.status != "pending")
                          _buildFACLeaveApplicationCard(application),
                  ],
                ),
              );
            }
            return SizedBox();
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){
        Provider.of<DbService>(context,listen: false).addStudentLeaveApplication(context, widget.insAdmin.id!, widget.institute.id!,
        LeaveApplication(
            appliedDate: DateTime.now(),
            type: "medical",
            fromDate: DateTime.now(),
            tillDate: DateTime.now().add(Duration(days: 3)),
            reason: "this is reason",
            status: "pending",
            std_name: "sadia",
            std_id: "5650",
            approvedby: null
        )
        );
      },child: Icon(Icons.add),),
    );
  }

  Widget _buildFACLeaveApplicationCard(LeaveApplication leaveApplication) {

    return InkWell(
      onDoubleTap: (){
        Provider.of<DbService>(context,listen: false).removeStudentLeaveApplication(context, leaveApplication.id!);
      },
      child: Container(
        margin: EdgeInsets.only(top: 10, bottom: 7),
        height: leaveApplication.status == "pending" ? 230 : 190,
        // #D89A20
        decoration: BoxDecoration(
          color: leaveApplication.status == "rejected"
              ? Color.fromARGB(40, 255, 0, 0)
              : (leaveApplication.status == "approved"
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.brown.shade50),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: leaveApplication.status == "rejected"
                  ? Colors.red
                  : (leaveApplication.status == "approved"
                        ? Theme.of(context).primaryColor
                        : Colors.brown),
              width: 3,
            ),
          ),
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color:leaveApplication.status == "rejected"
                            ? Colors.red
                            : (leaveApplication.status == "approved"
                            ? Theme.of(context).primaryColor
                            : Colors.brown),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        RMFuncts.getFirstLetters(leaveApplication.std_name)
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: leaveApplication.status == "rejected"
                              ? Colors.red
                              : (leaveApplication.status == "approved"
                              ? Theme.of(context).primaryColor
                              : Colors.brown),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leaveApplication.std_name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        leaveApplication.std_id,
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            "${leaveApplication.type} Leave",
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(width: 35),
                        ],
                      ),
                    ],
                  ),
                  Spacer(),

                  Icon(
                    leaveApplication.status == "rejected"
                        ? CupertinoIcons.xmark_circle
                        : (leaveApplication.status == "pending"
                              ? CupertinoIcons.clock
                              : Icons.check_circle_outline),
                    color: leaveApplication.status == "rejected"
                        ? Colors.red
                        : (leaveApplication.status == "approved"
                              ? Theme.of(context).primaryColor
                              : Colors.brown),
                    size: 25,
                  ),
                ],
              ),

              Row(
                children: [
                  SizedBox(width: 67),
                  Text(
                    "${DateFormat('dd MMM yyyy').format(leaveApplication.fromDate)}  -  ${DateFormat('dd MMM yyyy').format(leaveApplication.tillDate)}",
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 67),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      leaveApplication.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: leaveApplication.status == "rejected"
                            ? Colors.red
                            : (leaveApplication.status == "approved"
                                  ? Theme.of(context).primaryColor
                                  : Colors.brown),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 67),
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.black87,
                    size: 13,
                  ),
                  SizedBox(width: 5),
                  Text(
                    "applied ${DateFormat('dd-MMM-yyyy').format(leaveApplication.appliedDate)}",
                    style: TextStyle(color: Colors.black87, fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 5),
              leaveApplication.status == "pending"
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(120, 35),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            Provider.of<DbService>(context,listen: false).approveStudentLeaveApplication(context, leaveApplication, widget.insAdmin.name);
                          },
                          icon: Icon(
                            CupertinoIcons.checkmark_circle,
                            color: Colors.white,
                            size: 13,
                          ),
                          label: Text(
                            "Approve",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(120, 35),
                            backgroundColor: Colors.red.shade400,
                          ),
                          onPressed: () {
                            Provider.of<DbService>(context,listen: false).rejectStudentLeaveApplication(context, leaveApplication, widget.insAdmin.name);
                          },
                          icon: Icon(
                            CupertinoIcons.xmark_circle,
                            color: Colors.white,
                            size: 13,
                          ),
                          label: Text(
                            "Reject",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        SizedBox(),
                        Text("Reviewed by: ${leaveApplication.approvedby}",style: TextStyle(color: Theme.of(context).primaryColor,fontSize: 12),),
                        Badge(
                          padding: EdgeInsets.all(5),
                          label: Text(
                            leaveApplication.status,
                            style: TextStyle(color: Colors.white, fontSize: 9),
                          ),
                          backgroundColor: leaveApplication.status == "rejected"
                              ? Colors.red
                              : (leaveApplication.status == "approved"
                                    ? Theme.of(context).primaryColor
                                    : Colors.brown),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
