import 'package:flutter/material.dart';

class LeaveManage extends StatefulWidget {
  const LeaveManage({super.key});

  @override
  State<LeaveManage> createState() => _LeaveManageState();
}

class _LeaveManageState extends State<LeaveManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Leave"),
        centerTitle: true,
      ),
    );
  }
}
