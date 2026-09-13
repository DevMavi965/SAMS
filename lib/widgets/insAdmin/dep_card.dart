import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../maxins/rm_functions.dart';
import '../../models/department.dart';

Widget DepartmentCard({
  required BuildContext context,
  required Department department}) {
  final primary = Theme.of(context).primaryColor;
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                RMFuncts.getFirstLetters(department.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    department.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(CupertinoIcons.person_crop_circle, color: Colors.grey.shade500, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          department.hod_name,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, color: Colors.grey.shade400, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat("dd MMM yyyy").format(department.created_at!),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Menu
            SizedBox()
          ],
        ),
      ),
    ),
  );
}