// No special annotations needed for sembast; it uses plain Dart objects and maps.

class Product {
  String? id; // Sembast uses String IDs (key), typically auto-generated
  final String productSku;
  String name;
  String description;
  double price; // Selling price
  double costPrice; // Cost of the product (NEW)
  int stockQuantity;
  String category;
  DateTime createdAt;
  DateTime lastModified;

  // Constructor
  Product({
    this.id, // Sembast will set this upon insertion if null
    required this.productSku,
    required this.name,
    this.description = '',
    required this.price,
    this.costPrice = 0.0, // NEW: Initialize costPrice, default to 0.0
    required this.stockQuantity,
    this.category = 'General',
    DateTime? createdAt,
    DateTime? lastModified,
  }) :  createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert a Product object into a Map. The keys will be used as field names in Sembast.
  Map<String, dynamic> toMap() {
    return {
      'productSku': productSku,
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice, // NEW: Include costPrice in map
      'stockQuantity': stockQuantity,
      'category': category,
      'createdAt': createdAt.toIso8601String(), // Store DateTime as ISO string
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Convert a Map into a Product object.
  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    return Product(
      id: id,
      productSku: map['productSku'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      costPrice: map['costPrice'] ?? 0.0, // NEW: Retrieve costPrice, default to 0.0 for existing data
      stockQuantity: map['stockQuantity'],
      category: map['category'],
      createdAt: DateTime.parse(map['createdAt']),
      lastModified: DateTime.parse(map['lastModified']),
    );
  }

  // You can add helper methods here, e.g., for updating stock.
  void updateStock(int change) {
    stockQuantity += change;
    lastModified = DateTime.now();
  }
}
