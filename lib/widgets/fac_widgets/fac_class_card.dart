import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/lecture.dart';

import '../../models/lecture.dart' show LectureModel;

class FacClassCard extends StatefulWidget {
  final LectureModel lectureModel;
  const FacClassCard({super.key, required this.lectureModel});

  @override
  State<FacClassCard> createState() => _FacClassCardState();
}

class _FacClassCardState extends State<FacClassCard> {

  /// A student counts as present for this lecture if status is
  /// present/late AND a checkout was recorded — same rule used for the
  /// weekly stats — checked-in-but-never-checked-out does not count.
  int get _presentCount {
    final attendance = widget.lectureModel.attendance ?? [];
    return attendance
        .where((a) => (a.status == "present" || a.status == "late") && a.checkout != null)
        .length;
  }

  /// Total students this lecture has an attendance record for. This is the
  /// denominator for the percentage below — if you have a separate enrolled
  /// student count for the course, swap it in here instead so an upcoming
  /// no-shows still reduce the percentage correctly.
  int get _totalMarked {
    final attendance = widget.lectureModel.attendance ?? [];
    return attendance.length;
  }

  /// 0–100 percentage of marked students who are present, only meaningful
  /// once the lecture has actually started (ongoing/completed) — an
  /// upcoming lecture has no attendance yet, so it's always 0.
  num get _attendancePercentage {
    final status = RMFuncts.getliveStatus(
      widget.lectureModel.dated, widget.lectureModel.start_time, widget.lectureModel.end_time,
    );
    if (status == "upcoming") return 0;
    if (_totalMarked == 0) return 0;
    return (_presentCount / _totalMarked) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final liveStatus = RMFuncts.getliveStatus(
      widget.lectureModel.dated, widget.lectureModel.start_time, widget.lectureModel.end_time,
    );
    final percentage = _attendancePercentage;

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
                padding:  EdgeInsets.all(12.0),
                child: Icon(PhosphorIconsBold.calendarBlank,color: Theme.of(context).primaryColor,size: 25,),
              ),
            ),
            title: Text(widget.lectureModel.course,style: TextStyle(fontSize: 14),),
            // was: "${start_time.hour}:${end_time.minute}" — mixed start
            // hour with end minute. Now shows both times correctly.
            subtitle: Text(
              "${widget.lectureModel.start_time.hour.toString().padLeft(2, '0')}:${widget.lectureModel.start_time.minute.toString().padLeft(2, '0')}"
                  " - "
                  "${widget.lectureModel.end_time.hour.toString().padLeft(2, '0')}:${widget.lectureModel.end_time.minute.toString().padLeft(2, '0')}"
                  " - Room ${widget.lectureModel.room}",
              style: TextStyle(color: Colors.grey,fontSize: 12),
            ),
            trailing: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                  color: liveStatus=="ongoing"? Colors.red:(liveStatus=="completed" ?Theme.of(context).primaryColor: Colors.green),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      width: 0.3,
                      color: Colors.grey
                  )
              ),
              child: Badge(
                backgroundColor: Colors.transparent,
                label: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text(liveStatus,style: TextStyle(color:Colors.white),),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              Text("Attendance ",style: TextStyle(color: Colors.grey,fontSize: 12),),
              // was: hardcoded 807 with "%%%" typo. Now the real computed
              // percentage — no of present students shown once conducted.
              Text(
                liveStatus=="upcoming"
                    ? "0% students"
                    : "${percentage.toStringAsFixed(0)}% students ($_presentCount/$_totalMarked)",
                style: TextStyle(color: Colors.grey,fontSize: 12),
              )
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
              // was: hardcoded 455 — LinearProgressIndicator expects 0.0–1.0.
              // Now a real fraction derived from the same percentage above.
              value: liveStatus=="upcoming" ? 0 : (percentage / 100),
              valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
            ),
          ),
          //marked or not
          liveStatus=="ongoing" ?Padding(
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
          ):SizedBox(),
        ],
      ),
    );
  }
}