// lib/data/models/pos/sale_item_model.dart
class SaleItem {
  final String productId;
  final String productSku;
  final String productName; // Denormalized for easier display
  final double basePrice; // Original unit selling price
  final double costPrice; // Cost price at the time of sale (NEW FIELD)
  int quantity;
  final double itemDiscount; // Discount applied to this single item's line total

  // Getters for calculated values
  double get subtotalBeforeDiscount => basePrice * quantity;
  double get finalSubtotal => (basePrice * quantity) - itemDiscount;
  double get grossProfit => (basePrice - costPrice) * quantity - itemDiscount; // Calculate gross profit for the item

  SaleItem({
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.basePrice,
    required this.costPrice, // Added costPrice to constructor
    this.quantity = 1, // Default quantity
    this.itemDiscount = 0.0, // Default item discount
  });

  // Convert a SaleItem object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productSku': productSku,
      'productName': productName,
      'basePrice': basePrice,
      'costPrice': costPrice, // Include costPrice in toMap
      'quantity': quantity,
      'itemDiscount': itemDiscount,
    };
  }

  // Create a SaleItem object from a Map (retrieved from Sembast)
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] as String,
      productSku: map['productSku'] as String,
      productName: map['productName'] as String,
      basePrice: map['basePrice'] as double,
      costPrice: map['costPrice'] as double? ?? 0.0, // Retrieve costPrice, default to 0.0 for old data
      quantity: map['quantity'] as int,
      itemDiscount: map['itemDiscount'] as double? ?? 0.0, // Handle old data without discount
    );
  }
}
