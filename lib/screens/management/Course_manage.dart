import 'package:flutter/material.dart';

class CourseManage extends StatefulWidget {
  const CourseManage({super.key});

  @override
  State<CourseManage> createState() => _CourseManageState();
}

class _CourseManageState extends State<CourseManage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Courses"),
        centerTitle: true,
      ),
    );
  }
}
