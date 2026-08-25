import 'package:flutter/material.dart';
import 'package:smas3/models/attendance.dart';
import 'package:smas3/models/course.dart';

class LectureModel {
  String? id;
  DateTime dated;
  String course;
  TimeOfDay start_time,end_time;
  // Attendance attendance=Attendance(sid: "345678", checkin: TimeOfDay(hour: 6, minute: 30), checkout: TimeOfDay(hour: 7, minute: 00), mid_point: true, method: "fingerprint", status: "present")
  List<Attendance>? attendance;
  String room;
  String? status="upcoming";//upcoming,completed,ongoing,
  LectureModel({
    this.id,
    required this.course,
    required this.dated,
    required this.start_time,
    required this.end_time,
    required this.attendance,
    required this.room,
    this.status,
});
}

