import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/db_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../maxins/rm_functions.dart';
class _Palette {
  static const ink = Color(0xFF0E231F);
  static const inkSoft = Color(0xFF16342E);
  static const paper = Color(0xFFF7FAF9);
  static const slate = Color(0xFF55645F);
  static const hairline = Color(0xFFDEE6E3);
  static const teal = Color(0xFF009878);
}
class AddAdminPage extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const AddAdminPage({super.key, required this.insAdmin, required this.institute});

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final List<String> duties = [
    "Timetable",
    "Announcements",
    "Leave_management",
    "student_management",
    "faculty_management",
    "department_management", //includes adding/removing departments & sessions & semesters
    "course_management",
    "session_management",
  ];

  final List<String> duty_detail = [
    "Scheduling lectures & labs",
    "Posting announcements",
    "Approving/Rejecting leave requests",
    "Adding/removing/Editing students records",
    "Managing faculty",
    "Adding/removing departments",
    "Adding/removing courses",
    "Adding/removing sessions & semesters",
  ];

  List<bool> checked = List.generate(8, (_) => false);
  List<String> assigned = [];

  bool obscure = true;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Widget? getIcon(int i) {
    switch (i) {
      case 0:
        return Icon(PhosphorIconsBold.clock, color: Theme.of(context).primaryColor);
      case 1:
        return Icon(PhosphorIconsBold.speakerSimpleHigh, color: Theme.of(context).primaryColor);
      case 2:
        return Icon(PhosphorIconsBold.notepad, color: Theme.of(context).primaryColor);
      case 3:
        return Icon(Icons.person_add_alt_1, color: Theme.of(context).primaryColor);
      case 4:
        return Icon(Icons.person_add_alt, color: Theme.of(context).primaryColor);
      case 5:
        return Icon(PhosphorIconsBold.buildingApartment, color: Theme.of(context).primaryColor);
      case 6:
        return Icon(PhosphorIconsBold.books, color: Theme.of(context).primaryColor);
      case 7:
        return Icon(PhosphorIconsBold.desktop, color: Theme.of(context).primaryColor);
    }
    return null;
  }

  void _submit() {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("enter all fields first")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Admin"),
        content: const Text("Are you sure to add the admin?"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(context),
            child: const Text("No",style: TextStyle(color: Colors.white),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () async{
              assigned.clear();
              for (int i = 0; i < checked.length; i++) {
                if (checked[i]) assigned.add(duties[i]);
              }
              final admin = Admin(
                name: name.text.trim(),
                insAdminId: widget.insAdmin.id!,
                instituteId: widget.institute.id!,
                email: email.text.trim(),
                institute: widget.institute.name,
                role: "admin",
                status: "active",
                permissions: List<String>.from(assigned),
              );
              final password1 = password.text.trim();
              try {
                await Provider.of<DbService>(
                  context,
                  listen: false,
                ).registerAdmin(
                  widget.insAdmin.id!,
                  widget.institute.id!,
                  admin,
                  password1,
                  context,
                );

                Fluttertoast.showToast(
                  msg: "Admin added successfully",
                );

                await RMFuncts.sendSamsCredentialsEmail(
                  admin.email,
                  admin.name,
                  password1,
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                debugPrint("REGISTER ADMIN ERROR: $e");

                // Fluttertoast.showToast(
                //   msg: "Failed to add admin: $e",
                // );
                print(e.toString());
              }
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Yes",style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Add Admin",style: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600
      ),
          ),
        // centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Admin Management & Permissions",
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(width: 0.5, color: Colors.grey),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Please enter name";
                    if (v.length < 3) return "Please enter valid name";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "you@example.com",
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
                ),
                const SizedBox(height: 14),

                // Password

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
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
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 2,),
                    Flexible(
                      child:
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            //border
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12))
                            ),
                            backgroundColor:  Theme.of(context).primaryColor,
                          ),
                          onPressed: (){
                            Fluttertoast.showToast(msg: "generating password");
                            setState(() {
                              password.text = RMFuncts.generatePassword();
                            });
                          }, child: Text("generate",maxLines: 1,style: TextStyle(
                          color:Colors.white,
                          fontSize: 12
                      ),)),
                    )
                  ],
                ),

                const SizedBox(height: 20),
                Text("Duties & Permissions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text("Select what admin is allowed to manage",
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 7),
                for (int i = 0; i < duties.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(1),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                              child: getIcon(i),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(duties[i].split("_").join(" "),
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(duty_detail[i],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: 40,
                            height: 35,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Switch(
                                activeThumbColor: Theme.of(context).primaryColor,
                                value: checked[i],
                                onChanged: (v) => setState(() => checked[i] = v),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                    ),
                    onPressed: _submit,
                    child: const Text("Add", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }



}