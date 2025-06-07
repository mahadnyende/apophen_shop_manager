import 'package:shared_preferences/shared_preferences.dart';
import 'package:apophen_shop_manager/models/user_model.dart';
import 'package:apophen_shop_manager/core/constants/app_constants.dart';
import 'package:apophen_shop_manager/services/user_service.dart'; // Import UserService
import 'package:apophen_shop_manager/data/local/database/app_database.dart'; // FIX: Import AppDatabase

class AuthService {
  final UserService _userService = UserService();

  // Attempts to log in the user using the UserService
  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final user = await _userService.findUser(username, password);

      if (user != null) {
        // Successful login
        // For local-first, we store a "logged in" state and user info
        await prefs.setString(AppConstants.loginTokenKey, user.id!); // Using user ID as a simple "token"
        await prefs.setString(AppConstants.userRoleKey, user.role.toString().split('.').last);
        await prefs.setString(AppConstants.currentUserIdKey, user.id!);
        print('Login successful for ${user.username} with role ${user.role.toString().split('.').last}.');
        return true;
      } else {
        print('Login failed: Invalid username or password.');
        return false;
      }
    } catch (e) {
      print('Login failed due to an error: $e.');
      return false;
    }
  }

  // Checks if a user is currently logged in locally
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.loginTokenKey);
    return token != null;
  }

  // Retrieves the locally stored user role
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

  // Retrieves the locally stored current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.currentUserIdKey);
  }

  // Logs out the user by clearing local storage
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.loginTokenKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.currentUserIdKey);
    print('User logged out. Local token and role cleared.');
  }

  // For initial setup or if no admin exists: create a default admin
  // This method should ideally be called only once when the app is first launched or db is empty.
  Future<void> createDefaultAdminUser() async {
    // FIX: Use _userService.hasUsers() instead of direct store access
    final hasExistingUsers = await _userService.hasUsers();
    if (!hasExistingUsers) { // Only create if no users exist
      print('No users found. Creating default admin user...');
      final adminUser = User(
        username: 'admin',
        password: 'password', // In production, hash this password!
        role: UserRole.admin,
      );
      try {
        await _userService.addUser(adminUser);
        print('Default admin user "admin" created.');
      } catch (e) {
        print('Failed to create default admin user: $e');
      }
    }
  }
}
