import 'package:apophen_shop_manager/data/models/purchases/purchase_order_item_model.dart';

enum PurchaseOrderStatus {
  pending, // PO created but not yet sent to supplier
  ordered, // PO sent to supplier, awaiting delivery
  partiallyReceived, // Some items received, but not all
  received, // All items on PO have been received
  cancelled, // PO was cancelled
}

class PurchaseOrder {
  String? id; // Sembast ID for the purchase order record
  final String supplierId;
  final String supplierName; // To display supplier name without fetching full object
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  PurchaseOrderStatus status;
  final List<PurchaseOrderItem> items;
  final double totalOrderAmount; // Calculated from items' totalItemCost
  final DateTime createdAt;
  DateTime lastModified;

  PurchaseOrder({
    this.id,
    required this.supplierId,
    required this.supplierName,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.status = PurchaseOrderStatus.pending, // Default status
    required this.items,
    required this.totalOrderAmount,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert to Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'orderDate': orderDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'status': status.toString().split('.').last, // Store enum as string
      'items': items.map((item) => item.toMap()).toList(),
      'totalOrderAmount': totalOrderAmount,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Create from Map from Sembast storage
  factory PurchaseOrder.fromMap(Map<String, dynamic> map, {String? id}) {
    return PurchaseOrder(
      id: id,
      supplierId: map['supplierId'] as String,
      supplierName: map['supplierName'] as String,
      orderDate: DateTime.parse(map['orderDate'] as String),
      expectedDeliveryDate: map['expectedDeliveryDate'] != null
          ? DateTime.parse(map['expectedDeliveryDate'] as String)
          : null,
      status: PurchaseOrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => PurchaseOrderStatus.pending,
      ),
      items: (map['items'] as List<dynamic>)
          .map((itemMap) => PurchaseOrderItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      totalOrderAmount: map['totalOrderAmount'] as double,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }

  // Check if the PO is fully received
  bool get isFullyReceived {
    return items.every((item) => item.orderedQuantity == item.receivedQuantity);
  }
}
