import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final fb_instanse=FirebaseAuth.instance;
  TextEditingController email=TextEditingController();
  final key=GlobalKey<FormState>();
  bool loading=false;
  resetPassword(){
    setState(() {
      loading=true;
    });
    try{
      fb_instanse.sendPasswordResetEmail(email: email.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password reset link sent to your email"),backgroundColor: Colors.green,));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),backgroundColor: Colors.red,));
    }finally{
      setState(() {
        loading=false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title:Text("Forgot Password",textAlign: TextAlign.center,style: TextStyle(fontSize: 20,color: Theme.of(context).primaryColor,fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body:loading?
      Center(child: CircularProgressIndicator(),):
      Form(
        key: key,
        child:
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(

            // spacing: 10,
            children: [
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
                  }
                  // else if(!v.contains("gmail" )&&!v.contains("yahoo")&&!v.contains("outlook")){
                  //   return "Please enter valid email";
                  // }
                  // method II
                  // final emailRegex =
                  // RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                  // if (!emailRegex.hasMatch(v.trim())) {
                  //   return "Please enter valid email";
                  // }
                  return null;
                },
              ),
              SizedBox(height: 15,),
              ElevatedButton.icon(
                  style:ButtonStyle(
                    backgroundColor:MaterialStateProperty.all(Theme.of(context).primaryColor),
                  ),
                  onPressed:  (){
                    if(!key.currentState!.validate()){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter email"),backgroundColor: Colors.red,));
                      return;
                    }else {
                      showDialog(context: context, builder: (_) =>
                          AlertDialog(
                            title: Text("Reset Password", style: TextStyle(
                              // fontSize: 19,
                              fontWeight: FontWeight.bold,
                              // color: Theme.of(context).primaryColor
                            ),),
                            icon: Icon(Icons.rotate_left_sharp,
                              color: Colors.red, size: 35,),
                            content: Text(
                                "Are you sure to reset the password?"),
                            actions: [
                              FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Theme
                                          .of(context)
                                          .primaryColor
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  }, child: Text("No",)),
                              FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red
                                  ),
                                  onPressed: () async {
                                    await resetPassword();
                                    Navigator.pop(context);
                                  }, child: Text("yes",)),
                            ],
                          ));
                    }
              },
                  icon:  Icon(Icons.lock_reset,color: Colors.white,),
                  label:Text("Reset Password",style: TextStyle(color:Colors.white),))
            ],
          ),
        ),
      ),
    );
  }
}
