import 'package:flutter/material.dart';
import 'package:smas3/models/admin_model.dart';

class AdminDeshboard extends StatefulWidget {
  final Admin admin;
  const AdminDeshboard({super.key, required this.admin});

  @override
  State<AdminDeshboard> createState() => _AdminDeshboardState();
}

class _AdminDeshboardState extends State<AdminDeshboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dr.${widget.admin.name}"),
        centerTitle: true,
      ),
      body: Center(child: Text(widget.admin.email),),
    );
  }
}
