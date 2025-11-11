import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OverAllAttCard extends StatelessWidget {
  final double thisMonth;
  final double lastMonth;
  final double totalDays;

  const OverAllAttCard({
    super.key,
    required this.thisMonth,
    required this.lastMonth,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    //  percentage
    double percentage = (thisMonth / totalDays) * 100;
    double change = percentage - lastMonth;

    // progress bar  0–1 value
    double progressValue = percentage / 100;

    return Container(
      height: 150,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔹 Top Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overall Attendance",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${thisMonth.toStringAsFixed(0)} of ${totalDays.toStringAsFixed(0)} days",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  "${percentage.toStringAsFixed(1)}%", //
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Progress bar
            LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 12,
              borderRadius: BorderRadius.circular(20),
              backgroundColor: const Color.fromARGB(50, 0, 153, 124),
              color: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: 8),

            // 🔹 Bottom text (trend)
            Row(
              children: [
                Icon(change>=0 ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_left,color:
                  change >= 0 ? Colors.green : Colors.red,size: 13,),
                 SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% from last month",
                    style: TextStyle(
                      fontSize: 10,
                      color: change >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis, //  gracefully clips long text
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
