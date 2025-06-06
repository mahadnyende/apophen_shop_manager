// lib/data/models/purchases/purchase_order_model.dart
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_item_model.dart';

enum PurchaseOrderStatus {
  pending, // Created, but not yet sent/approved
  ordered, // Sent to supplier
  partiallyReceived, // Some items received
  received, // All items received
  cancelled, // Order cancelled
}

class PurchaseOrder {
  String? id; // Sembast ID for the purchase order record
  final String supplierId;
  final String supplierName; // Denormalized for easier display
  final DateTime orderDate;
  DateTime? expectedDeliveryDate;
  PurchaseOrderStatus status;
  final List<PurchaseOrderItem> items;
  final double totalCost; // Calculated total cost of all items in the PO
  String? notes;

  PurchaseOrder({
    this.id,
    required this.supplierId,
    required this.supplierName,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.status = PurchaseOrderStatus.pending,
    required this.items,
    required this.totalCost,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'orderDate': orderDate.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'status': status.name, // Store enum as string
      'items': items.map((item) => item.toMap()).toList(),
      'totalCost': totalCost,
      'notes': notes,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map, {String? id}) {
    return PurchaseOrder(
      id: id,
      supplierId: map['supplierId'] as String,
      supplierName: map['supplierName'] as String,
      orderDate: DateTime.parse(map['orderDate'] as String),
      expectedDeliveryDate: map['expectedDeliveryDate'] != null
          ? DateTime.parse(map['expectedDeliveryDate'] as String)
          : null,
      status: PurchaseOrderStatus.values.byName(map['status'] as String),
      items: (map['items'] as List<dynamic>)
          .map((itemMap) =>
              PurchaseOrderItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      totalCost: map['totalCost'] as double,
      notes: map['notes'] as String?,
    );
  }
}
