class PurchaseOrderItem {
  final String productId;
  final String productSku;
  final String productName;
  final double orderedUnitCost; // Cost at the time of placing the order
  int orderedQuantity;
  int receivedQuantity; // How many of this item have been received so far

  PurchaseOrderItem({
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.orderedUnitCost,
    this.orderedQuantity = 1,
    this.receivedQuantity = 0,
  });

  // Calculate the total cost for this item on the PO
  double get totalItemCost => orderedUnitCost * orderedQuantity;

  // Convert to Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productSku': productSku,
      'productName': productName,
      'orderedUnitCost': orderedUnitCost,
      'orderedQuantity': orderedQuantity,
      'receivedQuantity': receivedQuantity,
    };
  }

  // Create from Map from Sembast storage
  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      productId: map['productId'] as String,
      productSku: map['productSku'] as String,
      productName: map['productName'] as String,
      orderedUnitCost: map['orderedUnitCost'] as double,
      orderedQuantity: map['orderedQuantity'] as int,
      receivedQuantity: map['receivedQuantity'] as int? ?? 0, // Handle old data without receivedQuantity
    );
  }
}
