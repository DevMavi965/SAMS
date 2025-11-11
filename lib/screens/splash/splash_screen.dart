import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void nextScreen()async{
   await Future.delayed(Duration(seconds: 5));
    await Navigator.pushReplacementNamed(context, '/login');
  }
  @override
  void initState() {

    super.initState();
    nextScreen();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(CupertinoIcons.alarm,size: 60,color: Colors.lightBlue,),
      ),
    );
  }
}
