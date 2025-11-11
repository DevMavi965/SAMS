import 'package:flutter/material.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class Std_Announcement_card extends StatelessWidget {
  final Announcement ann;

  const Std_Announcement_card({super.key, required this.ann});

  @override
  Widget build(BuildContext context) {
    // Pick border color based on announcement type
    Color borderColor = ann.an_type == "urgent"
        ? Colors.red
        : ann.an_type == "event"
        ? Colors.blue
        : Colors.purple;

    return Container(
      decoration: BoxDecoration(
        color: ann.an_type == "urgent"
            ? Colors.red.shade100
            : ann.an_type == "event"
            ? Colors.blue.shade100
            : Colors.purple.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: borderColor, width: 4), // 👈 Left border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              children: [
                Icon(
                  PhosphorIcons.megaphoneSimple(),color: borderColor,
                  size: 15,fontWeight: FontWeight.bold,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    ann.an_title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Message text
            Text(
              ann.an_message,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
