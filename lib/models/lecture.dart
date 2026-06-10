import 'package:flutter/material.dart';
import 'package:smas3/models/course.dart';

class LectureModel {
  String? id;
  DateTime dated;
  String course;
  TimeOfDay start_time,end_time;
  List<String>? students;//student ids here.
  List<String>? present;//student ids here.
  List<String>? absent;//student ids here.
  String room;
  String? status="upcoming";//upcoming,late,present,absent
  LectureModel({
    this.id,
    required this.course,
    required this.dated,
    required this.start_time,
    required this.end_time,
    required this.students,
    required this.present,
    required this.absent,
    required this.room,
    this.status,
});
}