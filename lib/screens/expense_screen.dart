// lib/screens/expense_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/expense_service.dart';
import 'package:apophen_shop_manager/data/models/purchases/expense_model.dart';
import 'package:intl/intl.dart'; // Required for date formatting

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DateTime? _selectedExpenseDate;

  // Predefined expense categories for easy selection
  final List<String> _expenseCategories = [
    'Rent',
    'Utilities',
    'Salaries',
    'Office Supplies',
    'Marketing',
    'Maintenance',
    'Travel',
    'Other'
  ];
  String _selectedCategory = 'Other';

  @override
  void initState() {
    super.initState();
    _selectedExpenseDate = DateTime.now(); // Default to today's date
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _expenseService.dispose(); // Dispose the stream controller
    super.dispose();
  }

  void _clearControllers() {
    _titleController.clear();
    _descriptionController.clear();
    _amountController.clear();
    _categoryController.clear();
    setState(() {
      _selectedExpenseDate = DateTime.now();
      _selectedCategory = 'Other';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpenseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedExpenseDate) {
      setState(() {
        _selectedExpenseDate = picked;
      });
    }
  }

  void _addExpense() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedExpenseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, Amount, and Date are required!')),
      );
      return;
    }
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount!')),
      );
      return;
    }

    try {
      final expense = Expense(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        amount: amount,
        expenseDate: _selectedExpenseDate!,
        category: _selectedCategory,
      );
      await _expenseService.addExpense(expense);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Expense "${expense.title}" added successfully!')),
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
        _selectedExpenseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title, Amount, and Date are required for update!')),
      );
      return;
    }
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount!')),
      );
      return;
    }

    try {
      final updatedExpense = Expense(
        id: expense.id, // Keep the existing ID
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        amount: amount,
        expenseDate: _selectedExpenseDate!,
        category: _selectedCategory,
        createdAt: expense.createdAt, // Preserve original creation date
        lastModified: DateTime.now(), // Update last modified date
      );
      await _expenseService.updateExpense(updatedExpense);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Expense "${updatedExpense.title}" updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update expense: ${e.toString()}')),
      );
    }
  }

  void _showAddEditExpenseDialog({Expense? expense}) {
    _clearControllers(); // Clear for new, or will be populated below for edit
    bool isEditing = expense != null;

    if (isEditing) {
      _titleController.text = expense.title;
      _descriptionController.text = expense.description ?? '';
      _amountController.text = expense.amount.toString();
      _selectedExpenseDate = expense.expenseDate;
      _selectedCategory = expense.category;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Expense' : 'Add New Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Description (Optional)'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Amount *'),
                      keyboardType: TextInputType.number,
                    ),
                    ListTile(
                      title: Text(
                          'Expense Date: ${_selectedExpenseDate == null ? 'Select Date *' : DateFormat('yyyy-MM-dd').format(_selectedExpenseDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedExpenseDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null &&
                            pickedDate != _selectedExpenseDate) {
                          setStateInDialog(() {
                            // Update dialog's state
                            _selectedExpenseDate = pickedDate;
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category'),
                      value: _selectedCategory,
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          // Update dialog's state
                          _selectedCategory = newValue!;
                        });
                      },
                      items: _expenseCategories
                          .map<DropdownMenuItem<String>>((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearControllers(); // Clear on cancel
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isEditing) {
                      _updateExpense(expense!);
                    } else {
                      _addExpense();
                    }
                    Navigator.of(context)
                        .pop(); // Close dialog after action attempt
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracking',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add New Expense',
            onPressed: () => _showAddEditExpenseDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFBE9E7),
              Color(0xFFFFCCBC)
            ], // Light red/orange gradient for expenses
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
                      'No expenses recorded yet. Start tracking!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final expenses = snapshot.data!;
            // Sort by date (most recent first)
            expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

            // Calculate total expenses for display
            double totalExpenses =
                expenses.fold(0.0, (sum, item) => sum + item.amount);

            return Column(
              children: [
                // Total Expenses Summary Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    elevation: 6,
                    color: Colors.redAccent.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Expenses:',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                              Text(
                                'All Recorded',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(
                            '\$${totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
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
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child:
                                const Icon(Icons.money_off, color: Colors.red),
                          ),
                          title: Text(
                            expense.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Category: ${expense.category}'),
                              Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(expense.expenseDate)}'),
                              if (expense.description != null &&
                                  expense.description!.isNotEmpty)
                                Text('Description: ${expense.description}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '-\$${expense.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () {
                                  _showAddEditExpenseDialog(expense: expense);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  await _expenseService
                                      .deleteExpense(expense.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Expense "${expense.title}" deleted!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
