// lib/data/models/crm/employee_model.dart
class Employee {
  String? id; // Sembast ID for the employee record
  final String name;
  final String role; // e.g., 'Manager', 'Sales Associate', 'Admin'
  final String? email;
  final String? phone;
  final DateTime hireDate;
  DateTime lastModified;

  Employee({
    this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    DateTime? hireDate,
    DateTime? lastModified,
  })  : hireDate = hireDate ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'hireDate': hireDate.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map, {String? id}) {
    return Employee(
      id: id,
      name: map['name'] as String,
      role: map['role'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      hireDate: DateTime.parse(map['hireDate'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
