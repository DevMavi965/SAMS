import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void nextScreen()async{
   await Future.delayed(Duration(seconds: 3));
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
        child:
        Column(

          children: [
            // SizedBox(
            //   height: 250,
            //   child: Stack(
            //     children: [
            //       Positioned(
            //         top: -50,
            //         right: -50,
            //         child: Container(
            //           width: 200,
            //         height: 200,
            //           decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(100),
            //           color: Color(0xff009988),
            //         ),),
            //       ),
            //       Positioned(
            //         top: -50,
            //         right: -50,
            //         child: Container(
            //           width: 160,
            //         height: 160,
            //           decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(100),
            //           color: Colors.green,
            //         ),),
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(flex: 3,
                child:SizedBox(),),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: 30,right: 30,top: 30,bottom: 10
                ),
                padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xff009988),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Lottie.asset("assets/anims/st.json")),
            ),
            Expanded(child: Text("SAMS",textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Color(0xff009988)),)),
            Expanded(child: SizedBox()),
          ],
        ) ,
      ),
    );
  }
}
