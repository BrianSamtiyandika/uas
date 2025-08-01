// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:racketlog/firebase_options.dart'; // File hasil generate flutterfire
import 'package:racketlog/widgets/auth_gate.dart'; // Widget baru untuk gerbang autentikasi

void main() async {
  // Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatat Skor Badminton',
      theme: ThemeData(
        cardTheme: const CardThemeData( // Sesuai instruksi Anda
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      // AuthGate akan menentukan halaman mana yang ditampilkan
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}