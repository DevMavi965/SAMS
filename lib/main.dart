import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/firebase_options.dart';
import 'package:smas3/models/Routes.dart';
import 'package:smas3/providers/theme_Provider.dart';
import 'package:smas3/services/db_service.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (context)=>DbService()),
      ChangeNotifierProvider(create: (context)=>ThemeProvider())
    ],child: Consumer2<ThemeProvider,DbService>(
      builder: (context,provider,dbsprovider,child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // home: FacDeshboard(),
          routes: RouteHelper.myRoutes(),
          //JUlgUsKmHHVEqAhI7y7c0grT9yN2
          // home: dbsprovider.loading? Scaffold(body: Center(child: CircularProgressIndicator(),),):InsAdminDashboard(insAdmin:Provider.of<DbService>(context,listen: false).ins_admins.firstWhere((element) => element.id=="PmqTC7uOWotY7KPCsw8D")),
         // home: RegisterInsAdmin(),

          // home: AdminDeshboard(admin: Admin(name: "Ameer Muawiya", email: "ameermuawiya34@gmail.com", institute: "SVDS", role: "Admin", status: "active")),
          // home:

          // StudentDeshboard(student:dbsprovider.students[0],),
          // AdminDeshboard(admin:dbsprovider.admins[0],),
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
      }
    ));
  }
}
