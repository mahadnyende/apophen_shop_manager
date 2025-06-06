enum UserRole { admin, manager, employee, unknown }

class User {
  final String id;
  final String username;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    this.role = UserRole.employee,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role.toString().split('.').last,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.unknown,
      ),
    );
  }
}
