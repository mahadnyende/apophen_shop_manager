class SaleItem {
  final String productId;
  final String productSku;
  final String productName;
  final double basePrice; // Original unit price before any discounts
  int quantity;
  final double itemDiscount; // Discount applied to this single item's line total

  // Getters for calculated values
  double get subtotalBeforeDiscount => basePrice * quantity;
  double get finalSubtotal => (basePrice * quantity) - itemDiscount;

  SaleItem({
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.basePrice,
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
      quantity: map['quantity'] as int,
      itemDiscount: map['itemDiscount'] as double? ?? 0.0, // Handle old data without discount
    );
  }
}
