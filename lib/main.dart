import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/Routes.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/providers/theme_Provider.dart';
import 'package:smas3/screens/faculty/fac_deshboard.dart';
import 'package:smas3/screens/student/stdudent_deshboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FacDeshboard(),
          // initialRoute:"/fac_desh",
          // routes: MyRouter.myRoutes(),
          // onGenerateRoute: (RouteSettings settings){
          //   return MyRouter.myGenRoutes(settings);
          // },

          // ✅ Use the provider's current theme mode
          themeMode: themeProvider.themeMode,

          // Define both light and dark themes
          theme: ThemeData(
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
      },
    );
  }
}
