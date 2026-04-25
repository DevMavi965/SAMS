import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DepartAttCard extends StatefulWidget {
  final Map<String,dynamic> department;
  const DepartAttCard({super.key, required this.department});

  @override
  State<DepartAttCard> createState() => _DepartAttCardState();
}

class _DepartAttCardState extends State<DepartAttCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.grey.shade400,
              width: 0.5
          )
      ),
      margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
      padding: EdgeInsets.symmetric(horizontal: 10,vertical: 3),
      child: Column(
        children: [
          SizedBox(height: 10,),
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).primaryColor.withAlpha(60),
              child: Icon(PhosphorIconsBold.buildingApartment,color: Theme.of(context).primaryColor,),
            ),
            title: Text(widget.department['name']),
            subtitle: Text("${widget.department['total_students']} Students"),
            trailing: Badge(label: Text("${widget.department['attendence']}%"),backgroundColor: Theme.of(context).primaryColor,),
          ),
          SizedBox(height: 20,),
          LinearProgressIndicator(
            borderRadius: BorderRadius.circular(3),
            minHeight: 7,
            value: widget.department['attendence']/100,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 15,),

        ],
      ),
    );
  }
}
