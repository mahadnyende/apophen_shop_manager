// lib/data/models/pos/sale_model.dart
import 'package:apophen_shop_manager/data/models/pos/sale_item_model.dart';

class Sale {
  String? id; // Sembast ID for the sale record (nullable for new sales)
  final DateTime saleDate;
  final double
      subtotalBeforeDiscount; // Total of basePrice * quantity for all items
  final double overallDiscountAmount; // Discount applied to the entire sale
  final double
      finalTotalAmount; // subtotalBeforeDiscount - overallDiscountAmount
  final List<SaleItem> items;
  final String? customerId; // Optional: Link to a customer in the future
  final String? employeeId; // Optional: Link to employee who made the sale
  final String transactionType; // e.g., 'sale', 'return', 'hold'

  Sale({
    this.id,
    required this.saleDate,
    required this.subtotalBeforeDiscount,
    this.overallDiscountAmount = 0.0, // Default overall discount
    required this.finalTotalAmount,
    required this.items,
    this.customerId,
    this.employeeId,
    this.transactionType = 'sale', // Default to 'sale'
  });

  // Convert a Sale object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'saleDate': saleDate.toIso8601String(),
      'subtotalBeforeDiscount': subtotalBeforeDiscount,
      'overallDiscountAmount': overallDiscountAmount,
      'finalTotalAmount': finalTotalAmount,
      'items': items
          .map((item) => item.toMap())
          .toList(), // Convert list of SaleItems to list of Maps
      'customerId': customerId,
      'employeeId': employeeId,
      'transactionType': transactionType,
    };
  }

  // Create a Sale object from a Map (retrieved from Sembast)
  factory Sale.fromMap(Map<String, dynamic> map, {String? id}) {
    return Sale(
      id: id,
      saleDate: DateTime.parse(map['saleDate'] as String),
      subtotalBeforeDiscount: map['subtotalBeforeDiscount'] as double,
      overallDiscountAmount: map['overallDiscountAmount'] as double? ?? 0.0,
      finalTotalAmount: map['finalTotalAmount'] as double,
      items: (map['items'] as List<dynamic>)
          .map((itemMap) => SaleItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      customerId: map['customerId'] as String?,
      employeeId: map['employeeId'] as String?,
      transactionType:
          map['transactionType'] as String? ?? 'sale', // Handle old data
    );
  }
}
