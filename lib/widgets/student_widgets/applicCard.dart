import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smas3/models/Leave_Application_Model.dart';

class LeaveApplicationCard extends StatelessWidget {
  final LeaveApplication leave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LeaveApplicationCard({
    super.key,
    required this.leave,
    this.onEdit,
    this.onDelete,
  });

  Color get _statusColor {
    switch (leave.status) {
      case "approved":
        return const Color(0xFF2E7D32);
      case "rejected":
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFEF6C00);
    }
  }

  IconData get _typeIcon {
    switch (leave.type) {
      case "Medical":
        return Icons.local_hospital_rounded;
      case "Emergency":
        return Icons.warning_amber_rounded;
      case "Academic":
        return Icons.school_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final days = leave.tillDate.difference(leave.fromDate).inDays + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // colored accent bar
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_typeIcon, size: 18, color: statusColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.type,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "$days day${days > 1 ? 's' : ''} • ${DateFormat('dd MMM').format(leave.fromDate)} - ${DateFormat('dd MMM yyyy').format(leave.tillDate)}",
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          leave.status[0].toUpperCase() + leave.status.substring(1),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    leave.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        "Applied ${DateFormat('dd MMM yyyy').format(leave.appliedDate)}",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                      if (leave.approvedby != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.verified_rounded, size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          "by ${leave.approvedby}",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                      const Spacer(),
                      if (onEdit != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
                          onPressed: onEdit,
                        ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFC62828)),
                          onPressed: onDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}