// lib/screens/purchase_order_management_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_item_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/supplier_model.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart';
import 'package:apophen_shop_manager/services/purchase_order_service.dart';
import 'package:apophen_shop_manager/services/supplier_service.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart';
import 'package:intl/intl.dart';

class PurchaseOrderManagementScreen extends StatefulWidget {
  const PurchaseOrderManagementScreen({super.key});

  @override
  State<PurchaseOrderManagementScreen> createState() =>
      _PurchaseOrderManagementScreenState();
}

class _PurchaseOrderManagementScreenState
    extends State<PurchaseOrderManagementScreen> {
  final PurchaseOrderService _poService = PurchaseOrderService();
  final SupplierService _supplierService = SupplierService();
  final InventoryService _inventoryService = InventoryService();

  List<Supplier> _availableSuppliers = [];
  List<Product> _availableProducts = [];

  // For 'Add PO' dialog
  Supplier? _selectedSupplier;
  final List<PurchaseOrderItem> _currentPoItems = [];
  final TextEditingController _poExpectedDeliveryDateController =
      TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
  List<Product> _filteredProductsForPo = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _poExpectedDeliveryDateController.dispose();
    _productSearchController.dispose();
    _poService.dispose();
    _supplierService.dispose();
    _inventoryService.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    _supplierService.getSuppliers().listen((suppliers) {
      setState(() {
        _availableSuppliers = suppliers;
      });
    });
    _inventoryService.getProducts().listen((products) {
      setState(() {
        _availableProducts = products;
        // FIX: Ensure filtered products are also initialized when available products are loaded
        _filterProductsForPo(_productSearchController.text);
      });
    });
  }

  void _clearPoControllers() {
    setState(() {
      _selectedSupplier = null;
      _currentPoItems.clear();
      _poExpectedDeliveryDateController.clear();
      _productSearchController.clear();
      _filteredProductsForPo =
          List.from(_availableProducts); // Reset to all products
    });
  }

  void _filterProductsForPo(String query) {
    if (query.isEmpty) {
      _filteredProductsForPo =
          List.from(_availableProducts); // Show all if query is empty
    } else {
      _filteredProductsForPo = _availableProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.productSku.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  void _addPoItemToCart(Product product) {
    final existingItemIndex =
        _currentPoItems.indexWhere((item) => item.productId == product.id);

    if (existingItemIndex != -1) {
      _currentPoItems[existingItemIndex].orderedQuantity++;
    } else {
      _currentPoItems.add(PurchaseOrderItem(
        productId: product.id!,
        productSku: product.productSku,
        productName: product.name,
        orderedUnitCost: product.costPrice,
        orderedQuantity: 1,
      ));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${product.name} to PO cart.')),
    );
  }

  void _increasePoItemQuantity(PurchaseOrderItem item) {
    item.orderedQuantity++;
  }

  void _decreasePoItemQuantity(PurchaseOrderItem item) {
    if (item.orderedQuantity > 1) {
      item.orderedQuantity--;
    } else {
      _currentPoItems
          .removeWhere((poItem) => poItem.productId == item.productId);
    }
  }

  void _removePoItemFromCart(PurchaseOrderItem item) {
    _currentPoItems.removeWhere((poItem) => poItem.productId == item.productId);
  }

  double get _currentPoTotalAmount =>
      _currentPoItems.fold(0.0, (sum, item) => sum + item.totalItemCost);

  Future<void> _createPurchaseOrder() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier!')),
      );
      return;
    }
    if (_currentPoItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add items to the purchase order!')),
      );
      return;
    }

    DateTime? expectedDelivery;
    if (_poExpectedDeliveryDateController.text.isNotEmpty) {
      expectedDelivery =
          DateTime.tryParse(_poExpectedDeliveryDateController.text);
    }

    try {
      final po = PurchaseOrder(
        supplierId: _selectedSupplier!.id!,
        supplierName: _selectedSupplier!.name,
        orderDate: DateTime.now(),
        expectedDeliveryDate: expectedDelivery,
        items: List.from(_currentPoItems),
        totalOrderAmount: _currentPoTotalAmount,
        status: PurchaseOrderStatus.ordered,
      );
      await _poService.addPurchaseOrder(po);
      _clearPoControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase Order created successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to create Purchase Order: ${e.toString()}')),
      );
    }
  }

  void _showAddPurchaseOrderDialog(BuildContext context) {
    _clearPoControllers();
    _filterProductsForPo(''); // Ensure all products are shown initially

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('Create New Purchase Order'),
              // FIX: Constrain the height of the AlertDialog's content
              content: SizedBox(
                // Use SizedBox to give the content a defined size
                width: MediaQuery.of(context).size.width *
                    0.8, // Take 80% of screen width
                height: MediaQuery.of(context).size.height *
                    0.7, // Take 70% of screen height
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // Use min size, but still flexible due to SingleChildScrollView
                    children: [
                      DropdownButtonFormField<Supplier>(
                        decoration: const InputDecoration(
                            labelText: 'Select Supplier*'),
                        value: _selectedSupplier,
                        onChanged: (Supplier? newValue) {
                          dialogSetState(() {
                            _selectedSupplier = newValue;
                          });
                        },
                        items: _availableSuppliers.map((supplier) {
                          return DropdownMenuItem<Supplier>(
                            value: supplier,
                            child: Text(supplier.name),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            dialogSetState(() {
                              _poExpectedDeliveryDateController.text =
                                  DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _poExpectedDeliveryDateController,
                            decoration: const InputDecoration(
                              labelText: 'Expected Delivery Date',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Add Products to PO:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextField(
                        controller: _productSearchController,
                        decoration: InputDecoration(
                          labelText: 'Search Product (SKU or Name)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _productSearchController.clear();
                              dialogSetState(() {
                                _filterProductsForPo('');
                              });
                            },
                          ),
                        ),
                        onChanged: (query) {
                          dialogSetState(() {
                            _filterProductsForPo(query);
                          });
                        },
                      ),
                      if (_filteredProductsForPo.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                              'No products found matching your search or in inventory.',
                              style: TextStyle(color: Colors.grey)),
                        )
                      else
                        // FIX: Give ConstrainedBox a defined height or use Expanded within a Column with a defined height
                        SizedBox(
                          // Replace ConstrainedBox with SizedBox for more explicit sizing
                          height:
                              150, // Fixed height for product search results list
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredProductsForPo.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProductsForPo[index];
                              return ListTile(
                                title: Text(
                                    '${product.name} (SKU: ${product.productSku})'),
                                subtitle: Text(
                                    'Cost: \$${product.costPrice.toStringAsFixed(2)} | Stock: ${product.stockQuantity}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_shopping_cart,
                                      color: Colors.green),
                                  onPressed: () {
                                    dialogSetState(() {
                                      _addPoItemToCart(product);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text('PO Items:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _currentPoItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No items added to this PO yet.'),
                            )
                          : SizedBox(
                              // Replace ConstrainedBox with SizedBox for more explicit sizing
                              height: 150, // Fixed height for PO items list
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _currentPoItems.length,
                                itemBuilder: (context, index) {
                                  final item = _currentPoItems[index];
                                  return ListTile(
                                    title: Text(item.productName),
                                    subtitle: Text(
                                        'Unit Cost: \$${item.orderedUnitCost.toStringAsFixed(2)} | Total: \$${item.totalItemCost.toStringAsFixed(2)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          onPressed: () {
                                            dialogSetState(() {
                                              _decreasePoItemQuantity(item);
                                            });
                                          },
                                        ),
                                        Text('${item.orderedQuantity}'),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () {
                                            dialogSetState(() {
                                              _increasePoItemQuantity(item);
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            dialogSetState(() {
                                              _removePoItemFromCart(item);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                      const SizedBox(height: 16),
                      Text(
                        'Total PO Amount: \$${_currentPoTotalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearPoControllers();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _createPurchaseOrder,
                  child: const Text('Create PO'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReceiveItemsDialog(
      BuildContext context, PurchaseOrder po) async {
    final Map<String, TextEditingController> _receiveQtyControllers = {};
    for (var item in po.items) {
      _receiveQtyControllers[item.productId] = TextEditingController(
        text: (item.orderedQuantity - item.receivedQuantity > 0) ? '1' : '0',
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Receive Items for PO: ${po.id!.substring(0, 8)}...'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Supplier: ${po.supplierName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...po.items.map((item) {
                  final remaining =
                      item.orderedQuantity - item.receivedQuantity;
                  final TextEditingController controller =
                      _receiveQtyControllers[item.productId]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                            'Ordered: ${item.orderedQuantity}, Received: ${item.receivedQuantity}, Remaining: $remaining'),
                        TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity to Receive',
                            border: OutlineInputBorder(),
                          ),
                          enabled: remaining > 0,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _receiveQtyControllers
                    .forEach((key, controller) => controller.dispose());
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                List<PurchaseOrderItem> actualReceivedItems = [];
                bool hasError = false;

                for (var item in po.items) {
                  final TextEditingController controller =
                      _receiveQtyControllers[item.productId]!;
                  final qtyToReceive = int.tryParse(controller.text) ?? 0;

                  if (qtyToReceive < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Error: Quantity for ${item.productName} cannot be negative.')),
                    );
                    hasError = true;
                    break;
                  }

                  final totalReceivedSoFar =
                      item.receivedQuantity + qtyToReceive;

                  if (totalReceivedSoFar > item.orderedQuantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Error: Received quantity for ${item.productName} exceeds ordered quantity.')),
                    );
                    hasError = true;
                    break;
                  }

                  if (qtyToReceive > 0) {
                    actualReceivedItems.add(PurchaseOrderItem(
                      productId: item.productId,
                      productSku: item.productSku,
                      productName: item.productName,
                      orderedUnitCost: item.orderedUnitCost,
                      orderedQuantity: item.orderedQuantity,
                      receivedQuantity: qtyToReceive,
                    ));
                  }
                }

                if (hasError) return;

                if (actualReceivedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('No valid quantity entered for receiving.')),
                  );
                  return;
                }

                try {
                  await _poService.receiveItems(po.id!, actualReceivedItems);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Items received and stock updated!')),
                  );
                  _receiveQtyControllers
                      .forEach((key, controller) => controller.dispose());
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error receiving items: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Receive Items'),
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
            tooltip: 'Create New Purchase Order',
            onPressed: () => _showAddPurchaseOrderDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
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
            purchaseOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

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
                      'PO: ${po.id!.substring(0, 8)}... - ${po.supplierName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Order Date: ${DateFormat('MMM d,yyyy').format(po.orderDate.toLocal())}'),
                        if (po.expectedDeliveryDate != null)
                          Text(
                              'Expected Delivery: ${DateFormat('MMM d,yyyy').format(po.expectedDeliveryDate!.toLocal())}'),
                        Text(
                            'Total Amount: \$${po.totalOrderAmount.toStringAsFixed(2)}'),
                        Text('Status: ${_getStatusText(po.status)}',
                            style: TextStyle(
                                color: _getStatusColor(po.status),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Items:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            ...po.items.map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    '• ${item.productName} (SKU: ${item.productSku}) - Ordered: ${item.orderedQuantity}, Received: ${item.receivedQuantity}',
                                    style: TextStyle(
                                        color: item.receivedQuantity ==
                                                item.orderedQuantity
                                            ? Colors.grey
                                            : Colors.black87),
                                  ),
                                )),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (po.status != PurchaseOrderStatus.received &&
                                    po.status != PurchaseOrderStatus.cancelled)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showReceiveItemsDialog(context, po),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Receive Items'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0)),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await _poService
                                        .deletePurchaseOrder(po.id!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Purchase Order ${po.id!.substring(0, 8)}... deleted!')),
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
        return Colors.black;
    }
  }

  IconData _getStatusIcon(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.pending:
        return Icons.hourglass_empty;
      case PurchaseOrderStatus.ordered:
        return Icons.shopping_bag;
      case PurchaseOrderStatus.partiallyReceived:
        return Icons.low_priority;
      case PurchaseOrderStatus.received:
        return Icons.check_circle;
      case PurchaseOrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(PurchaseOrderStatus status) {
    return status
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .capitalizeFirst;
  }
}

// Extension to capitalize first letter (used for status text)
extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
