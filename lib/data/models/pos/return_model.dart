// lib/data/models/pos/return_model.dart
import 'package:apophen_shop_manager/data/models/pos/return_item_model.dart';

enum ReturnStatus {
  pending, // Return initiated
  processed, // Return fully processed and inventory/refund handled
  cancelled, // Return request cancelled
}

class Return {
  String? id; // Sembast ID for the return record
  final String originalSaleId; // Link to the original sale
  final DateTime returnDate;
  ReturnStatus status;
  final List<ReturnItem> items; // List of items being returned
  final double
      totalRefundAmount; // Total calculated refund amount for the items
  final String? customerId; // Optional: Link to a customer
  final String?
      processedByEmployeeId; // Optional: Employee who processed the return
  final String? notes; // Any additional notes about the return
  final DateTime createdAt;
  DateTime lastModified;

  Return({
    this.id,
    required this.originalSaleId,
    required this.returnDate,
    this.status = ReturnStatus.pending, // Default status
    required this.items,
    required this.totalRefundAmount,
    this.customerId,
    this.processedByEmployeeId,
    this.notes,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert to Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'originalSaleId': originalSaleId,
      'returnDate': returnDate.toIso8601String(),
      'status': status.toString().split('.').last, // Store enum as string
      'items': items.map((item) => item.toMap()).toList(),
      'totalRefundAmount': totalRefundAmount,
      'customerId': customerId,
      'processedByEmployeeId': processedByEmployeeId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Create from Map from Sembast storage
  factory Return.fromMap(Map<String, dynamic> map, {String? id}) {
    return Return(
      id: id,
      originalSaleId: map['originalSaleId'] as String,
      returnDate: DateTime.parse(map['returnDate'] as String),
      status: ReturnStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ReturnStatus.pending,
      ),
      items: (map['items'] as List<dynamic>)
          .map((itemMap) => ReturnItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      totalRefundAmount: map['totalRefundAmount'] as double,
      customerId: map['customerId'] as String?,
      processedByEmployeeId: map['processedByEmployeeId'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
