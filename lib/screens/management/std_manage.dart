import 'package:flutter/material.dart';

class StdManage extends StatefulWidget {
  const StdManage({super.key});

  @override
  State<StdManage> createState() => _StdManageState();
}

class _StdManageState extends State<StdManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("std manage"),
      ),
    );
  }
}
