import 'package:apophen_shop_manager/data/models/pos/sale_item_model.dart';

import 'package:apophen_shop_manager/data/models/pos/sale_item_model.dart';

class Sale {
  String? id; // Sembast ID for the sale record
  final DateTime saleDate;
  final double subtotalBeforeDiscount; // Total of basePrice * quantity for all items
  final double overallDiscountAmount; // Discount applied to the entire sale
  final double finalTotalAmount; // subtotalBeforeDiscount - overallDiscountAmount
  final List<SaleItem> items;
  final String? customerId; // Optional: Link to a customer in the future
  final String? employeeId; // Optional: Link to employee who made the sale
  final String transactionType; // e.g., 'sale', 'return', 'hold' - NEW FIELD

  Sale({
    this.id,
    required this.saleDate,
    required this.subtotalBeforeDiscount,
    this.overallDiscountAmount = 0.0,
    required this.finalTotalAmount,
    required this.items,
    this.customerId,
    this.employeeId,
    this.transactionType = 'sale', // Default to 'sale'
  });

  Map<String, dynamic> toMap() {
    return {
      'saleDate': saleDate.toIso8601String(),
      'subtotalBeforeDiscount': subtotalBeforeDiscount,
      'overallDiscountAmount': overallDiscountAmount,
      'finalTotalAmount': finalTotalAmount,
      'items': items.map((item) => item.toMap()).toList(),
      'customerId': customerId,
      'employeeId': employeeId,
      'transactionType': transactionType,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, {String? id}) {
    return Sale(
      id: id,
      saleDate: DateTime.parse(map['saleDate']),
      subtotalBeforeDiscount: map['subtotalBeforeDiscount'],
      overallDiscountAmount: map['overallDiscountAmount'] ?? 0.0,
      finalTotalAmount: map['finalTotalAmount'],
      items: (map['items'] as List).map((itemMap) => SaleItem.fromMap(itemMap)).toList(),
      customerId: map['customerId'],
      employeeId: map['employeeId'],
      transactionType: map['transactionType'] ?? 'sale', // Handle old data
    );
  }
}
