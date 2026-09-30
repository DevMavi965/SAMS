import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AttRecCard extends StatelessWidget {
  final int present_days, late_days, absent_days, leave_days;
  const AttRecCard({
    super.key,
    required this.present_days,
    required this.late_days,
    required this.absent_days,
    this.leave_days = 0,
  });

  @override
  Widget build(BuildContext context) {
    // total for share bars
    final total = present_days + late_days + absent_days + leave_days;

    return Row(
      spacing: 8,
      children: [
        _RecTile(
          icon: CupertinoIcons.checkmark_alt_circle_fill,
          color: Theme.of(context).primaryColor,
          count: present_days,
          total: total,
          label: "Present",
        ),
        _RecTile(
          icon: CupertinoIcons.clock_fill,
          color: Colors.brown,
          count: late_days,
          total: total,
          label: "Late",
        ),
        _RecTile(
          icon: CupertinoIcons.xmark_circle_fill,
          color: Colors.red,
          count: absent_days,
          total: total,
          label: "Absent",
        ),
        _RecTile(
          icon: PhosphorIconsBold.airplaneTakeoff,
          color: Colors.blue,
          count: leave_days,
          total: total,
          label: "Leave",
        ),
      ],
    );
  }
}

// single stat tile
class _RecTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final int total;
  final String label;

  const _RecTile({
    required this.icon,
    required this.color,
    required this.count,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final double share = total > 0 ? count / total : 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // soft tinted background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.14), color.withOpacity(0.03)],
          ),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // round icon badge
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),

            // animated count-up number
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: count.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                value.round().toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // share of total bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 5, color: color.withOpacity(0.15)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: share),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(height: 5, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}