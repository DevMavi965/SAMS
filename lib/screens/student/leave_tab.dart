import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/Leave_Application_Model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/widgets/student_widgets/leave_acceptance_record.dart';

import '../../models/department.dart';
import '../../models/institute.dart';
import '../../models/semester.dart';
import '../../models/session.dart';
import '../../services/db_service.dart';
import '../../widgets/student_widgets/applicCard.dart';
import 'leave_app_form.dart';

class LeaveTab extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;
  final Student student;
  const LeaveTab({
    super.key,
    required this.student,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.session,
    required this.semester,
  });

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab> {
  void _openForm({LeaveApplication? existingLeave}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeaveApplicationFormScreen(
          student: widget.student,
          existingLeave: existingLeave,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(LeaveApplication leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Leave Application"),
        content: const Text(
            "Are you sure you want to delete this leave application? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted && leave.id != null) {
      await Provider.of<DbService>(context, listen: false)
          .removeStudentLeaveApplication(context, leave.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: ListView(
        children: [
          SizedBox(
            height: 100,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Leave Applications",
                        style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    SizedBox(height: 7),
                    Text("Request time off from classes",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 10),
                    Transform.scale(
                      scale: 0.8,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _openForm(),
                        label: const Text("Apply"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StreamBuilder(
            stream: Provider.of<DbService>(context, listen: false)
                .dbref
                .collection("ins_admins")
                .doc(widget.student.insAdminId)
                .collection("institutes")
                .doc(widget.student.instituteId)
                .collection("leave_applications")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("error"));
              }
              if (snapshot.hasData) {
                List<LeaveApplication> leaveApplications = [];
                for (var leave in snapshot.data!.docs) {
                  leaveApplications.add(LeaveApplication(
                    appliedDate: leave['applied_date'].toDate(),
                    type: leave['type'],
                    fromDate: leave['start_date'].toDate(),
                    tillDate: leave['end_date'].toDate(),
                    reason: leave['reason'],
                    status: leave['status'],
                    std_name: leave['student_name'],
                    std_id: leave['student_id'],
                  ));
                }
                final approved =
                    leaveApplications.where((e) => e.status == "approved").length;
                final pending =
                    leaveApplications.where((e) => e.status == "pending").length;
                final rejected =
                    leaveApplications.where((e) => e.status == "rejected").length;
                return LeaveAcceptanceRecord(
                    approved: approved, pending: pending, rejected: rejected);
              }
              return const LeaveAcceptanceRecord(
                  approved: 0, pending: 0, rejected: 0);
            },
          ),
          const SizedBox(height: 20),
          StreamBuilder(
            stream: Provider.of<DbService>(context, listen: false)
                .dbref
                .collection("ins_admins")
                .doc(widget.student.insAdminId)
                .collection("institutes")
                .doc(widget.student.instituteId)
                .collection("leave_applications")
                .where("student_id", isEqualTo: widget.student.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("error"));
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text("No leave applications yet",
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                );
              }

              List<LeaveApplication> leaveApplications =
              snapshot.data!.docs.map((leave) {
                return LeaveApplication(
                  id: leave.id,
                  appliedDate: leave['applied_date'].toDate(),
                  type: leave['type'],
                  fromDate: leave['start_date'].toDate(),
                  tillDate: leave['end_date'].toDate(),
                  reason: leave['reason'],
                  status: leave['status'],
                  std_name: leave['student_name'],
                  std_id: leave['student_id'],
                  approvedby: leave.data().toString().contains('approved_by')
                      ? leave['approved_by']
                      : null,
                );
              }).toList()
                ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  const Text("My Leave Applications",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leaveApplications.length,
                    itemBuilder: (context, index) {
                      final leave = leaveApplications[index];
                      final isPending = leave.status == "pending";
                      return LeaveApplicationCard(
                        leave: leave,
                        onEdit: isPending
                            ? () => _openForm(existingLeave: leave)
                            : null,
                        onDelete: isPending ? () => _confirmDelete(leave) : null,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}