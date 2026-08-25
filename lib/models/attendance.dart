import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Attendance {
  final String sid;
  final String status;
  final String? method;
  final TimeOfDay? checkin, checkout;
  final bool? mid_point;

  Attendance({
    required this.sid,
    required this.checkin,
    required this.checkout,
    required this.mid_point,
    required this.method,
    required this.status,
  });

  // onDate anchors the bare TimeOfDay to a real calendar day so it can
  // be stored as a Firestore Timestamp. Pass the lecture's date.
  Map<String, dynamic> toMap({required DateTime onDate}) {
    Timestamp? combine(TimeOfDay? t) {
      if (t == null) return null;
      return Timestamp.fromDate(
        DateTime(onDate.year, onDate.month, onDate.day, t.hour, t.minute),
      );
    }
    return {
      'sid': sid,
      'checkin': combine(checkin),
      'checkout': combine(checkout),
      'mid_point': mid_point,
      'method': method,
      'status': status,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    TimeOfDay? fromTs(dynamic ts) {
      if (ts == null) return null;
      final dt = (ts as Timestamp).toDate();
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    return Attendance(
      sid: map['sid'] as String,
      checkin: fromTs(map['checkin']),
      checkout: fromTs(map['checkout']),
      mid_point: map['mid_point'] as bool?,
      method: map['method'] as String?,
      status: map['status'] as String,
    );
  }
}