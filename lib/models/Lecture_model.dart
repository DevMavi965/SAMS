import 'package:flutter/material.dart';

class Course{
  String name;
  String lecturer;
  String room;
  String status;//upcoming,late,present,absent
  DateTime time;
  Course({
    required this.name,
    required this.lecturer,
    required this.room,
    required this.time,
    required this.status
});
}