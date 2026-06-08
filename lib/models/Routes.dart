import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/auth_screens/login_screen.dart';
import 'package:smas3/screens/faculty/fac_deshboard.dart';
import 'package:smas3/screens/splash/splash_screen.dart';
import 'package:smas3/screens/admin/admin_deshboard.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/screens/student/stdudent_deshboard.dart';

class RouteHelper {
  static String home = "/";
  static String stdDashboard = "/stddeshboard";
  static String login = "/login";
  static String admin = "/admin";

  // Normal routes
  static Map<String, WidgetBuilder> myRoutes() {
    return {
      home: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),

    };
  }

  // Dynamic (Generated) routes
  static Route<dynamic> myGenRoutes(RouteSettings settings) {
    switch (settings.name) {
      case "/admin":
        final admin = settings.arguments as Admin;
        return MaterialPageRoute(
          builder: (context) => AdminDeshboard(admin: admin),
        );

      case "/fac_desh":
        return MaterialPageRoute(
          builder: (context) => FacDeshboard(lecturer: Lecturer(
              name: 'abd', deprt: '', designation: '', status: '', email: '', phone: '', role: '', instituteId: '', insAdminId: ''

          ),),
        );

      case "/stddeshboard":
    final student= Student(
        id: "1204",
        role: "student",
        instituteId: "34567890",
        insAdminId: "234567890",
        name: "Ameer",
        depart: "Information Technology",
        semester: 7,
        email: "ameermuawiya472@gmail.com",
    );
        return MaterialPageRoute(
          builder: (context) => StudentDeshboard(student: student,),
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
    }
  }
}
