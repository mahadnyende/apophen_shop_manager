class Customer {
  String? id; // Sembast ID for the customer record
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  DateTime lastModified;

  Customer({
    this.id,
    required this.name,
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
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, {String? id}) {
    return Customer(
      id: id,
      name: map['name'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
