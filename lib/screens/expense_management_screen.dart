import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/purchases/expense_model.dart';
import 'package:apophen_shop_manager/services/expense_service.dart';
import 'package:intl/intl.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() => _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // List of common expense categories for a dropdown or suggestion
  final List<String> _expenseCategories = [
    'Rent', 'Utilities', 'Salaries', 'Supplies', 'Marketing',
    'Maintenance', 'Transportation', 'Taxes', 'Miscellaneous'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _expenseService.dispose(); // Dispose the stream controller
    super.dispose();
  }

  void _clearControllers() {
    _titleController.clear();
    _descriptionController.clear();
    _amountController.clear();
    _dateController.clear();
    _categoryController.clear();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addExpense() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (Title, Amount, Date, Category)!')),
      );
      return;
    }

    try {
      final expense = Expense(
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        amount: double.parse(_amountController.text),
        expenseDate: DateTime.parse(_dateController.text),
        category: _categoryController.text,
      );
      await _expenseService.addExpense(expense);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add expense: ${e.toString()}')),
      );
    }
  }

  void _updateExpense(Expense expense) async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields for update!')),
      );
      return;
    }

    try {
      final updatedExpense = Expense(
        id: expense.id, // Keep existing ID
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        amount: double.parse(_amountController.text),
        expenseDate: DateTime.parse(_dateController.text),
        category: _categoryController.text,
      );
      await _expenseService.updateExpense(updatedExpense);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update expense: ${e.toString()}')),
      );
    }
  }

  void _showExpenseDialog(BuildContext context, {Expense? expense}) {
    _clearControllers(); // Clear controllers before showing dialog
    if (expense != null) {
      // Populate if editing an existing expense
      _titleController.text = expense.title;
      _descriptionController.text = expense.description ?? '';
      _amountController.text = expense.amount.toString();
      _dateController.text = DateFormat('yyyy-MM-dd').format(expense.expenseDate);
      _categoryController.text = expense.category;
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default to today for new expense
      _categoryController.text = _expenseCategories.first; // Default to first category
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(expense == null ? 'Add New Expense' : 'Edit Expense: ${expense.title}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title*'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                ),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount*'),
                  keyboardType: TextInputType.number,
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date*',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _categoryController.text.isNotEmpty ? _categoryController.text : _expenseCategories.first,
                  decoration: const InputDecoration(labelText: 'Category*'),
                  items: _expenseCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _categoryController.text = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearControllers();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (expense == null) {
                  _addExpense();
                } else {
                  _updateExpense(expense);
                }
                Navigator.of(context).pop();
              },
              child: Text(expense == null ? 'Add Expense' : 'Save Changes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Add New Expense',
            onPressed: () => _showExpenseDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)], // Light orange gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Expense>>(
          stream: _expenseService.getExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No expenses recorded. Add your first expense!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final expenses = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.receipt, color: Colors.orange),
                    ),
                    title: Text(
                      expense.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${expense.category}'),
                        if (expense.description != null && expense.description!.isNotEmpty)
                          Text('Description: ${expense.description}'),
                        Text('Date: ${DateFormat('MMM d,yyyy').format(expense.expenseDate.toLocal())}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '-\$${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showExpenseDialog(context, expense: expense);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _expenseService.deleteExpense(expense.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${expense.title} deleted!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
