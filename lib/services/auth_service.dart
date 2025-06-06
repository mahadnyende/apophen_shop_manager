import 'package:shared_preferences/shared_preferences.dart';
import 'package:apophen_shop_manager/models/user_model.dart';
import 'package:apophen_shop_manager/core/constants/app_constants.dart';

class AuthService {
  Future<Map<String, dynamic>?> _authenticateOnServer(
    String username,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    if (username == 'admin' && password == 'password') {
      return {
        'token': 'dummy_admin_token_123',
        'user': {'id': 'user_1', 'username': 'admin', 'role': 'admin'},
      };
    } else if (username == 'manager' && password == 'password') {
      return {
        'token': 'dummy_manager_token_456',
        'user': {'id': 'user_2', 'username': 'manager', 'role': 'manager'},
      };
    } else if (username == 'employee' && password == 'password') {
      return {
        'token': 'dummy_employee_token_789',
        'user': {'id': 'user_3', 'username': 'employee', 'role': 'employee'},
      };
    }
    return null;
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(AppConstants.loginTokenKey);
    final storedUserRole = prefs.getString(AppConstants.userRoleKey);

    if (storedToken != null &&
        storedUserRole != null &&
        storedUserRole == UserRole.admin.toString().split('.').last &&
        username == 'admin' &&
        password == 'password') {
      return true;
    }

    final response = await _authenticateOnServer(username, password);

    if (response != null &&
        response['token'] != null &&
        response['user'] != null) {
      final token = response['token'];
      final userData = response['user'];
      final user = User.fromJson(userData);

      await prefs.setString(AppConstants.loginTokenKey, token);
      await prefs.setString(
        AppConstants.userRoleKey,
        user.role.toString().split('.').last,
      );
      await prefs.setString(AppConstants.currentUserIdKey, user.id);
      return true;
    }
    return false;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.loginTokenKey);
    return token != null;
  }

  Future<UserRole> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(AppConstants.userRoleKey);
    if (roleString != null) {
      return UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == roleString,
        orElse: () => UserRole.unknown,
      );
    }
    return UserRole.unknown;
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.currentUserIdKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.loginTokenKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.currentUserIdKey);
  }
}
