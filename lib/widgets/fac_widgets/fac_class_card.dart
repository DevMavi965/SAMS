import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/lecture.dart';

import '../../models/lecture.dart' show LectureModel;

class FacClassCard extends StatefulWidget {
  final LectureModel lectureModel;
  const FacClassCard({super.key, required this.lectureModel});

  @override
  State<FacClassCard> createState() => _FacClassCardState();
}

class _FacClassCardState extends State<FacClassCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 5,
        bottom: 10
      ),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              width: 0.5,
              color: Colors.grey
          )
      ),
      child: Column(
        children: [
          ListTile(
            leading:  Container(

              decoration: BoxDecoration(
                  color:Color.fromARGB(35, 0, 153, 136),
                  shape: BoxShape.circle
              ),
              child:
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(PhosphorIconsBold.calendarBlank,color: Theme.of(context).primaryColor,size: 25,),
              ),
            ),
            title: Text(widget.lectureModel.course!.name,style: TextStyle(fontSize: 14),),
            subtitle: Text("${widget.lectureModel.start_time.hour}:${widget.lectureModel.end_time.minute} - Room ${widget.lectureModel.room}",style: TextStyle(color: Colors.grey,fontSize: 12),),
            trailing: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: widget.lectureModel.status=="completed" ?Theme.of(context).primaryColor: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      width: 0.3,
                      color: Colors.grey
                  )
              ),
              child: Badge(
                backgroundColor: Colors.transparent,
                label: Text(widget.lectureModel.status!,style: TextStyle(color:widget.lectureModel.status=="completed"? Colors.white:Colors.black),),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              Text("Attendance ",style: TextStyle(color: Colors.grey,fontSize: 12),),
              Text("${widget.lectureModel.status=="upcoming" ?0:widget.lectureModel.present!.length}/${widget.lectureModel.students!.length} students",style: TextStyle(color: Colors.grey,fontSize: 12),)
            ],
          ),
          SizedBox(height: 10,),
          //progress bar
          Padding(
            padding: const EdgeInsets.only(
              left: 85,

            ),
            child: LinearProgressIndicator(
              minHeight: 10,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              borderRadius: BorderRadiusGeometry.circular(12),
              value:widget.lectureModel.status=="upcoming" ?0: widget.lectureModel.present!.length/widget.lectureModel.students!.length,
              valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
            ),
          ),
          //marked or not
          widget.lectureModel.status=="completed" ?SizedBox():Padding(
            padding: const EdgeInsets.only(
                left: 85,
                top: 10
            ),
            child: Container(
              height: 35,
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      width: 0.5,
                      color: Colors.grey
                  )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_center_focus,color: Colors.black,),
                  SizedBox(width: 5,),
                  Text("Mark Attendance",style: TextStyle(color: Colors.black),)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
