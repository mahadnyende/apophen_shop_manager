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
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _posService.getSales().listen((sales) {
      _calculateAggregates(sales);
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

  void _calculateAggregates(List<Sale> sales) {
    double sum = 0.0;
    for (var sale in sales) {
      sum += sale.finalTotalAmount;
    }
    setState(() {
      _totalSalesAmount = sum;
      _totalTransactions = sales.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Sales Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB)
            ], // Light blue gradient for reports
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
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
            ),
            const Divider(height: 1, color: Colors.deepPurple),
            // Sales List
            Expanded(
              child: StreamBuilder<List<Sale>>(
                stream: _posService.getSales(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error loading sales: ${snapshot.error}'));
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

                  final sales = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      final saleDateFormatted =
                          DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.shopping_cart_checkout,
                                color: Colors.green),
                          ),
                          title: Text(
                            'Sale ID: ${sale.id!.substring(0, 8)}...', // Truncate ID for display
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                              'Total: \${sale.finalTotalAmount.toStringAsFixed(2)} | Date: $saleDateFormatted'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Items:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  ...sale.items
                                      .map((item) => Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0, top: 4.0),
                                            child: Text(
                                                '${item.productName} (x${item.quantity}) - \${item.finalSubtotal.toStringAsFixed(2)}'),
                                          ))
                                      .toList(),
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

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8)),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
