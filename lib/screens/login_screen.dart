import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/auth_service.dart';
import 'package:apophen_shop_manager/screens/dashboard_screen.dart';
import 'package:apophen_shop_manager/core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    final success = await _authService.login(username, password);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to ${AppConstants.appName}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            hintText: 'e.g., admin, manager, employee',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: const Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        _errorMessage != null
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox.shrink(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              backgroundColor: const Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              shadowColor: const Color(
                                0xFF4A148C,
                              ).withOpacity(0.5),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
      ),
    );
  }
}
