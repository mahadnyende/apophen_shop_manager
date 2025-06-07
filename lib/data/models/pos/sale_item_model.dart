// lib/data/models/pos/sale_item_model.dart
class SaleItem {
  final String productId;
  final String productSku;
  final String productName;
  final double basePrice; // Original selling price of the product
  final double costPrice; // Cost of the product at the time of sale (NEW)
  final double itemDiscount; // Discount applied to this specific item (NEW)
  int quantity;
  double get finalSubtotal =>
      (basePrice * quantity) -
      itemDiscount; // Calculate subtotal after discount (NEW)
  double get grossProfit => (finalSubtotal -
      (costPrice * quantity)); // Calculate gross profit for this item (NEW)

  SaleItem({
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.basePrice, // Changed from price to basePrice
    required this.costPrice, // NEW
    this.itemDiscount = 0.0, // NEW, default to 0
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productSku': productSku,
      'productName': productName,
      'basePrice': basePrice,
      'costPrice': costPrice, // NEW
      'itemDiscount': itemDiscount, // NEW
      'quantity': quantity,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'],
      productSku: map['productSku'],
      productName: map['productName'],
      basePrice: map['basePrice'], // Changed from price to basePrice
      costPrice: map['costPrice'], // NEW
      itemDiscount:
          map['itemDiscount'] ?? 0.0, // NEW, handle potential null for old data
      quantity: map['quantity'],
    );
  }
}
