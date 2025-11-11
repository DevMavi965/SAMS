import 'package:flutter/material.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
class FacPersonalInfoCard extends StatefulWidget {
  final Lecturer lecturer;
  const FacPersonalInfoCard({super.key, required this.lecturer});

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
                          Text("Employee ID",style: TextStyle(color: Colors.grey),),
                          Text(widget.lecturer.E_id),
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
                          Text("${widget.lecturer.courses.length} Active Courses"),
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
