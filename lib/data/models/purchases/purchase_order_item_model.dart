// lib/data/models/purchases/purchase_order_item_model.dart
class PurchaseOrderItem {
  final String productId;
  final String productSku;
  final String productName; // Denormalized for easier display
  int orderedQuantity;
  double costPrice; // Cost price per unit at the time of ordering
  int receivedQuantity; // Quantity actually received for this item

  PurchaseOrderItem({
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.orderedQuantity,
    required this.costPrice,
    this.receivedQuantity = 0, // Default to 0 received
  });

  // Calculate the total cost for this item line
  double get totalCost => orderedQuantity * costPrice;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productSku': productSku,
      'productName': productName,
      'orderedQuantity': orderedQuantity,
      'costPrice': costPrice,
      'receivedQuantity': receivedQuantity,
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      productId: map['productId'] as String,
      productSku: map['productSku'] as String,
      productName: map['productName'] as String,
      orderedQuantity: map['orderedQuantity'] as int,
      costPrice: map['costPrice'] as double,
      receivedQuantity: map['receivedQuantity'] as int? ?? 0,
    );
  }
}
