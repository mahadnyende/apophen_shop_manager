// lib/data/models/purchases/supplier_model.dart
class Supplier {
  String? id; // Sembast ID for the supplier record
  String name; // Supplier company name
  String contactPerson; // Primary contact at the supplier
  String phoneNumber;
  String email;
  String? address;
  DateTime createdAt;
  DateTime lastModified;

  Supplier({
    this.id,
    required this.name,
    required this.contactPerson,
    this.phoneNumber = '',
    this.email = '',
    this.address,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert a Supplier object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(), // Store DateTime as ISO string
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Create a Supplier object from a Map (retrieved from Sembast)
  factory Supplier.fromMap(Map<String, dynamic> map, {String? id}) {
    return Supplier(
      id: id,
      name: map['name'] as String,
      contactPerson: map['contactPerson'] as String,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
