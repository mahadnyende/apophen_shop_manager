// lib/data/models/purchases/expense_model.dart
class Expense {
  String? id; // Sembast ID for the expense record
  final String title;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final String category; // e.g., 'Rent', 'Utilities', 'Supplies', 'Salaries'

  Expense({
    this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.category = 'General',
  });

  // Convert an Expense object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'amount': amount,
      'expenseDate':
          expenseDate.toIso8601String(), // Store DateTime as ISO string
      'category': category,
    };
  }

  // Create an Expense object from a Map (retrieved from Sembast)
  factory Expense.fromMap(Map<String, dynamic> map, {String? id}) {
    return Expense(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: map['amount'] as double,
      expenseDate: DateTime.parse(map['expenseDate'] as String),
      category: map['category'] as String? ??
          'General', // Handle old data without category
    );
  }
}
