import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/student/std_facial_setting.dart';

import '../../services/biometric_dervice.dart';
import '../../services/db_service.dart';

class StdBioMet extends StatefulWidget {
  final Student student;
  const StdBioMet({super.key, required this.student});

  @override
  State<StdBioMet> createState() => _StdBioMetState();
}

class _StdBioMetState extends State<StdBioMet> {
  bool loading=false;
  bool authenticated=false;
  bool isAuthenticating=false;
  final biometricService=BiometricService();

  handleBiometricAuthentication()async{
    setState(() {
      isAuthenticating=true;
    });
    var result=await biometricService.authenticateUser();
    setState(() {
      isAuthenticating=false;
      authenticated=result.$1;
    });
    if(authenticated){
      if(mounted){
       Fluttertoast.showToast(msg: "Authentication successful,you can now mark attendance with fingerprint");
      }
    }
    else{
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.$2))
        );
      }
    }
  }

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
            onTap:isAuthenticating?null:handleBiometricAuthentication,
            child: Card(
              color: Colors.white,
              child:ListTile(
                title: Text("Finger-print setting"),
                leading: Icon(Icons.fingerprint,color: Theme.of(context).primaryColor,),
                subtitle: Text("configure finger-print to enable attendance through fingerprint",style: TextStyle(color: Colors.grey),),
              ),
            ),
          )
        ],
      ),
    );
  }
  enableFingerPrint()async{
    try{
      setState(() {
        loading=true;
      });
      await Provider.of<DbService>(context,listen: false).indexDoc.doc(widget.student.id).set({
        "fingerprint":true
      });
      print("fingerprint enabled");
    }catch(e){
      print(e.toString());
    }finally{
      setState(() {
        loading=false;
      });
    }
  }
  disabledFingerPrint()async{
    try{
      setState(() {
        loading=true;
      });
      await Provider.of<DbService>(context,listen: false).indexDoc.doc(widget.student.id).set({
        "fingerprint":false
      });
      print("fingerprint enabled");
    }catch(e){
      print(e.toString());
    }finally{
      setState(() {
        loading=false;
      });
    }
  }

}
