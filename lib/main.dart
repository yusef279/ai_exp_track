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
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home' : (context) => HomeScreen(),
        // '/scan': (context) => const ScanScreen(),
        // '/chat': (context) => const ChatScreen(),
        // '/expenses': (context) => const ExpensesScreen(),
        // '/add-expense': (context) => const AddExpenseScreen(),
      }
    );
  }
}
