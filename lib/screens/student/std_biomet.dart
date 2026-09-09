import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/student/std_facial_setting.dart';

class StdBioMet extends StatefulWidget {
  final Student student;
  const StdBioMet({super.key, required this.student});

  @override
  State<StdBioMet> createState() => _StdBioMetState();
}

class _StdBioMetState extends State<StdBioMet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title: Text("Student Bio-metrics Settings",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 18,color: Theme.of(context).primaryColor),),
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>StdFaceReg(student: widget.student,)));
            },
            child: Card(
              color: Colors.white,
              child:ListTile(
                title: Text("Facial recognition setting"),
                leading: Icon(Icons.face_outlined,color: Theme.of(context).primaryColor,),
                subtitle: Text("configure your facial identity",style: TextStyle(color: Colors.grey),),
              ),
            ),
          ),
          InkWell(//fingerPrint here.o.o.o
            onTap: (){
              Fluttertoast.showToast(msg: "coming soon..",textColor: Colors.white);
            },
            child: Card(
              color: Colors.white,
              child:ListTile(
                title: Text("Finger-print setting"),
                leading: Icon(Icons.fingerprint,color: Theme.of(context).primaryColor,),
                subtitle: Text("configure finger-print",style: TextStyle(color: Colors.grey),),
              ),
            ),
          )
        ],
      ),
    );
  }
}
