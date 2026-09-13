import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../models/ins_admin.dart';
import '../../services/db_service.dart';
import '../ins_admin/ins_admin_dashboard.dart';

class _Palette {
  static const ink = Color(0xFF0E231F);
  static const inkSoft = Color(0xFF16342E);
  static const paper = Color(0xFFF7FAF9);
  static const slate = Color(0xFF55645F);
  static const hairline = Color(0xFFDEE6E3);
  static const teal = Color(0xFF009878);
}
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
  bool obscure1=true;
  bool obscure=true;
  final formKey=GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title:Text("Register Institute Admin",textAlign: TextAlign.center,style: TextStyle(fontSize: 20,color: Theme.of(context).primaryColor,fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:loading?Center(child:
      SizedBox(
          width:150,height: 150,
          child: Lottie.asset("assets/anims/m2.json")),):
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: ListView(
            children: [

              SizedBox(height: 20,),
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  labelText: "Name",
                  prefixIcon: const Icon(Icons.person, color: _Palette.slate),
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
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "Enter your email here..",
                  prefixIcon: const Icon(Icons.mail_outline, color: _Palette.slate),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Enter your email";
                  if (!v.contains("@") || !v.contains(".")) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),//email
              SizedBox(height: 15,),
              TextFormField(
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline, color: _Palette.slate),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: obscure ? _Palette.slate : _Palette.teal,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter your password";
                  if (v.length < 8) return "Password must be at least 8 characters";

                  if (!RegExp(r'[A-Z]').hasMatch(v)) {
                    return "Password must contain at least one uppercase letter";
                  }
                  if (!RegExp(r'[a-z]').hasMatch(v)) {
                    return "Password must contain at least one lowercase letter";
                  }
                  if (!RegExp(r'[0-9]').hasMatch(v)) {
                    return "Password must contain at least one number";
                  }
                  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;+=~`]').hasMatch(v)) {
                    return "Password must contain at least one special character";
                  }
                  return null;
                },
              ),//password
              SizedBox(height: 15,),
             TextFormField(
            controller: confirm_password,
            obscureText: obscure1,
            decoration: InputDecoration(
              labelText: "confirm Password",
              prefixIcon: const Icon(Icons.lock_outline, color: _Palette.slate),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: obscure1 ? _Palette.slate : _Palette.teal,
                ),
                onPressed: () => setState(() => obscure1 = !obscure1),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "Enter your password";
              if (v.length < 8) return "Password must be at least 8 characters";

              if (!RegExp(r'[A-Z]').hasMatch(v)) {
                return "Password must contain at least one uppercase letter";
              }
              if (!RegExp(r'[a-z]').hasMatch(v)) {
                return "Password must contain at least one lowercase letter";
              }
              if (!RegExp(r'[0-9]').hasMatch(v)) {
                return "Password must contain at least one number";
              }
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;+=~`]').hasMatch(v)) {
                return "Password must contain at least one special character";
              }
              return null;
            },
          ),//Confirm password
              SizedBox(height: 15,),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: (){
                if(formKey.currentState!.validate()){
                  if(password.text!=confirm_password.text){
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("password not matched"),backgroundColor: Colors.red,));
                  }else{
                    InsAdmin insAdmin=InsAdmin(
                        role: "ins_admin",
                        name: name.text.trim(),
                        email: email.text.trim(),
                        status: "active",
                      created_at: DateTime.now(),
                      last_login: DateTime.now(),
                    );
                    Provider.of<DbService>(context,listen: false).signUpWithInsAdminEmail(insAdmin,password.text.trim(),context);
                  }
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please fill all fields"),backgroundColor: Colors.red,));
                }
              }, child: Text("register",style: TextStyle(
                color:Colors.white,
                fontWeight: FontWeight.w600
              ),)),
            ],
          ),
        ),
      ),
    );
  }
}
