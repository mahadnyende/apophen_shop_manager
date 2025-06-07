// lib/models/user_model.dart
enum UserRole {
  admin,
  manager,
  employee,
  unknown,
}

class User {
  String? id; // Sembast ID for the user record
  final String username;
  String
      password; // NEW: Added password field (for demo, would be hashed in production)
  final UserRole role;
  final DateTime createdAt;
  DateTime lastModified;

  User({
    this.id,
    required this.username,
    required this.password, // NEW
    this.role = UserRole.employee,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert User object to a JSON-like map for Sembast
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password, // NEW
      'role': role.toString().split('.').last, // Convert enum to string
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Create User object from a JSON-like map from Sembast
  factory User.fromMap(Map<String, dynamic> map, {String? id}) {
    return User(
      id: id,
      username: map['username'] as String,
      password: map['password'] as String, // NEW
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.unknown,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
