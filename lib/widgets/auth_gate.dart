// lib/widgets/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:racketlog/screens/home_screen.dart';
import 'package:racketlog/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jika pengguna belum login, tampilkan halaman login
          if (!snapshot.hasData) {
            return const LoginScreen();
          }
          // Jika pengguna sudah login, tampilkan halaman utama
          return const HomeScreen();
        },
      ),
    );
  }
}