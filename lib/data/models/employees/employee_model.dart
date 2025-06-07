// lib/data/models/employees/employee_model.dart
class Employee {
  String? id; // Sembast ID for the employee record
  String firstName;
  String lastName;
  String position; // e.g., 'Manager', 'Sales Associate', 'Cashier'
  String phoneNumber;
  String email;
  DateTime hireDate;
  String? address;
  double? salary; // Optional
  DateTime createdAt;
  DateTime lastModified;

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    this.phoneNumber = '',
    this.email = '',
    required this.hireDate,
    this.address,
    this.salary,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert an Employee object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'position': position,
      'phoneNumber': phoneNumber,
      'email': email,
      'hireDate': hireDate.toIso8601String(), // Store DateTime as ISO string
      'address': address,
      'salary': salary,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Create an Employee object from a Map (retrieved from Sembast)
  factory Employee.fromMap(Map<String, dynamic> map, {String? id}) {
    return Employee(
      id: id,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      position: map['position'] as String,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      hireDate: DateTime.parse(map['hireDate'] as String),
      address: map['address'] as String?,
      salary: map['salary'] as double?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }

  String get fullName => '$firstName $lastName';
}
