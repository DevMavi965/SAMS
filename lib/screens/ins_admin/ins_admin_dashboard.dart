import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';

import '../../services/db_service.dart';

class InsAdminDashboard extends StatefulWidget {
  final InsAdmin insAdmin;
  const InsAdminDashboard({super.key, required this.insAdmin});

  @override
  State<InsAdminDashboard> createState() => _InsAdminDashboardState();
}

class _InsAdminDashboardState extends State<InsAdminDashboard> {
  logout()async{
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ins Admin Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
          setState(() {
           logout();
          });
          }, icon: Icon(Icons.logout))
        ],
      ),
      body: Center(child: Text(widget.insAdmin.name),),
      floatingActionButton: FloatingActionButton(onPressed: (){
        Provider.of<DbService>(context,listen: false).addInsAdmin(context,widget.insAdmin);
      },child: Icon(Icons.add),),
    );
  }
}
