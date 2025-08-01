// lib/screens/success_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:racketlog/widgets/auth_gate.dart';

class SuccessScreen extends StatefulWidget {
  final String message;
  const SuccessScreen({super.key, required this.message});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()),
              (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/success.json',
              width: 250,
              height: 250,
              fit: BoxFit.fill,
            ),
            const SizedBox(height: 24),
            Text(
              widget.message,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}