import 'package:flutter/material.dart';

class TimetableMng extends StatefulWidget {
  const TimetableMng({super.key});

  @override
  State<TimetableMng> createState() => _TimetableMngState();
}

class _TimetableMngState extends State<TimetableMng> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Timetable"),
        centerTitle: true,
      ),
    );
  }
}
