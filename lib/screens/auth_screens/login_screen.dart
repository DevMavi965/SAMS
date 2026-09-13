import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/auth_screens/forgot_password.dart';
import 'package:smas3/screens/auth_screens/register_ins_admin.dart';
import 'package:smas3/screens/faculty/fac_deshboard.dart';
import 'package:smas3/screens/ins_admin/ins_admin_dashboard.dart';
import 'package:smas3/screens/ins_admin/ins_selection.dart';
import 'package:smas3/screens/student/stdudent_deshboard.dart';
import 'package:smas3/services/db_service.dart';
import '../../models/fac_model.dart';
import '../../models/ins_admin.dart';
import '../admin/admin_deshboard.dart';

// ── Design tokens ───────────────────────────────────────────────────
// Kept close to the app's existing teal accent (was hardcoded as
// Color.fromARGB(230/255, 0, 152, 120/124) in a couple of places in the
// old file) rather than introducing an unrelated palette, and paired it
// with a dark ink-green header rather than a generic navy/black, so the
// whole screen reads as one family instead of a stock template.
class _Palette {
  static const ink = Color(0xFF0E231F);
  static const inkSoft = Color(0xFF16342E);
  static const paper = Color(0xFFF7FAF9);
  static const slate = Color(0xFF55645F);
  static const hairline = Color(0xFFDEE6E3);
  static const teal = Color(0xFF009878);
}

class _RoleOption {
  final String value; // must match the strings login() switches on
  final String label; // what the person sees
  final IconData icon;
  const _RoleOption(this.value, this.label, this.icon);
}

const List<_RoleOption> _roleOptions = [
  _RoleOption("Student", "Student", PhosphorIconsBold.graduationCap),
  _RoleOption("Faculty", "Faculty", PhosphorIconsBold.chalkboardTeacher),
  _RoleOption("Admin", "Admin", PhosphorIconsBold.shieldCheck),
  _RoleOption("insAdmin", "Institute Admin", PhosphorIconsBold.buildings),
];

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = "Student";
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscure = true;
  bool loading = false;
  final eauth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();

  login() {
    if (selectedRole == "Student") {
      Provider.of<DbService>(context, listen: false).loginWithStudentEmail(
          emailController.text.trim(), passwordController.text.trim(), context);
    } else if (selectedRole == "Faculty") {
      Provider.of<DbService>(context, listen: false).loginWithFacEmail(
          emailController.text.trim(), passwordController.text.trim(), context);
    } else if (selectedRole == "Admin") {
      Provider.of<DbService>(context, listen: false).loginWithAdminEmail(
          emailController.text.trim(), passwordController.text.trim(), context);
    } else if (selectedRole == "insAdmin") {
      Provider.of<DbService>(context, listen: false).loginWithInsAdminEmail(
          emailController.text.trim(), passwordController.text.trim(), context);
    }
  }

  continueWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });
      final dbRef = FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB");
      final indexDoc = FirebaseFirestore.instance
          .collection("SAMS")
          .doc("SAMS_DB")
          .collection("index");
      GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
          serverClientId:
          "319337104794-jghsq31njud2m6nrf9cmmraf7lke384u.apps.googleusercontent.com");
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.authenticate();
      GoogleSignInAuthentication googleAuth = await googleSignInAccount.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await eauth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final dox = await indexDoc.doc(userCredential.user!.uid).get();
        if (dox.exists == false) {
          await Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        String role = dox['role'];
        if (role == "ins_admin") {
          final v =
          await dbRef.collection("ins_admins").doc(userCredential.user!.uid).get();
          if (!v.exists) {
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
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => InsSelection(insAdmin: insAdmin)),
                    (r) => false);
            return;
          }
        } else if (role == "admin") {
          final instituteId = dox['institute_id'];
          final insAdminId = dox['ins_admin_id'];
          final v = await dbRef
              .collection("ins_admins")
              .doc(insAdminId)
              .collection("institutes")
              .doc(instituteId)
              .collection("admins")
              .doc(userCredential.user!.uid)
              .get();
          if (!v.exists) {
            await Navigator.pushReplacementNamed(context, '/login');
            return;
          }
          Admin _admin = Admin(
            id: v.id,
            insAdminId: v['ins_admin_id'],
            instituteId: v['institute_id'],
            name: v['name'],
            email: v['email'],
            institute: v['institute'],
            role: v['role'],
            permissions: List<String>.from(v['permissions']),
            status: v['status'],
          );
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => AdminDeshboard(admin: _admin)),
                    (r) => false);
            return;
          }
        } else if (role == "faculty") {
          final institute_Id = dox['institute_id'];
          final insAdmin_Id = dox['ins_admin_id'];
          final department_Id = dox['department_id'];
          final v = await dbRef
              .collection("ins_admins")
              .doc(insAdmin_Id)
              .collection("institutes")
              .doc(institute_Id)
              .collection("faculty")
              .doc(userCredential.user!.uid)
              .get();
          if (!v.exists) {
            await Navigator.pushReplacementNamed(context, '/login');
            return;
          }
          Lecturer faculty = Lecturer(
            id: v.id,
            name: v['name'],
            deprt: v['depart'],
            role: v['role'],
            instituteId: institute_Id,
            insAdminId: insAdmin_Id,
            departmentId: department_Id,
            designation: v['designation'],
            status: v['status'],
            email: v['email'],
            semesters: List<int>.from(v['semester']),
            courses: List<String>.from(v['courses']),
            created_at: v['created_at'].toDate(),
            phone: v['phone'],
          );
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => FacDeshboard(lecturer: faculty)),
                    (r) => false);
            return;
          }
        } else if (role == "student") {
          final instituteId = dox['institute_id'];
          final insAdminId = dox['ins_admin_id'];
          final departmentId = dox['department_id'];
          final sessionId = dox['session_id'];
          final semesterId = dox['semester_id'];
          final v = await dbRef
              .collection("ins_admins")
              .doc(insAdminId)
              .collection("institutes")
              .doc(instituteId)
              .collection("departments")
              .doc(departmentId)
              .collection("sessions")
              .doc(sessionId)
              .collection("semesters")
              .doc(semesterId)
              .collection("students")
              .doc(userCredential.user!.uid)
              .get();
          if (!v.exists) {
            await Navigator.pushReplacementNamed(context, '/login');
            return;
          }
          Student student = Student(
            id: v.id,
            role: v['role'],
            name: v['name'],
            insAdminId: insAdminId,
            instituteId: instituteId,
            departId: v['depart_id'],
            sessionId: v['session_id'],
            semesterId: v['semester_id'],
            email: v['email'],
            created_at: v['created_at'].toDate(),
          );
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => StudentDeshboard(student: student)),
                    (r) => false);
            return;
          }
        }
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.paper,
      body: loading
          ? Center(
        child: SizedBox(
            width: 150, height: 150, child: Lottie.asset("assets/anims/m2.json")),
      )
          : Consumer<DbService>(
        builder: (context, provider, child) {
          // if (provider.loading) {
          //   return Center(
          //     child: SizedBox(
          //         width: 150,
          //         height: 150,
          //         child: Lottie.asset("assets/anims/m2.json")),
          //   );
          // }
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                // Card overlaps the header slightly, like a sheet sliding
                // up from it, and fades/rises in once on load — one
                // orchestrated entrance rather than per-field animations.
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCard(context),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.ink, _Palette.inkSoft],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.58),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child:
            Image.asset("assets/icons/samshyperlogo.png", ),
            // child: const Text(
            //   "S",
            //   style: TextStyle(
            //     fontFamily: 'serif',
            //     fontSize: 26,
            //     fontWeight: FontWeight.w600,
            //     color: Colors.white,
            //   ),
            // ),
          ),
          const SizedBox(height: 16),
          const Text(
            "SAMS",
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),//institute
          const SizedBox(height: 6),
          Text(
            "Smart Attendance Management System",
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
 //forgot
  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color:Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sign in as",
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _Palette.slate),
            ),
            const SizedBox(height: 10),

            // Role picker — a 2x2 grid of flat, bordered tiles (fill
            // change on selection, no drop-shadow-per-card) instead of
            // the old single-row table, so each role reads as its own
            // choice rather than a segment of one control.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                for (final option in _roleOptions)
                  _RoleTile(
                    option: option,
                    selected: selectedRole == option.value,
                    onTap: () => setState(() => selectedRole = option.value),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: emailController,
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
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: passwordController,
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
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: implement forgot password
             Navigator.push(context, MaterialPageRoute(builder: (_)=>ForgotPassword()));
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(fontSize: 12.5, color: _Palette.teal),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Sign in
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    login();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Check the fields above and try again.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:Provider.of<DbService>(context,listen: false).loading? Theme.of(context).primaryColor.withOpacity(0.76):Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child:
                  Provider.of<DbService>(context,listen: false).loading?
                  Center(child:
                  SizedBox(
                      width: 24,height: 24,
                      child: CircularProgressIndicator(color: Colors.white,strokeWidth:2.5,padding: EdgeInsets.all(8),))):
                  Text( "Sign in",
                  style: TextStyle(
                      fontSize: 15.5, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: const [
                Expanded(child: Divider(color: _Palette.hairline)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("or continue with",
                      style: TextStyle(fontSize: 12, color: _Palette.slate)),
                ),
                Expanded(child: Divider(color: _Palette.hairline)),
              ],
            ),
            const SizedBox(height: 16),

            // Google
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: continueWithGoogle,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: _Palette.hairline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Image.asset("assets/icons/google.png", width: 20, height: 20),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(color: _Palette.ink, fontWeight: FontWeight.w500),
                ),
              ),//Attend
            ),
            const SizedBox(height: 18),

            // Only institute admins register themselves; every other role
            // is provisioned by one, so they're pointed to their admin
            // instead of a sign-up form.
            Center(
              child: selectedRole == "insAdmin"
                  ? GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => RegisterInsAdmin())),
                child: RichText(
                  text: const TextSpan(
                    text: "New institute? ",
                    style: TextStyle(color: _Palette.slate, fontSize: 12.5),
                    children: [
                      TextSpan(
                        text: "Register as admin",
                        style: TextStyle(
                            color: _Palette.teal, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
                  : const Text(
                "Don't have an account? Contact your administrator.",
                style: TextStyle(color: _Palette.slate, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? _Palette.teal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _Palette.teal : _Palette.hairline,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(option.icon, size: 21, color: selected ? Colors.white : _Palette.ink),
            const SizedBox(height: 5),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _Palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}