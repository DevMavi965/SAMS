import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ins_admin.dart';
import '../../services/db_service.dart';
import '../ins_admin/ins_admin_dashboard.dart';

class RegisterInsAdmin extends StatefulWidget {
  const RegisterInsAdmin({super.key});

  @override
  State<RegisterInsAdmin> createState() => _RegisterInsAdminState();
}

class _RegisterInsAdminState extends State<RegisterInsAdmin> {
  String con="password not matched";
  TextEditingController name=TextEditingController();
  TextEditingController email=TextEditingController();
  // TextEditingController phone=TextEditingController();
  TextEditingController password=TextEditingController();
  TextEditingController confirm_password=TextEditingController();
  final auth=FirebaseAuth.instance;
  bool loading=false;
  signUpWithInsAdminEmail()async{
    setState(() {
      loading=true;
    });
    try{
      await auth.createUserWithEmailAndPassword(email: email.text.trim(),
          password: password.text.trim()).then((v) async{
        if(auth.currentUser!=null){

          InsAdmin insAdmin=InsAdmin(
              id: auth.currentUser!.uid,
              name: name.text.trim(),
              email: email.text.trim(),
              status: 'active',
            last_login: DateTime.now(),
            created_at: DateTime.now(),
          );
         await Provider.of<DbService>(context,listen: false).addInsAdmin(context,insAdmin);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>InsAdminDashboard(insAdmin: insAdmin,)),(r)=>false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("successfully registered as institute admin"),backgroundColor: Theme.of(context).primaryColor,));
        }else{
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));
        }
      });
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));
    }finally{
      setState(() {
        loading=false;
      });
    }

  }
  final formKey=GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              SizedBox(height: 25,),
              Text("Register Institute Admin",textAlign: TextAlign.center,style: TextStyle(fontSize: 20,color: Theme.of(context).primaryColor,fontWeight: FontWeight.w600)),
              SizedBox(height: 20,),
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      width: 0.5,
                      color: Colors.grey
                    )
                  ),
                ),
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter name";
                  }else if(v.length<3){
                    return "Please enter valid name";
                  }
                  return null;
                },
              ),//name
              SizedBox(height: 15,),
              TextFormField(
                controller: email,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      width: 0.5,
                      color: Colors.grey
                    )
                  ),
                ),
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter email";
                  }else if(v.length<3){
                    return "Please enter valid email";
                  }else if(!v.contains("@")){
                    return "Please enter valid email";
                  }else if(!v.contains(".")){
                    return "Please enter valid email";
                  }else if(!v.contains("com")){
                    return "Please enter valid email";
                  }else if(!v.contains("gmail" )&&!v.contains("yahoo")&&!v.contains("outlook")){
                    return "Please enter valid email";
                  }
                  // method II
                  // final emailRegex =
                  // RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                  // if (!emailRegex.hasMatch(v.trim())) {
                  //   return "Please enter valid email";
                  // }
                  return null;
                },
              ),//email
              SizedBox(height: 15,),
              TextFormField(
                controller: password,
                decoration: InputDecoration(
                  labelText: "password",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          width: 0.5,
                          color: Colors.grey
                      )
                  ),
                ),
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter password";
                  }else if(v.length<6){
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),//password
              SizedBox(height: 15,),
              TextFormField(
                controller: confirm_password,
                decoration: InputDecoration(
                  labelText: "confirm-password",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          width: 0.5,
                          color: Colors.grey
                      )
                  ),
                ),
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter password";
                  }else if(v.length<6){
                    return "Password must be at least 6 characters";
                  }else if(v!=password.text){
                    return con;
                  }
                  return null;
                },
              ),//Confirm password
              SizedBox(height: 15,),
              ElevatedButton(onPressed: (){
                if(formKey.currentState!.validate()){
                  if(password.text!=confirm_password.text){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("password not matched"),backgroundColor: Colors.red,));
                  }else{
                    signUpWithInsAdminEmail();
                  }
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please fill all fields"),backgroundColor: Colors.red,));
                }
              }, child: Text("register")),
            ],
          ),
        ),
      ),
    );
  }
}
