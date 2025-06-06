import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/auth_service.dart';
import 'package:apophen_shop_manager/screens/login_screen.dart';
import 'package:apophen_shop_manager/models/user_model.dart';
import 'package:apophen_shop_manager/core/constants/app_constants.dart';
import 'package:apophen_shop_manager/screens/inventory_screen.dart';
import 'package:apophen_shop_manager/screens/pos_screen.dart';
import 'package:apophen_shop_manager/screens/reports_screen.dart';
import 'package:apophen_shop_manager/screens/customer_screen.dart';
import 'package:apophen_shop_manager/screens/supplier_screen.dart';
import 'package:apophen_shop_manager/screens/purchase_order_screen.dart'; // Import the new Purchase Order screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  UserRole _userRole = UserRole.unknown;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final role = await _authService.getUserRole();
    final userId = await _authService.getCurrentUserId();
    setState(() {
      _userRole = role;
      _userId = userId;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, // Clear all routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.dashboard,
                  size: 100,
                  color: Colors.deepPurple[400],
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome, ${_userRole.toString().split('.').last.toUpperCase()}!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (_userId != null)
                  Text(
                    'User ID: $_userId',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                const Text(
                  'You have successfully logged in. This is your main dashboard.',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Dashboard Features
                Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.inventory,
                      title: 'Inventory',
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const InventoryScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.point_of_sale,
                      title: 'POS',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const POSScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.bar_chart,
                      title: 'Reports',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ReportsScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.group,
                      title: 'Customers',
                      color: Colors.pink,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const CustomerScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.local_shipping, // Icon for Suppliers
                      title: 'Suppliers',
                      color: Colors.teal, // Color for Suppliers
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SupplierScreen()),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.receipt_long, // Icon for Purchases/Expenses
                      title: 'Purchases',
                      color: Colors.deepPurple, // Color for Purchases
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const PurchaseOrderScreen()), // Navigate to PurchaseOrderScreen
                        );
                      },
                    ),
                    _buildDashboardCard(icon: Icons.people, title: 'Employees', color: Colors.purple), // Adjusted color
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      AppConstants.poweredBy,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({required IconData icon, required String title, required Color color, VoidCallback? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 6,
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to $title... (Feature coming soon)')),
          );
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
          width: 140,
          height: 140,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
