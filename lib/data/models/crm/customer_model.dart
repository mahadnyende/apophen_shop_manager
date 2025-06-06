// lib/data/models/crm/customer_model.dart
class Customer {
  String? id; // Sembast ID for the customer record
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String? address;
  DateTime createdAt;
  DateTime lastModified;

  Customer({
    this.id,
    required this.firstName,
    required this.lastName,
    this.email = '', // Optional
    this.phoneNumber = '', // Optional
    this.address, // Optional
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert a Customer object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt.toIso8601String(), // Store DateTime as ISO string
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Create a Customer object from a Map (retrieved from Sembast)
  factory Customer.fromMap(Map<String, dynamic> map, {String? id}) {
    return Customer(
      id: id,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }

  String get fullName => '$firstName $lastName';
}
