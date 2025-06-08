class Supplier {
  String? id; // Sembast ID for the supplier record
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  DateTime lastModified;

  Supplier({
    this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map, {String? id}) {
    return Supplier(
      id: id,
      name: map['name'] as String,
      contactPerson: map['contactPerson'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
