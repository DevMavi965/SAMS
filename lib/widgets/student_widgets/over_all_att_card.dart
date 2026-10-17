import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OverAllAttCard extends StatelessWidget {
  final int attended; // present plus late
  final int total; // since joining, leave excluded
  final int leaveDays;
  final double thisMonthPercent;
  final int thisMonthTotal;
  final double lastMonthPercent;

  const OverAllAttCard({
    super.key,
    required this.attended,
    required this.total,
    this.leaveDays = 0,
    this.thisMonthPercent = 0,
    this.thisMonthTotal = 0,
    this.lastMonthPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    // overall percentage, safe divide
    final double percentage = total > 0 ? (attended / total) * 100 : 0;
    final double progressValue = percentage / 100;

    final String lecturesText = "$attended of $total lectures since joining"
        "${leaveDays > 0 ? '  •  $leaveDays on leave' : ''}";

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // title and percentage row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Attendance",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lecturesText,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                "${percentage.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            minHeight: 12,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: const Color.fromARGB(50, 0, 153, 124),
            color: Theme.of(context).primaryColor,
          ),

          const SizedBox(height: 10),

          _buildMonthRow(),
        ],
      ),
    );
  }

  // this month trend row
  Widget _buildMonthRow() {
    if (thisMonthTotal == 0) {
      return Row(
        children: [
          Icon(CupertinoIcons.calendar, color: Colors.grey.shade500, size: 13),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              "No lectures counted this month yet",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // trend only with last month data
    final bool hasLast = lastMonthPercent > 0;
    final double change = thisMonthPercent - lastMonthPercent;
    final Color color = !hasLast
        ? Colors.grey.shade700
        : (change >= 0 ? Colors.green : Colors.red);

    final String text = hasLast
        ? "This month ${thisMonthPercent.toStringAsFixed(1)}%  "
        "(${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% vs last month)"
        : "This month ${thisMonthPercent.toStringAsFixed(1)}%";

    return Row(
      children: [
        Icon(
          !hasLast || change >= 0
              ? CupertinoIcons.arrow_up_right
              : CupertinoIcons.arrow_down_left,
          color: color,
          size: 13,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}