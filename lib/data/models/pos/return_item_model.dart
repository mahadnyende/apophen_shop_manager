// lib/data/models/pos/return_item_model.dart
class ReturnItem {
  final String productId;
  final String productSku;
  final String productName;
  final double unitPriceAtSale; // Price of the item when it was originally sold
  final double unitCostAtSale; // Cost of the item when it was originally sold
  int quantity; // Quantity being returned
  final String?
      returnReason; // e.g., 'Damaged', 'Wrong size', 'Customer changed mind'

  ReturnItem({
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.unitPriceAtSale,
    required this.unitCostAtSale,
    this.quantity = 1,
    this.returnReason,
  });

  // Calculate the potential refund amount for this item (excluding any original discounts on this item)
  double get potentialRefundAmount => unitPriceAtSale * quantity;

  // Convert to Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productSku': productSku,
      'productName': productName,
      'unitPriceAtSale': unitPriceAtSale,
      'unitCostAtSale': unitCostAtSale,
      'quantity': quantity,
      'returnReason': returnReason,
    };
  }

  // Create from Map from Sembast storage
  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      productId: map['productId'] as String,
      productSku: map['productSku'] as String,
      productName: map['productName'] as String,
      unitPriceAtSale: map['unitPriceAtSale'] as double,
      unitCostAtSale: map['unitCostAtSale'] as double,
      quantity: map['quantity'] as int,
      returnReason: map['returnReason'] as String?,
    );
  }
}
