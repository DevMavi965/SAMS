import 'package:flutter/material.dart';

class InsAdminHome extends StatefulWidget {
  const InsAdminHome({super.key});

  @override
  State<InsAdminHome> createState() => _InsAdminHomeState();
}

class _InsAdminHomeState extends State<InsAdminHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ListView(
        children: [
          Text("Admin Dashboard",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
          SizedBox(height: 7,),
          Text("System Overview & Management",style: TextStyle(fontSize: 15,color: Colors.grey),),
        ],
      ))
    );
  }
}
