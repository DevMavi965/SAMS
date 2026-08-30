import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smas3/models/Leave_Application_Model.dart';

class LeaveSelectionCard extends StatefulWidget {
  final List<LeaveApplication> leaveApplications;

  const LeaveSelectionCard({super.key, required this.leaveApplications});

  @override
  State<LeaveSelectionCard> createState() => _LeaveSelectionCardState();
}

class _LeaveSelectionCardState extends State<LeaveSelectionCard> {
  bool check = true; // true = Pending, false = History

  List<LeaveApplication> pendingApplications(List<LeaveApplication> leaveApplications) {
    List<LeaveApplication> pendingA = [];
    for (int i = 0; i < leaveApplications.length; i++) {
      if (leaveApplications[i].status == "pending") {
        pendingA.add(leaveApplications[i]);
      }
    }
    return pendingA;
  }

  List<LeaveApplication> pendingleaveApplications = [];

  @override
  void initState() {
    pendingleaveApplications = pendingApplications(widget.leaveApplications);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        Container(
          width: 300,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Stack(
            children: [
              // Moving white box
              AnimatedAlign(
                alignment: check ? Alignment.centerLeft : Alignment.centerRight,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              // Text buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pending button (LEFT)
                  InkWell(
                    onTap: () {
                      setState(() {
                        check = true;
                      });
                    },
                    child: Container(
                      width: 140,
                      alignment: Alignment.center,
                      child: Text(
                        "Pending", // This should show Pending
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: check ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // History button (RIGHT)
                  InkWell(
                    onTap: () {
                      setState(() {
                        check = false;
                      });
                    },
                    child: Container(
                      width: 140,
                      alignment: Alignment.center,
                      child: Text(
                        "History", // This should show History
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: !check ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Display the correct list based on the toggle
        for (int i = 0; i < (check ? pendingleaveApplications.length : widget.leaveApplications.length); i++)
          _buildLeaveApplicationCard(
              check ? pendingleaveApplications[i] : widget.leaveApplications[i]
          ),
      ],
    );
  }

  Widget _buildLeaveApplicationCard(LeaveApplication leaveApplication) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 7),
      height: 150,
      decoration: BoxDecoration(
        color: leaveApplication.status == "rejected"
            ? Colors.red.shade100
            : (leaveApplication.status == "approved"
            ? const Color.fromARGB(60, 0, 153, 136)
            : Colors.brown.shade50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: leaveApplication.status == "rejected"
              ? Colors.red
              : (leaveApplication.status == "approved"
              ? const Color.fromARGB(255, 0, 153, 136)
              : Colors.brown),
          width: 0.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        leaveApplication.status == "rejected"
                            ? CupertinoIcons.xmark_circle
                            : (leaveApplication.status == "pending"
                            ? CupertinoIcons.clock
                            : Icons.check_circle_outline),
                        color: leaveApplication.status == "rejected"
                            ? Colors.red
                            : (leaveApplication.status == "approved"
                            ? const Color.fromARGB(255, 0, 153, 136)
                            : Colors.brown),
                        size: 25,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${leaveApplication.type} Leave",
                        style: const TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                  Badge(
                    padding: const EdgeInsets.all(5),
                    label: Text(
                      leaveApplication.status,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                    backgroundColor: leaveApplication.status == "rejected"
                        ? Colors.red
                        : (leaveApplication.status == "approved"
                        ? const Color.fromARGB(255, 0, 153, 136)
                        : Colors.brown),
                  )
                ],
              ),
            ),
            Flexible(
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Flexible(
                    child: Text(
                      "${leaveApplication.fromDate.day}/${leaveApplication.fromDate.month}/${leaveApplication.fromDate.year} to ${leaveApplication.tillDate.day}/${leaveApplication.tillDate.month}/${leaveApplication.tillDate.year}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 40),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    leaveApplication.reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: leaveApplication.status == "rejected"
                          ? Colors.red
                          : (leaveApplication.status == "approved"
                          ? const Color.fromARGB(255, 0, 153, 136)
                          : Colors.brown),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 40),
                const Icon(Icons.calendar_today_outlined,
                    color: Colors.grey, size: 13),
                const SizedBox(width: 5),
                Text(
                  "applied ${leaveApplication.appliedDate.day}/${leaveApplication.appliedDate.month}/${leaveApplication.appliedDate.year}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            leaveApplication.approvedby != null
                ? Row(
              children: [
                const SizedBox(width: 40),
                const Icon(Icons.person, color: Colors.grey, size: 13),
                const SizedBox(width: 5),
                Text(
                  leaveApplication.approvedby != null
                      ? "approved by ${leaveApplication.approvedby}"
                      : "pending",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )
              ],
            )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}