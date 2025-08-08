import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ai_exp_track/screens/loginscreen.dart';
import 'package:ai_exp_track/screens/homescreen.dart';
import 'package:ai_exp_track/screens/registerscreen.dart';
// import 'package:ai_exp_track/screens/chatscreen.dart';
// import 'package:ai_exp_track/screens/expensescreen.dart';
// import 'package:ai_exp_track/screens/addexpensescreen.dart';
// import 'package:ai_exp_track/screens/scanscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();


  runApp(const MainApp());
}



class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home' : (context) => HomeScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
