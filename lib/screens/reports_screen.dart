// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/pos_service.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_model.dart';
import 'package:intl/intl.dart'; // For date formatting, will need to add to pubspec.yaml

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final POSService _posService = POSService();
  double _totalSalesAmount = 0.0;
  double _totalCostOfGoodsSold = 0.0; // New field for Cost of Goods Sold
  double _grossProfit = 0.0; // New field for Gross Profit
  int _totalTransactions = 0;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30)); // Default to last 30 days
  DateTime _endDate = DateTime.now();

  List<Sale> _allSales = []; // Store all sales to filter later

  @override
  void initState() {
    super.initState();
    _posService.getSales().listen((sales) {
      _allSales = sales; // Cache all sales
      _calculateAggregates(); // Calculate aggregates based on current date range
    }, onError: (error) {
      print('Error listening to sales stream in reports: $error');
      // Potentially show a user-friendly error message
    });
  }

  @override
  void dispose() {
    _posService.dispose(); // Dispose POS service's internal streams if any
    super.dispose();
  }

  void _calculateAggregates() {
    // Filter sales based on the selected date range
    final filteredSales = _allSales.where((sale) =>
        sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) && // Inclusive start date
        sale.saleDate.isBefore(_endDate.add(const Duration(days: 1)))) // Inclusive end date
        .toList();

    double salesSum = 0.0;
    double cogsSum = 0.0; // Cost of Goods Sold sum
    for (var sale in filteredSales) { // Use filtered sales for calculations
      salesSum += sale.finalTotalAmount; // Total revenue from sales
      for (var item in sale.items) {
        cogsSum += item.costPrice * item.quantity; // Sum of cost price * quantity for each item
      }
    }
    setState(() {
      _totalSalesAmount = salesSum;
      _totalCostOfGoodsSold = cogsSum;
      _grossProfit = salesSum - cogsSum; // Calculate gross profit
      _totalTransactions = filteredSales.length; // Count filtered transactions
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // Allow selection from a historical date
      lastDate: DateTime.now().add(const Duration(days: 365)), // Up to one year in future for reporting
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _calculateAggregates(); // Recalculate with new date range
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reports', style: TextStyle(color: Colors.white)),
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
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // Light blue gradient for reports
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Date Range Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.deepPurple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Period: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectDateRange(context),
                        child: const Text('Change', style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column( // Use Column to stack cards vertically
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryCard(
                        'Total Sales',
                        '\$${_totalSalesAmount.toStringAsFixed(2)}',
                        Icons.monetization_on,
                        Colors.green,
                      ),
                      _buildSummaryCard(
                        'Transactions',
                        '$_totalTransactions',
                        Icons.receipt_long,
                        Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Spacing between rows of cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryCard(
                        'Cost of Goods Sold',
                        '\$${_totalCostOfGoodsSold.toStringAsFixed(2)}',
                        Icons.money_off,
                        Colors.orange, // Different color for COGS
                      ),
                      _buildSummaryCard(
                        'Gross Profit',
                        '\$${_grossProfit.toStringAsFixed(2)}',
                        Icons.trending_up,
                        _grossProfit >= 0 ? Colors.teal : Colors.red, // Color based on profit
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.deepPurple),
            // Sales List
            Expanded(
              child: StreamBuilder<List<Sale>>(
                stream: _posService.getSales(), // Still listen to all sales
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading sales: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'No sales recorded yet. Start selling!',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter sales for display as well
                  final displaySales = snapshot.data!.where((sale) =>
                      sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                      sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
                      .toList();

                  if (displaySales.isEmpty) {
                     return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_off, size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'No sales found for the selected date range.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: displaySales.length,
                    itemBuilder: (context, index) {
                      final sale = displaySales[index];
                      final saleDateFormatted = DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.shopping_cart_checkout, color: Colors.green),
                          ),
                          title: Text(
                            'Sale ID: ${sale.id!.substring(0, 8)}... from ${sale.customerId ?? 'Walk-in'}', // Added customer info
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column( // Use Column for multiple subtitle lines
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total: \$${sale.finalTotalAmount.toStringAsFixed(2)} | Date: $saleDateFormatted'),
                              // Calculate gross profit for this specific sale for display
                              Text('Profit: \$${(sale.finalTotalAmount - sale.items.fold(0.0, (sum, item) => sum + (item.costPrice * item.quantity))).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: (sale.finalTotalAmount - sale.items.fold(0.0, (sum, item) => sum + (item.costPrice * item.quantity))) >= 0
                                      ? Colors.blue
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...sale.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${item.productName} (x${item.quantity}) - \$${item.finalSubtotal.toStringAsFixed(2)}'),
                                        Text('Cost: \$${item.costPrice.toStringAsFixed(2)} | Selling: \$${item.basePrice.toStringAsFixed(2)} | Item Discount: \$${item.itemDiscount.toStringAsFixed(2)}'),
                                        Text('Item Profit: \$${item.grossProfit.toStringAsFixed(2)}', style: TextStyle(
                                          color: item.grossProfit >= 0 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        )),
                                        const Divider(height: 8, color: Colors.grey),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 6,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
