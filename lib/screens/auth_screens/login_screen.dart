import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/auth_screens/register_ins_admin.dart';
import 'package:smas3/screens/faculty/fac_deshboard.dart';
import 'package:smas3/screens/ins_admin/ins_admin_dashboard.dart';
import 'package:smas3/screens/student/stdudent_deshboard.dart';
import 'package:smas3/services/db_service.dart';
import '../../models/ins_admin.dart';
import '../admin/admin_deshboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  // void initState() {
  //   Provider.of<DbService>(context,listen: false).getData();
  //   // TODO: implement initState
  //   super.initState();
  // }
  String selectedRole = "Student";
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedMethod = "Email";
  final roles = ["Student", "Faculty", "Admin","insAdmin"];
  final methods = ["Biometric", "Email"];
  bool rememberMe = false;
  bool obscure = true;
  bool loading=false;
  final eauth=FirebaseAuth.instance;
   loginWithStdEmail()async{
     setState(() {
       loading=true;
     });
     try{
       final cu=await eauth.signInWithEmailAndPassword(email: emailController.text.trim(),
           password: passwordController.text.trim()).then((v){
         if(eauth.currentUser!=null){
           Student student=Provider.of<DbService>(context,listen: false).students.firstWhere((element) => element.id==eauth.currentUser!.uid);
           print(student.name);
           Navigator.push(context, MaterialPageRoute(builder: (_)=>StudentDeshboard(student: student)));
         }else{
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));
         }
       });
     }catch(e){
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("error:$e"),));
     }finally{
       setState(() {
         loading=false;
       });
     }

   }
  loginWithFacEmail()async{
    setState(() {
      loading=true;
    });
    try{
      await eauth.signInWithEmailAndPassword(email: emailController.text.trim(),
          password: passwordController.text.trim()).then((v){
        if(eauth.currentUser!=null){
          InsAdmin insAdmin=Provider.of<DbService>(context,listen: false).ins_admins.firstWhere((element) => element.email==emailController.text.trim());
          print(insAdmin.name);
          Navigator.push(context, MaterialPageRoute(builder: (_)=>InsAdminDashboard(insAdmin: insAdmin,)));
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
  loginWithAdminEmail()async{
    setState(() {
      loading=true;
    });
    try{
      await eauth.signInWithEmailAndPassword(email: emailController.text.trim(),
          password: passwordController.text.trim()).then((v){
        if(eauth.currentUser!=null){
          Admin admin=Provider.of<DbService>(context,listen: false).admins.firstWhere((element) => element.email==emailController.text.trim());
          print(admin.name);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>AdminDeshboard(admin: admin)),(r)=>false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("successfully logging as admin"),backgroundColor: Theme.of(context).primaryColor,));
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
  // loginWithInsAdminEmail()async{
  //    try{
  //      await eauth.signInWithEmailAndPassword(email: emailController.text.trim(),
  //          password: passwordController.text.trim()).then((v){
  //        if(eauth.currentUser!=null){
  //          InsAdmin insAdmin=Provider.of<DbService>(context,listen: false).ins_admins.firstWhere((element) => element.id==eauth.currentUser!.uid);
  //          print(insAdmin.name);
  //          if(insAdmin!=null){
  //            Navigator.push(context, MaterialPageRoute(builder: (_)=>InsAdminDashboard(insAdmin: insAdmin,)));
  //            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("successfully logging as institute admin"),backgroundColor: Theme.of(context).primaryColor,));
  //          }else{
  //            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));
  //          }
  //
  //        }else{
  //          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));
  //        }
  //      });
  //    }catch(e){
  //      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));
  //    }finally{
  //      setState(() {
  //        loading=false;
  //      });
  //    }
  //
  //  }
  login(){
     if(selectedRole=="Student"){
       loginWithStdEmail();
     }else if(selectedRole=="Faculty"){
       loginWithFacEmail();
     }else if(selectedRole=="Admin"){
       loginWithAdminEmail();
     }else if(selectedRole=="insAdmin"){
       Provider.of<DbService>(context,listen: false)
           .loginWithInsAdminEmail(emailController.text.trim(), passwordController.text.trim(), context);
     }
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {


    return  Scaffold(
      backgroundColor:Colors.white,
      // const Color(0xFFF1FAF5),
      body:Consumer<DbService>(builder: (context,provider,child){
        return
        Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // Logo / Icon
                  Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:Theme.of(context).primaryColor
                      ),
                      child:  Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(Icons.fingerprint, size: 40, color:Colors.white),
                      )),
                  const SizedBox(height: 10),

                  // Title
                  const Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Sign in to continue to AttendEase",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Role Selector
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Table(
                            border: TableBorder.symmetric(
                                inside: BorderSide(
                                    color: Colors.grey.shade500,
                                    width: 1
                                )
                            ),
                            children: [
                              TableRow(
                                  children: [
                                    for(int i=0;i<roles.length;i++)
                                      InkWell(
                                        onTap: (){
                                          setState(() {
                                            selectedRole=roles[i];
                                          });
                                        },
                                        child: Container(
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: selectedRole==roles[i]?Theme.of(context).primaryColor:Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: i == 0
                                                  ? const Radius.circular(6)
                                                  : Radius.zero,
                                              bottomLeft: i == 0
                                                  ? const Radius.circular(6)
                                                  : Radius.zero,

                                              topRight: i == roles.length - 1
                                                  ? const Radius.circular(6)
                                                  : Radius.zero,
                                              bottomRight: i == roles.length - 1
                                                  ? const Radius.circular(6)
                                                  : Radius.zero,
                                            ),

                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(roles[i],textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w400),),
                                          ),
                                        ),
                                      )
                                  ]
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 20),

                        // Login Method
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: methods.map((method) {
                            final isSelected = selectedMethod == method;
                            return ChoiceChip(
                              label: Text(method),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => selectedMethod = method),
                              selectedColor:Theme.of(context).primaryColor,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              backgroundColor: Colors.grey.shade100,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 15),

                        // Email Login Fields
                        if (selectedMethod == "Email") ...[
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "$selectedRole@gmail.com",
                              labelStyle:  TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.email_outlined,color: Colors.black54,),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v){
                              if(v!.isEmpty){
                                return "Please enter email";
                              }else if(!v.contains("@")){
                                return "Please enter valid email";
                              }else if(!v.contains(".")){
                                return "Please enter valid email";
                              }else if(!v.contains("com")){
                                return "Please enter valid email";
                              }else if(!v.contains("gmail" )&&!v.contains("yahoo")&&!v.contains("outlook")){
                                return "Please enter valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle:  TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.lock_outline,color: Colors.black54,),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,color:obscure?Colors.black54:Theme.of(context).primaryColor ,
                                ),
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v){
                              if(v!.isEmpty){
                                return "Please enter password";
                              }else if(v.length<8){
                                return "Password must be at least 8 characters";
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Remember Me + Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Row(
                              //   children: [
                              //     Checkbox(
                              //       value: rememberMe,
                              //       onChanged: (val) =>
                              //           setState(() => rememberMe = val!),
                              //     ),
                              //      // Text("Remember me",style: TextStyle(fontSize: 12),),
                              //   ],
                              // ),
                              TextButton(
                                onPressed: () {},
                                child: const Text("Forgot password?",style: TextStyle(fontSize: 12,color: Color.fromARGB(230, 0, 152,120)),),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
//main button
                                if(formKey.currentState!.validate()){
                                  login();
                                }else{
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("plz select valid role"),)
                                  );
                                }
                              },
                              icon: const Icon(Icons.arrow_right_alt,color: Colors.white,),
                              label: const Text(
                                "Sign In",
                                style: TextStyle(fontSize: 16,color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Biometric Buttons
                        if (selectedMethod == "Biometric") ...[
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.redAccent],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                "Multi-Factor Auth",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _biometricButton(Icons.fingerprint, "Fingerprint",
                                  Theme.of(context).primaryColor),
                              _biometricButton(Icons.face, "Facial", Colors.blue),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Footer
                  selectedRole=="insAdmin"?GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_)=>RegisterInsAdmin()));
                    },
                    child: const Text(
                      "Don't have an account? register now as institute admin",
                      style: TextStyle(color: Color.fromARGB(255, 0, 152,124)),
                    ),
                  ):
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      "Don't have an account? Contact administrator",
                      style: TextStyle(color: Color.fromARGB(255, 0, 152,124)),
                    ),
                  ),
                  SizedBox(height: 15,),
                  InkWell(
                    onTap: (){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("using google"),));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/icons/google.png",width: 25,height: 25,),
                        SizedBox(width: 10,),
                        Text("Continue with google",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w400),),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      })
    );
  }

  // Custom biometric button
  Widget _biometricButton(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
