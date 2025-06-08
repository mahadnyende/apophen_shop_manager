// lib/screens/return_management_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_model.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_item_model.dart';
import 'package:apophen_shop_manager/data/models/pos/return_model.dart';
import 'package:apophen_shop_manager/data/models/pos/return_item_model.dart';
import 'package:apophen_shop_manager/services/pos_service.dart';
import 'package:apophen_shop_manager/services/return_service.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart'; // To get product cost price for return item
import 'package:apophen_shop_manager/data/local/database/app_database.dart'; // For direct DB access if needed by SaleService
import 'package:sembast/sembast.dart'; // For StoreRef
import 'package:intl/intl.dart';

class ReturnManagementScreen extends StatefulWidget {
  const ReturnManagementScreen({super.key});

  @override
  State<ReturnManagementScreen> createState() => _ReturnManagementScreenState();
}

class _ReturnManagementScreenState extends State<ReturnManagementScreen> {
  final POSService _posService = POSService();
  final ReturnService _returnService = ReturnService();
  final InventoryService _inventoryService =
      InventoryService(); // For product details

  final TextEditingController _saleIdController = TextEditingController();
  Sale? _selectedSale;
  final List<ReturnItem> _itemsToReturn = [];
  Map<String, TextEditingController> _returnQtyControllers =
      {}; // ItemId -> Controller
  Map<String, String> _returnReasons = {}; // ItemId -> Reason

  // Common return reasons for a dropdown
  final List<String> _commonReturnReasons = [
    'Customer changed mind',
    'Damaged item',
    'Wrong size/color',
    'Defective product',
    'Received wrong item',
    'Other (specify)',
  ];

  @override
  void dispose() {
    _saleIdController.dispose();
    _returnQtyControllers.forEach((key, controller) => controller.dispose());
    _posService.dispose(); // No stream in POSService, but good practice
    _returnService.dispose();
    _inventoryService.dispose();
    super.dispose();
  }

  void _searchSale() async {
    final saleId = _saleIdController.text.trim();
    if (saleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Sale ID to search.')),
      );
      return;
    }

    try {
      final db = await AppDatabase.instance;
      final _salesStore =
          stringMapStoreFactory.store('sales'); // Re-declare store
      final snapshot = await _salesStore.record(saleId).getSnapshot(db);

      if (snapshot != null) {
        final sale = Sale.fromMap(snapshot.value, id: snapshot.key);
        setState(() {
          _selectedSale = sale;
          _itemsToReturn.clear();
          _returnQtyControllers.forEach((key, controller) =>
              controller.dispose()); // Dispose old controllers
          _returnQtyControllers.clear();
          _returnReasons.clear();
          // Initialize controllers for each item in the selected sale
          for (var item in sale.items) {
            _returnQtyControllers[item.productId] =
                TextEditingController(text: item.quantity.toString());
            _returnReasons[item.productId] =
                _commonReturnReasons.first; // Default reason
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale found!')),
        );
      } else {
        setState(() {
          _selectedSale = null;
          _itemsToReturn.clear();
          _returnQtyControllers
              .forEach((key, controller) => controller.dispose());
          _returnQtyControllers.clear();
          _returnReasons.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale not found. Please check the ID.')),
        );
      }
    } catch (e) {
      setState(() {
        _selectedSale = null;
        _itemsToReturn.clear();
        _returnQtyControllers
            .forEach((key, controller) => controller.dispose());
        _returnQtyControllers.clear();
        _returnReasons.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for sale: ${e.toString()}')),
      );
    }
  }

  void _toggleItemForReturn(SaleItem saleItem) {
    setState(() {
      final existingIndex = _itemsToReturn
          .indexWhere((item) => item.productId == saleItem.productId);
      if (existingIndex != -1) {
        _itemsToReturn.removeAt(existingIndex);
        _returnQtyControllers[saleItem.productId]
            ?.dispose(); // Dispose controller
        _returnQtyControllers.remove(saleItem.productId);
        _returnReasons.remove(saleItem.productId);
      } else {
        // When adding, create a new ReturnItem with default quantity and reason
        _itemsToReturn.add(ReturnItem(
          productId: saleItem.productId,
          productSku: saleItem.productSku,
          productName: saleItem.productName,
          unitPriceAtSale: saleItem.basePrice,
          unitCostAtSale:
              saleItem.costPrice, // Use original cost price from sale item
          quantity: saleItem.quantity, // Default to full quantity sold
          returnReason: _commonReturnReasons.first,
        ));
        _returnQtyControllers[saleItem.productId] =
            TextEditingController(text: saleItem.quantity.toString());
        _returnReasons[saleItem.productId] = _commonReturnReasons.first;
      }
    });
  }

  double get _totalRefundAmount {
    double total = 0.0;
    for (var item in _itemsToReturn) {
      // Ensure the quantity from the controller is used if available
      final qtyController = _returnQtyControllers[item.productId];
      final currentQty =
          int.tryParse(qtyController?.text ?? '0') ?? item.quantity;
      total += item.unitPriceAtSale * currentQty;
    }
    return total;
  }

  void _processReturn() async {
    if (_selectedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sale selected for return.')),
      );
      return;
    }
    if (_itemsToReturn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected for return.')),
      );
      return;
    }

    List<ReturnItem> actualReturnItems = [];
    bool hasError = false;

    for (var item in _itemsToReturn) {
      final qtyController = _returnQtyControllers[item.productId]!;
      final reason = _returnReasons[item.productId]!;
      final quantityToReturn = int.tryParse(qtyController.text) ?? 0;

      if (quantityToReturn <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Quantity to return for ${item.productName} must be positive.')),
        );
        hasError = true;
        break;
      }

      // Find the original quantity sold from _selectedSale.items
      final originalSaleItem = _selectedSale!.items.firstWhere(
        (saleItem) => saleItem.productId == item.productId,
        orElse: () => throw Exception(
            'Original sale item not found for ${item.productName}'),
      );

      if (quantityToReturn > originalSaleItem.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Cannot return more than sold quantity for ${item.productName}.')),
        );
        hasError = true;
        break;
      }

      actualReturnItems.add(ReturnItem(
        productId: item.productId,
        productSku: item.productSku,
        productName: item.productName,
        unitPriceAtSale: item.unitPriceAtSale,
        unitCostAtSale: item.unitCostAtSale,
        quantity: quantityToReturn,
        returnReason: reason,
      ));
    }

    if (hasError) return;

    try {
      final returnObj = Return(
        originalSaleId: _selectedSale!.id!,
        returnDate: DateTime.now(),
        items: actualReturnItems,
        totalRefundAmount: actualReturnItems.fold(
            0.0, (sum, element) => sum + element.potentialRefundAmount),
        customerId:
            _selectedSale!.customerId, // Associate with original customer
        // processedByEmployeeId: ... (if you have current user's employee ID)
        notes: 'Processed through POS return screen.',
      );

      await _returnService.processReturn(returnObj);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Return processed successfully! Inventory adjusted.')),
      );
      setState(() {
        _selectedSale = null;
        _itemsToReturn.clear();
        _saleIdController.clear();
        _returnQtyControllers.forEach((key, controller) =>
            controller.dispose()); // Dispose all controllers
        _returnQtyControllers.clear();
        _returnReasons.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process return: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Returns',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFBE9E7),
              Color(0xFFFFCCBC)
            ], // Light orange/red gradient for returns
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _saleIdController,
                          decoration: InputDecoration(
                            labelText: 'Enter Original Sale ID',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: const Icon(Icons.receipt),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _searchSale,
                        icon: const Icon(Icons.search),
                        label: const Text('Search Sale'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedSale != null)
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Original Sale Details:',
                              style: Theme.of(context).textTheme.headlineSmall),
                          Text('Sale ID: ${_selectedSale!.id!}'),
                          Text(
                              'Sale Date: ${DateFormat('MMM d,yyyy HH:mm').format(_selectedSale!.saleDate)}'),
                          Text(
                              'Total Paid: \$${_selectedSale!.finalTotalAmount.toStringAsFixed(2)}'),
                          const Divider(),
                          Text('Items from Sale:',
                              style: Theme.of(context).textTheme.titleLarge),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _selectedSale!.items.length,
                              itemBuilder: (context, index) {
                                final originalItem =
                                    _selectedSale!.items[index];
                                final isSelected = _itemsToReturn.any((item) =>
                                    item.productId == originalItem.productId);
                                final returnItemInList =
                                    _itemsToReturn.firstWhereOrNull((item) =>
                                        item.productId ==
                                        originalItem.productId);

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  elevation: 2,
                                  color: isSelected
                                      ? Colors.orange.withOpacity(0.1)
                                      : null,
                                  child: ListTile(
                                    onTap: () =>
                                        _toggleItemForReturn(originalItem),
                                    leading: Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        _toggleItemForReturn(originalItem);
                                      },
                                    ),
                                    title: Text(originalItem.productName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Sold: ${originalItem.quantity} x \$${originalItem.basePrice.toStringAsFixed(2)}'),
                                        Text('SKU: ${originalItem.productSku}'),
                                        if (isSelected) ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      _returnQtyControllers[
                                                          originalItem
                                                              .productId],
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText:
                                                              'Qty to Return'),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      // This setState will trigger recalculation of total refund
                                                      // and also visually update the text field.
                                                      // No need to update _itemsToReturn directly here,
                                                      // as it will be finalized in _processReturn.
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _returnReasons[
                                                      originalItem.productId],
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: 'Reason'),
                                                  items: _commonReturnReasons
                                                      .map((String reason) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: reason,
                                                      child: Text(reason),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {
                                                    setState(() {
                                                      // setState to update dropdown in UI
                                                      _returnReasons[
                                                              originalItem
                                                                  .productId] =
                                                          newValue!;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total Refund: \$${_totalRefundAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _processReturn,
                              icon: const Icon(Icons.assignment_return),
                              label: const Text('Process Return',
                                  style: TextStyle(fontSize: 18)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'Search for a sale to process a return.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to help with finding firstWhereOrNull, which is not built-in for all Lists
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
