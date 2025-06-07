// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/auth_service.dart';
import 'package:apophen_shop_manager/screens/login_screen.dart';
import 'package:apophen_shop_manager/screens/dashboard_screen.dart';
import 'package:apophen_shop_manager/core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final authService = AuthService();
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading time

    if (await authService.isLoggedIn()) {
      // If logged in, navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } else {
      // If not logged in, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF4A148C)
            ], // Deep purple gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for an Apophen logo/icon
              const Icon(
                Icons.storefront, // Example icon
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
              const SizedBox(height: 50),
              Text(
                AppConstants.poweredBy,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
