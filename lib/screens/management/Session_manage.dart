import 'package:flutter/material.dart';

class SessionManage extends StatefulWidget {
  const SessionManage({super.key});

  @override
  State<SessionManage> createState() => _SessionManageState();
}

class _SessionManageState extends State<SessionManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Sessions"),
        centerTitle: true,
      ),
    );
  }
}
