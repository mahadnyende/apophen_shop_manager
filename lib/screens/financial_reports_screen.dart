// lib/screens/financial_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/pos_service.dart';
import 'package:apophen_shop_manager/services/expense_service.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/expense_model.dart';
import 'package:intl/intl.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final POSService _posService = POSService();
  final ExpenseService _expenseService = ExpenseService();

  double _totalSalesRevenue = 0.0;
  double _totalExpenses = 0.0;
  double _netProfit = 0.0;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Sale> _allSales = [];
  List<Expense> _allExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  @override
  void dispose() {
    _posService.dispose();
    _expenseService.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    // Listen to sales stream
    _posService.getSales().listen((sales) {
      _allSales = sales;
      _calculateFinancials();
    }, onError: (error) {
      print('Error loading sales for financial reports: $error');
    });

    // Listen to expenses stream
    _expenseService.getExpenses().listen((expenses) {
      _allExpenses = expenses;
      _calculateFinancials();
    }, onError: (error) {
      print('Error loading expenses for financial reports: $error');
    });
  }

  void _calculateFinancials() {
    // Filter sales and expenses by date range
    final filteredSales = _allSales
        .where((sale) =>
            sale.saleDate
                .isAfter(_startDate.subtract(const Duration(days: 1))) &&
            sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    final filteredExpenses = _allExpenses
        .where((expense) =>
            expense.expenseDate
                .isAfter(_startDate.subtract(const Duration(days: 1))) &&
            expense.expenseDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    double salesSum =
        filteredSales.fold(0.0, (sum, sale) => sum + sale.finalTotalAmount);
    double expensesSum =
        filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    setState(() {
      _totalSalesRevenue = salesSum;
      _totalExpenses = expensesSum;
      _netProfit = salesSum - expensesSum;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(
          const Duration(days: 365)), // Up to one year in future for reporting
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _calculateFinancials(); // Recalculate with new date range
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            tooltip: 'Select Date Range',
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9)
            ], // Light green gradient for financial reports
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Date Range Display
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range,
                          color: Colors.deepPurple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Report Period: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectDateRange(context),
                        child: const Text('Change',
                            style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ),
              ),
              // Summary Cards
              _buildSummaryCard(
                'Total Sales Revenue',
                '\$${_totalSalesRevenue.toStringAsFixed(2)}',
                Colors.green,
                Icons.attach_money,
              ),
              _buildSummaryCard(
                'Total Expenses',
                '\$${_totalExpenses.toStringAsFixed(2)}',
                Colors.redAccent,
                Icons.money_off,
              ),
              _buildSummaryCard(
                'Net Profit',
                '\$${_netProfit.toStringAsFixed(2)}',
                _netProfit >= 0 ? Colors.blueAccent : Colors.orange,
                _netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
              const SizedBox(height: 20),
              const Text(
                'Detailed Breakdown (Future Enhancement)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              // You can add more detailed lists or charts here in the future
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
