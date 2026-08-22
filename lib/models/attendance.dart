import 'package:flutter/material.dart';

class Attendance {
  String status="absent";
  String? method;
  TimeOfDay? checkin,checkout;
  bool? mid_point=false;//mid-point to be added lastly
}
