import 'package:flutter/material.dart';

class AnnManage extends StatefulWidget {
  const AnnManage({super.key});

  @override
  State<AnnManage> createState() => _AnnManageState();
}

class _AnnManageState extends State<AnnManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Announcements"),
        centerTitle: true,
      ),
    );
  }
}
