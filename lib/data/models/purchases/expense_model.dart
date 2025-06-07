// lib/data/models/purchases/expense_model.dart
class Expense {
  String? id; // Sembast ID for the expense record
  String title; // A brief description of the expense
  String? description; // More detailed description
  double amount;
  DateTime expenseDate;
  String category; // E.g., 'Rent', 'Utilities', 'Salaries', 'Office Supplies'
  DateTime createdAt;
  DateTime lastModified;

  Expense({
    this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.category = 'Other',
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  // Convert an Expense object to a Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'amount': amount,
      'expenseDate':
          expenseDate.toIso8601String(), // Store DateTime as ISO string
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
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
      category: map['category'] as String? ?? 'Other',
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }
}
