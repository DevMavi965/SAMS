import 'package:flutter/material.dart';

class DepartManage extends StatefulWidget {
  const DepartManage({super.key});

  @override
  State<DepartManage> createState() => _DepartManageState();
}

class _DepartManageState extends State<DepartManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Departments"),
        centerTitle: true,
      ),
    );
  }
}
