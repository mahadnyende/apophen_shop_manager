import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/screens/splash_screen.dart';
import 'package:apophen_shop_manager/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart'; // Import AppDatabase
import 'package:apophen_shop_manager/services/auth_service.dart'; // NEW: Import AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize shared preferences for simple key-value storage
  await SharedPreferences.getInstance();
  // Initialize Sembast database for structured data storage
  await AppDatabase.initialize(); // Initialize Sembast database

  // NEW: Create a default admin user if none exists
  final authService = AuthService();
  await authService.createDefaultAdminUser();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
