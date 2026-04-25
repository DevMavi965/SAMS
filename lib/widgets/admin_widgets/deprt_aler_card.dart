import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/deprt_alert.dart';
class DeprtAlerCard extends StatefulWidget {
  final DepartmentalAlerts dept_alert;
  const DeprtAlerCard({super.key, required this.dept_alert});

  @override
  State<DeprtAlerCard> createState() => _DeprtAlerCardState();
}

class _DeprtAlerCardState extends State<DeprtAlerCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
                color: widget.dept_alert.type=="negative"?Colors.red:(widget.dept_alert.type=="positive"?Colors.green:Colors.blue),
                width: 4
            ),

          )
      ),
      child: ListTile(
        leading: Icon(PhosphorIconsBold.warningCircle,color: widget.dept_alert.type=="negative"?Colors.red:(widget.dept_alert.type=="positive"?Colors.green:Colors.blue),),
        title: Text(widget.dept_alert.content,style: TextStyle(fontWeight: FontWeight.w300),),
        subtitle: Text(getTimeAgo(widget.dept_alert.created_at, DateTime.now()),style: TextStyle(color: Colors.grey),),
      ),
    );
  }
  static String getTimeAgo(DateTime startTime, DateTime endTime) {
    Duration difference = endTime.difference(startTime);

    // Handle future dates
    if (difference.isNegative) {
      return 'in the future';
    }

    // Seconds
    if (difference.inSeconds < 60) {
      return 'just now';
    }

    // Minutes
    if (difference.inMinutes < 60) {
      int minutes = difference.inMinutes;
      return '$minutes min ago';
    }

    // Hours
    if (difference.inHours < 24) {
      int hours = difference.inHours;
      return '$hours hr ago';
    }

    // Days
    if (difference.inDays < 7) {
      int days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    }

    // Weeks
    if (difference.inDays < 30) {
      int weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    }

    // Months
    if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }

    // Years
    int years = (difference.inDays / 365).floor();
    return '$years year${years > 1 ? 's' : ''} ago';
  }
}
