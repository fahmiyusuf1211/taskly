import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/app_routes.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TasklyApp());
}

class TasklyApp extends StatelessWidget {
  const TasklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GetMaterialApp dipakai supaya seluruh navigasi bisa lewat GetX
    // (rute terdaftar di lib/core/app_routes.dart). Tema dan konfigurasi
    // lain tetap sama persis dengan MaterialApp sebelumnya, jadi tampilan
    // tidak berubah sedikit pun.
    return GetMaterialApp(
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
      // Halaman pertama tetap MainShell, sama seperti `home:` sebelumnya.
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.routes,
      // Fallback: kalau ada rute tak dikenal, tampilkan MainShell
      // (bukan layar error), supaya deep-link yang salah tidak mematikan app.
      unknownRoute: GetPage<dynamic>(
        name: '/not-found',
        page: () => const MainShell(),
      ),
    );
  }
}
