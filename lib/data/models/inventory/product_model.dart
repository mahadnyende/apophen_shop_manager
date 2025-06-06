// lib/data/models/inventory/product_model.dart
class Product {
  String? id; // Sembast ID for the product record
  String name;
  String productSku;
  String description;
  double price; // Selling price
  double costPrice; // Cost price (NEW FIELD)
  int stockQuantity;
  String category;
  DateTime createdAt;
  DateTime lastModified;

  Product({
    this.id,
    required this.name,
    required this.productSku,
    this.description = '',
    required this.price,
    required this.costPrice, // Include costPrice in the constructor
    this.stockQuantity = 0,
    this.category = 'General',
    DateTime? createdAt,
    DateTime? lastModified,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now();

  // Method to update stock quantity and lastModified date
  void updateStock(int quantityChange) {
    stockQuantity += quantityChange;
    lastModified = DateTime.now();
  }

  // Convert a Product object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'productSku': productSku,
      'description': description,
      'price': price,
      'costPrice': costPrice, // Include costPrice in toMap
      'stockQuantity': stockQuantity,
      'category': category,
      'createdAt': createdAt.toIso8601String(), // Store DateTime as ISO string
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Create a Product object from a Map (retrieved from Sembast)
  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    return Product(
      id: id,
      name: map['name'] as String,
      productSku: map['productSku'] as String,
      description: map['description'] as String? ?? '',
      price: map['price'] as double,
      costPrice: map['costPrice'] as double? ?? 0.0, // Retrieve costPrice, default to 0.0 if not present (for old data)
      stockQuantity: map['stockQuantity'] as int,
      category: map['category'] as String? ?? 'General',
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
