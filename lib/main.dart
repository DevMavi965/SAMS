import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/Routes.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/providers/theme_Provider.dart';
import 'package:smas3/screens/admin/admin_deshboard.dart';
import 'package:smas3/screens/faculty/fac_deshboard.dart';
import 'package:smas3/screens/splash/splash_screen.dart';
import 'package:smas3/screens/student/stdudent_deshboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_)=>ThemeProvider(),
    child: Consumer<ThemeProvider>(builder: (context,provider,child){
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        // home: FacDeshboard(),
        // routes: RouteHelper.myRoutes(),
        home: AdminDeshboard(admin: Admin(name: "Ameer Muawiya", email: "ameermuawiya34@gmail.com", institute: "SVDS", role: "Admin", status: "active")),
        // home: StudentDeshboard(student: Student(id: "120", name: "ali", deprt: "physics",
        //     semester: 5, email: "abc@.com", password: "23478899")),
        // initialRoute:"/fac_desh",
        // routes: MyRouter.myRoutes(),
        // onGenerateRoute: (RouteSettings settings){
        //   return MyRouter.myGenRoutes(settings);
        // },


        themeMode: provider.themeMode,


        theme: ThemeData(
          scaffoldBackgroundColor: Color(0xfffaf8fc),
          brightness: Brightness.light,
          primaryColor: const Color.fromARGB(255, 0, 153, 136),
          primaryColorLight: const Color.fromARGB(40, 67, 186, 125),
          primaryColorDark: const Color.fromARGB(255, 67, 186, 125),
        ),
        darkTheme: ThemeData(
            brightness: Brightness.light,

            primaryColorDark: const Color.fromARGB(255, 38, 95, 136),
            primaryColorLight: const Color.fromARGB(202, 93, 132, 175),
            primaryColor: const Color.fromARGB(255, 34, 32, 103),
            textTheme: TextTheme(

            )
          // primaryColor: Colors.tealAccent,
        ),
      );
    }),
    );
  }
}
