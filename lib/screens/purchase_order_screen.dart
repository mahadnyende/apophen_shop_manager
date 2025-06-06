// lib/screens/purchase_order_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_item_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/supplier_model.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart';
import 'package:apophen_shop_manager/services/purchase_order_service.dart';
import 'package:apophen_shop_manager/services/supplier_service.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final PurchaseOrderService _poService = PurchaseOrderService();
  final SupplierService _supplierService = SupplierService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedExpectedDeliveryDate;
  Supplier? _selectedSupplier;
  List<PurchaseOrderItem> _currentPoItems = [];
  double _currentPoTotalCost = 0.0;

  List<Product> _availableProducts = [];
  final TextEditingController _productSearchController =
      TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _inventoryService.getProducts().listen((products) {
      setState(() {
        _availableProducts = products;
        _filterProducts(_productSearchController.text);
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _productSearchController.dispose();
    _poService.dispose();
    _supplierService.dispose(); // Dispose service streams if they have them
    _inventoryService.dispose(); // Dispose service streams if they have them
    super.dispose();
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = [];
    } else {
      _filteredProducts = _availableProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.productSku.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void _addPoItem(Product product) {
    // Check if item already exists in current PO items
    final existingItemIndex =
        _currentPoItems.indexWhere((item) => item.productId == product.id);

    if (existingItemIndex != -1) {
      setState(() {
        _currentPoItems[existingItemIndex].orderedQuantity++;
      });
    } else {
      setState(() {
        _currentPoItems.add(PurchaseOrderItem(
          productId: product.id!,
          productSku: product.productSku,
          productName: product.name,
          orderedQuantity: 1,
          costPrice: product.costPrice, // Use product's cost price
        ));
      });
    }
    _calculatePoTotal();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${product.name} to PO.')),
    );
  }

  void _updatePoItemQuantity(PurchaseOrderItem item, int change) {
    setState(() {
      final index = _currentPoItems.indexOf(item);
      if (index != -1) {
        _currentPoItems[index].orderedQuantity += change;
        if (_currentPoItems[index].orderedQuantity <= 0) {
          _currentPoItems.removeAt(index);
        }
        _calculatePoTotal();
      }
    });
  }

  void _removePoItem(PurchaseOrderItem item) {
    setState(() {
      _currentPoItems.remove(item);
      _calculatePoTotal();
    });
  }

  void _calculatePoTotal() {
    _currentPoTotalCost =
        _currentPoItems.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  void _clearPoForm() {
    _notesController.clear();
    _selectedExpectedDeliveryDate = null;
    _selectedSupplier = null;
    _currentPoItems.clear();
    _currentPoTotalCost = 0.0;
    _productSearchController.clear();
    _filteredProducts.clear();
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpectedDeliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedExpectedDeliveryDate) {
      setState(() {
        _selectedExpectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _createPurchaseOrder() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier.')),
      );
      return;
    }
    if (_currentPoItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add items to the purchase order.')),
      );
      return;
    }

    try {
      final newPo = PurchaseOrder(
        supplierId: _selectedSupplier!.id!,
        supplierName: _selectedSupplier!.name,
        orderDate: DateTime.now(),
        expectedDeliveryDate: _selectedExpectedDeliveryDate,
        items: _currentPoItems,
        totalCost: _currentPoTotalCost,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        status: PurchaseOrderStatus.pending, // Default status
      );
      await _poService.addPurchaseOrder(newPo);
      _clearPoForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase Order created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to create Purchase Order: ${e.toString()}')),
      );
    }
  }

  Future<void> _receiveStockDialog(PurchaseOrder po) async {
    final List<PurchaseOrderItem> itemsToReceive = po.items
        .where((item) => item.receivedQuantity < item.orderedQuantity)
        .toList();

    if (itemsToReceive.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All items in this PO have already been received.')),
      );
      return;
    }

    Map<String, int> tempReceivedQuantities = {
      for (var item in itemsToReceive) item.productId: 0 // Initialize to 0
    };

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Receive Stock for PO ${po.id!.substring(0, 8)}...'),
          content: StatefulBuilder(
            // Use StatefulBuilder for internal state management
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: itemsToReceive.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                                '${item.productName} (Ordered: ${item.orderedQuantity}, Received: ${item.receivedQuantity})'),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              controller: TextEditingController(
                                  text: tempReceivedQuantities[item.productId]
                                      .toString())
                                ..selection = TextSelection.collapsed(
                                    offset:
                                        tempReceivedQuantities[item.productId]
                                            .toString()
                                            .length),
                              onChanged: (value) {
                                setState(() {
                                  int qty = int.tryParse(value) ?? 0;
                                  if (qty < 0) qty = 0;
                                  // Cap the input quantity to the remaining ordered quantity
                                  final maxReceivable = item.orderedQuantity -
                                      item.receivedQuantity;
                                  if (qty > maxReceivable) {
                                    qty = maxReceivable;
                                    // Optionally show a snackbar here
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Cannot receive more than ${maxReceivable} for ${item.productName}.')),
                                    );
                                  }
                                  tempReceivedQuantities[item.productId] = qty;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Receive'),
              onPressed: () async {
                final List<PurchaseOrderItem> actualReceivedItems = [];
                tempReceivedQuantities.forEach((productId, quantity) {
                  if (quantity > 0) {
                    final originalItem = itemsToReceive
                        .firstWhere((item) => item.productId == productId);
                    actualReceivedItems.add(PurchaseOrderItem(
                      productId: originalItem.productId,
                      productSku: originalItem.productSku,
                      productName: originalItem.productName,
                      orderedQuantity: originalItem
                          .orderedQuantity, // This is ordered, not received
                      costPrice: originalItem.costPrice,
                      receivedQuantity:
                          quantity, // This is the quantity actually received in this transaction
                    ));
                  }
                });

                if (actualReceivedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No quantity entered for receiving.')),
                  );
                  return;
                }

                try {
                  await _poService.receiveStock(po.id!, actualReceivedItems);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Stock received successfully!')),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to receive stock: ${e.toString()}')),
                  );
                }
              },
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
        title: const Text('Purchase Orders',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            tooltip: 'Create New PO',
            onPressed: () {
              _showCreatePoDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFFE1BEE7)
            ], // Light purple gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<PurchaseOrder>>(
          stream: _poService.getPurchaseOrders(),
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
                    Icon(Icons.assignment, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No Purchase Orders found. Create your first one!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final purchaseOrders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: purchaseOrders.length,
              itemBuilder: (context, index) {
                final po = purchaseOrders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getStatusColor(po.status).withOpacity(0.1),
                      child: Icon(_getStatusIcon(po.status),
                          color: _getStatusColor(po.status)),
                    ),
                    title: Text(
                      'PO# ${po.id!.substring(0, 8)}... from ${po.supplierName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Order Date: ${DateFormat('yyyy-MM-dd').format(po.orderDate)}'),
                        if (po.expectedDeliveryDate != null)
                          Text(
                              'Expected: ${DateFormat('yyyy-MM-dd').format(po.expectedDeliveryDate!)}'),
                        Text(
                            'Total Cost: \$${po.totalCost.toStringAsFixed(2)}'),
                        Text('Status: ${po.status.name.toUpperCase()}'),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Items:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            ...po.items
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 4.0),
                                      child: Text(
                                          '${item.productName} (SKU: ${item.productSku}) - Ordered: ${item.orderedQuantity}, Received: ${item.receivedQuantity}, Cost: \$${item.costPrice.toStringAsFixed(2)}'),
                                    ))
                                .toList(),
                            if (po.notes != null && po.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('Notes: ${po.notes}'),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (po.status != PurchaseOrderStatus.received &&
                                    po.status != PurchaseOrderStatus.cancelled)
                                  ElevatedButton.icon(
                                    onPressed: () => _receiveStockDialog(po),
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Receive Stock'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    await _poService
                                        .deletePurchaseOrder(po.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'PO ${po.id!.substring(0, 8)}... deleted!')),
                                    );
                                  },
                                ),
                              ],
                            ),
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
    );
  }

  Color _getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.pending:
        return Colors.grey;
      case PurchaseOrderStatus.ordered:
        return Colors.blue;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.orange;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.pending:
        return Icons.hourglass_empty;
      case PurchaseOrderStatus.ordered:
        return Icons.send;
      case PurchaseOrderStatus.partiallyReceived:
        return Icons.pending_actions;
      case PurchaseOrderStatus.received:
        return Icons.check_circle;
      case PurchaseOrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  void _showCreatePoDialog(BuildContext context) {
    _clearPoForm(); // Clear any previous data

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to manage dialog's internal state
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Create New Purchase Order'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Supplier Selection
                    StreamBuilder<List<Supplier>>(
                      stream: _supplierService.getSuppliers(),
                      builder: (context, supplierSnapshot) {
                        if (supplierSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (supplierSnapshot.hasError) {
                          return Text(
                              'Error loading suppliers: ${supplierSnapshot.error}');
                        }
                        final suppliers = supplierSnapshot.data ?? [];
                        if (suppliers.isEmpty) {
                          return const Text(
                              'No suppliers found. Please add a supplier first.');
                        }
                        return DropdownButtonFormField<Supplier>(
                          decoration: const InputDecoration(
                              labelText: 'Select Supplier *'),
                          value: _selectedSupplier,
                          onChanged: (Supplier? newValue) {
                            setState(() {
                              _selectedSupplier = newValue;
                            });
                          },
                          items: suppliers
                              .map<DropdownMenuItem<Supplier>>((supplier) {
                            return DropdownMenuItem<Supplier>(
                              value: supplier,
                              child: Text(supplier.name),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expected Delivery Date
                    ListTile(
                      title: Text(
                          'Expected Delivery Date: ${_selectedExpectedDeliveryDate == null ? 'Not Set' : DateFormat('yyyy-MM-dd').format(_selectedExpectedDeliveryDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        await _selectDate(context);
                        setState(
                            () {}); // Update the dialog's state after date selection
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Search and Add to PO
                    TextField(
                      controller: _productSearchController,
                      decoration: InputDecoration(
                        labelText: 'Search Product to Add',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _productSearchController.clear();
                            _filterProducts('');
                            setState(() {}); // Update dialog state
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (query) {
                        _filterProducts(query);
                        setState(() {}); // Update dialog state
                      },
                    ),
                    if (_filteredProducts.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                  'SKU: ${product.productSku} | Cost: \$${product.costPrice.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  _addPoItem(product);
                                  setState(
                                      () {}); // Update dialog state after adding item
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Current PO Items List
                    const Text('PO Items:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _currentPoItems.isEmpty
                        ? const Text('No items added to PO yet.')
                        : ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _currentPoItems.length,
                              itemBuilder: (context, index) {
                                final item = _currentPoItems[index];
                                return ListTile(
                                  title: Text(
                                      '${item.productName} (x${item.orderedQuantity})'),
                                  subtitle: Text(
                                      'Cost: \$${item.costPrice.toStringAsFixed(2)} | Total: \$${item.totalCost.toStringAsFixed(2)}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: () {
                                          _updatePoItemQuantity(item, -1);
                                          setState(() {});
                                        },
                                      ),
                                      Text('${item.orderedQuantity}'),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        onPressed: () {
                                          _updatePoItemQuantity(item, 1);
                                          setState(() {});
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          _removePoItem(item);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 16),

                    // PO Total Cost
                    Text(
                      'Total PO Cost: \$${_currentPoTotalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration:
                          const InputDecoration(labelText: 'Notes (Optional)'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearPoForm(); // Clear on cancel
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _createPurchaseOrder();
                    Navigator.of(context)
                        .pop(); // Close dialog after creation attempt
                  },
                  child: const Text('Create PO'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
