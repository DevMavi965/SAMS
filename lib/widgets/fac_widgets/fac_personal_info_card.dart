import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../services/db_service.dart';
class FacPersonalInfoCard extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const FacPersonalInfoCard({super.key, required this.lecturer, required this.insAdmin, required this.institute, required this.department});

  @override
  State<FacPersonalInfoCard> createState() => _FacPersonalInfoCardState();
}

class _FacPersonalInfoCardState extends State<FacPersonalInfoCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      // height: 265,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey,
          width: 0.2,
        ),
      ),
      child:
      Table(
        border:
        TableBorder.all(
          color: Colors.grey,
          width: 0.2,
        ),
        children: [
          //email
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.email_outlined,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email",style: TextStyle(color: Colors.grey),),
                          Text(widget.lecturer.email),
                        ],
                      )
                    ],
                  ),
                )
              ]
          ),
          //phone
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone_outlined,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone",style: TextStyle(color: Colors.grey),),
                          Text(widget.lecturer.phone),
                        ],
                      )
                    ],
                  ),
                )
              ]
          ),
          //course enrolled date
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(PhosphorIconsBold.user,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Designation",style: TextStyle(color: Colors.grey),),
                          Text(widget.lecturer.role),
                        ],
                      )
                    ],
                  ),
                )
              ]
          ),
          //semester current
          TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.menu_book_sharp,size: 25,color: Theme.of(context).primaryColor,),
                      ),
                      SizedBox(width: 10,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Courses Teaching",style: TextStyle(color: Colors.grey),),
                          FutureBuilder(future: Provider.of<DbService>(context, listen: false).indexDoc
                              .where("type", isEqualTo: "course")
                              .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
                              .where("institute_id", isEqualTo: widget.institute.id)
                              .where("department_id", isEqualTo: widget.department.id)
                              .where("lecturer_id", isEqualTo: widget.lecturer.id).get(),
                              builder: (context,snapshot){
                                if(snapshot.connectionState==ConnectionState.waiting){
                                  return Text("Loading...");
                                }else if(snapshot.hasError){
                                  return Text("Error: ${snapshot.error}");
                                }else if(!snapshot.hasData || snapshot.data!.docs.isEmpty){
                                  return Text("No courses assigned to you");
                                }
                                final indexDocs = snapshot.data!.docs
                                    .map((doc) => {...doc.data(), 'id': doc.id})
                                    .toList();
                                return Text("${indexDocs.length} active courses");
                              })
                        ],
                      )
                    ],
                  ),
                )
              ]
          )
        ],
      ),
    );
  }
}
