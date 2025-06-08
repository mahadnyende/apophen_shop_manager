// lib/screens/customer_purchase_history_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/crm/customer_model.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_model.dart';
import 'package:apophen_shop_manager/services/pos_service.dart';
import 'package:intl/intl.dart';

class CustomerPurchaseHistoryScreen extends StatefulWidget {
  final Customer customer;

  const CustomerPurchaseHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerPurchaseHistoryScreen> createState() =>
      _CustomerPurchaseHistoryScreenState();
}

class _CustomerPurchaseHistoryScreenState
    extends State<CustomerPurchaseHistoryScreen> {
  final POSService _posService = POSService();
  List<Sale> _customerSales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerSales();
  }

  @override
  void dispose() {
    _posService.dispose(); // Dispose the stream listener
    super.dispose();
  }

  void _loadCustomerSales() {
    _posService.getSales().listen((allSales) {
      final salesForCustomer = allSales
          .where((sale) => sale.customerId == widget.customer.id)
          .toList();
      salesForCustomer.sort(
          (a, b) => b.saleDate.compareTo(a.saleDate)); // Sort by newest first
      setState(() {
        _customerSales = salesForCustomer;
        _isLoading = false;
      });
    }, onError: (error) {
      print('Error loading customer sales: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error loading purchase history: ${error.toString()}')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.name}\'s Purchase History',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFCE4EC),
              Color(0xFFF8BBD0)
            ], // Light pink gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _customerSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey[600]),
                        const SizedBox(height: 20),
                        Text(
                          'No purchase history found for ${widget.customer.name}.',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _customerSales.length,
                    itemBuilder: (context, index) {
                      final sale = _customerSales[index];
                      final saleDateFormatted =
                          DateFormat('MMM d,yyyy HH:mm').format(sale.saleDate);
                      final totalProfit = sale.items
                          .fold(0.0, (sum, item) => sum + item.grossProfit);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.withOpacity(0.1),
                            child: const Icon(Icons.shopping_cart,
                                color: Colors.deepPurple),
                          ),
                          title: Text(
                            'Sale ID: ${sale.id!.substring(0, 8)}...',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: $saleDateFormatted'),
                              Text(
                                  'Total Amount: \$${sale.finalTotalAmount.toStringAsFixed(2)}'),
                              Text(
                                  'Profit: \$${totalProfit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: totalProfit >= 0
                                          ? Colors.green
                                          : Colors.red)),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Items Purchased:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  ...sale.items.map((item) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0),
                                        child: Text(
                                          '• ${item.productName} (SKU: ${item.productSku}) x ${item.quantity} - \$${item.basePrice.toStringAsFixed(2)} each',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      )),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Overall Discount: \$${sale.overallDiscountAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
