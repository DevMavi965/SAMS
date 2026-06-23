import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smas3/screens/ins_admin/ins_selection.dart';

import '../../models/admin_model.dart';
import '../../models/fac_model.dart';
import '../../models/ins_admin.dart';
import '../../models/student_model.dart';
import '../admin/admin_deshboard.dart';
import '../faculty/fac_deshboard.dart';
import '../ins_admin/ins_admin_dashboard.dart';
import '../student/stdudent_deshboard.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final dbRef=FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB");
final indexDoc=FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("index");
final auth=FirebaseAuth.instance;
  void nextScreen()async{
    await Future.delayed(Duration(seconds: 3));
    
    if(auth.currentUser!=null){
      final dox=await indexDoc.doc(auth.currentUser!.uid).get();
      if(dox.exists==false){
        await Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      String role=dox['role'];
        if(role=="ins_admin"){
        final v =await dbRef.collection("ins_admins").doc(auth.currentUser!.uid).get();
        if(!v.exists){
          await Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        InsAdmin insAdmin = InsAdmin(
            id: v.id,
            role: v['role'],
            name: v["name"],
            email: v["email"],
            created_at: v["created_at"].toDate(),
            last_login: v["last_login"].toDate(),
            status: v["status"]);
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (_) => InsSelection(insAdmin: insAdmin,)), (
              r) => false);
         return;
        }
      } else
        if(role=="admin"){
        final instituteId=dox['institute_id'];
        final insAdminId=dox['ins_admin_id'];
        final v =await dbRef.collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("admins").doc(auth.currentUser!.uid).get();
        if(!v.exists){
          await Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        Admin _admin=Admin(
          id: v.id,
          insAdminId: v['ins_admin_id'],
          instituteId: v['institute_id'],
          name: v['name'],
          email: v['email'],
          institute: v['institute'],
          role: v['role'],
          permissions:List<String>.from( v['permissions']),
          status: v['status'],
        );
        if(context.mounted){
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => AdminDeshboard(admin: _admin)), (r) => false);
        return;
        }

      }else
        if(role=="faculty"){
        final instituteId=dox['institute_id'];
        final insAdminId=dox['ins_admin_id'];
        final departmentId=dox['department_id'];
        final v =await dbRef.collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("faculty").doc(auth.currentUser!.uid).get();
        if(!v.exists){
          await Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        Lecturer faculty=Lecturer(
          id: v.id,
          name: v['name'],
          deprt: v['depart'],
          role: v['role'],
          instituteId: instituteId,
          insAdminId: insAdminId,
          departmentId: departmentId,
          designation: v['designation'],
          status: v['status'],
          email: v['email'],
          semesters: List<int>.from(v['semester']),
          courses: List<String>.from(v['courses']),
          created_at: v['created_at'].toDate(),
          phone: v['phone'],);
        if(context.mounted){
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => FacDeshboard(lecturer: faculty)), (r) => false);
        return;
        }
      }else
        if(role=="student"){
        final instituteId=dox['institute_id'];
        final insAdminId=dox['ins_admin_id'];
        final departmentId=dox['department_id'];
        final sessionId=dox['session_id'];
        final semesterId=dox['semester_id'];
        final v =await dbRef.collection("ins_admins").doc(insAdminId)
            .collection("institutes").doc(instituteId)
            .collection("departments").doc(departmentId)
            .collection("sessions").doc(sessionId)
            .collection("semesters").doc(semesterId)
            .collection("students").doc(auth.currentUser!.uid).get();
        if(!v.exists){
          await Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        Student student=Student(
          id: v.id,
          role: v['role'],
          name: v['name'],
          insAdminId: insAdminId,
          instituteId: instituteId,
          departId: v['department_id'],
          sessionId: v['session_id'],
          semesterId: v['semester_id'],
          email: v['email'],
          created_at: v['created_at'].toDate(),
        );
        if(context.mounted){
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
              builder: (_) => StudentDeshboard(student: student)), (
              r) => false);
           return;
        }
      }
    }
    else {
      await Navigator.pushReplacementNamed(context, '/login');
      return;
    }
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
              child:
              Container(
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
