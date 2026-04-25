import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/student/stdudent_deshboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = "Student";
  String selectedMethod = "Email";
  bool rememberMe = false;
  bool obscure = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final roles = ["Student", "Faculty", "Admin"];
    final methods = ["Biometric", "Email"];

    return Scaffold(
      backgroundColor:Colors.white,
      // const Color(0xFFF1FAF5),
      body: Center(
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
                const SizedBox(height: 25),

                // Card
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: roles.map((role) {
                          final isSelected = selectedRole == role;
                          return ChoiceChip(
                            label: Text(role),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => selectedRole = role),
                            selectedColor: Theme.of(context).primaryColor,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

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
                      const SizedBox(height: 25),

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
                            }else if(!v.endsWith("@gmail.com")){
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (val) =>
                                      setState(() => rememberMe = val!),
                                ),
                                 Text("Remember me",style: TextStyle(fontSize: 12),),
                              ],
                            ),
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
                              if(formKey.currentState!.validate() && selectedRole=="Student"){
                                Navigator.push(context,
                                    MaterialPageRoute(
                                    builder: (context)=>
                                        StudentDeshboard(
                                        student:Student(
                                            id: "120",
                                            name: "Muawiya Sultan",
                                            deprt: "Information Technology",
                                            semester: 7,
                                            email: emailController.text,
                                            password: passwordController.text
                                        ) )
                                    )
                                );
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
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    "Don't have an account? Contact administrator",
                    style: TextStyle(color: Color.fromARGB(255, 0, 152,124)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
