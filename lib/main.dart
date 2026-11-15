import 'package:flutter/material.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TasklyApp());
}

class TasklyApp extends StatelessWidget {
  const TasklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052CC),
          primary: const Color(0xFF0052CC),
          surface: const Color(0xFFFAF7F2),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainShell(),
    );
  }
}
