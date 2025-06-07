// lib/screens/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_item_model.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart';
import 'package:apophen_shop_manager/services/pos_service.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final InventoryService _inventoryService = InventoryService();
  final POSService _posService = POSService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController =
      TextEditingController(); // Controller for discount input

  List<Product> _availableProducts = [];
  List<Product> _filteredProducts = [];
  List<SaleItem> _cartItems = [];
  double _overallDiscount = 0.0; // State for overall sale discount

  @override
  void initState() {
    super.initState();
    _inventoryService.getProducts().listen((products) {
      setState(() {
        _availableProducts = products;
        _filterProducts(_searchController.text); // Re-filter if products change
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose(); // Dispose discount controller
    _inventoryService.dispose(); // Dispose inventory service's stream
    _posService
        .dispose(); // Dispose POS service (though it currently has no internal streams)
    super.dispose();
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = []; // Don't show all products without a search query
    } else {
      _filteredProducts = _availableProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.productSku.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  void _addItemToCart(Product product) {
    final existingItemIndex =
        _cartItems.indexWhere((item) => item.productId == product.id);

    if (existingItemIndex != -1) {
      // If item already in cart, increase quantity
      final existingItem = _cartItems[existingItemIndex];
      if (product.stockQuantity > existingItem.quantity) {
        setState(() {
          existingItem.quantity++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Maximum stock for ${product.name} reached in cart!')),
        );
      }
    } else {
      // Add new item to cart
      if (product.stockQuantity > 0) {
        setState(() {
          _cartItems.add(SaleItem(
            productId: product.id!,
            productSku: product.productSku,
            productName: product.name,
            basePrice: product.price, // Corrected: use basePrice
            costPrice:
                product.price, // Use product.price as costPrice temporarily
            quantity: 1,
            itemDiscount: 0.0, // No item-specific discount by default
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Added ${product.name} (SKU: ${product.productSku}) to cart.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} is out of stock!')),
        );
      }
    }
  }

  void _increaseCartItemQuantity(SaleItem item) {
    final product =
        _availableProducts.firstWhere((p) => p.id == item.productId);
    if (product.stockQuantity > item.quantity) {
      setState(() {
        item.quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Cannot add more ${item.productName}. Max stock reached.')),
      );
    }
  }

  void _decreaseCartItemQuantity(SaleItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cartItems
            .removeWhere((cartItem) => cartItem.productId == item.productId);
      }
    });
  }

  void _removeItemFromCart(SaleItem item) {
    setState(() {
      _cartItems
          .removeWhere((cartItem) => cartItem.productId == item.productId);
    });
  }

  double get _subtotalBeforeOverallDiscount =>
      _cartItems.fold(0.0, (sum, item) => sum + item.finalSubtotal);

  double get _cartTotal => _subtotalBeforeOverallDiscount - _overallDiscount;

  void _applyOverallDiscount() {
    double? discount = double.tryParse(_discountController.text);
    if (discount == null || discount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid discount amount.')),
      );
      return;
    }
    if (discount > _subtotalBeforeOverallDiscount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Discount cannot be greater than the subtotal.')),
      );
      discount = _subtotalBeforeOverallDiscount; // Cap discount at subtotal
    }
    setState(() {
      _overallDiscount = discount!;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Overall discount applied: \$${_overallDiscount.toStringAsFixed(2)}')),
    );
    FocusScope.of(context).unfocus(); // Dismiss keyboard
  }

  void _clearOverallDiscount() {
    setState(() {
      _overallDiscount = 0.0;
      _discountController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Overall discount cleared.')),
    );
  }

  Future<void> _processSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add products to sell!')),
      );
      return;
    }

    try {
      // Corrected: Pass overallDiscountAmount
      await _posService.recordSale(_cartItems, _overallDiscount, null,
          null); // Customer and Employee ID are null for now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sale completed successfully! Stock updated.')),
      );
      setState(() {
        _cartItems.clear(); // Clear cart after successful sale
        _searchController.clear();
        _discountController.clear(); // Clear discount after sale
        _overallDiscount = 0.0; // Reset overall discount
        _filterProducts(''); // Clear search results
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process sale: ${e.toString()}')),
      );
    }
  }

  Future<void> _holdCart() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Nothing to hold!')),
      );
      return;
    }
    try {
      await _posService.holdCart(_cartItems);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart held successfully!')),
      );
      setState(() {
        _cartItems.clear(); // Clear current cart
        _searchController.clear();
        _discountController.clear();
        _overallDiscount = 0.0;
        _filterProducts('');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to hold cart: ${e.toString()}')),
      );
    }
  }

  Future<void> _retrieveHeldCart() async {
    try {
      final heldItems = await _posService.retrieveHeldCart();
      if (heldItems != null && heldItems.isNotEmpty) {
        if (_cartItems.isNotEmpty) {
          // If current cart is not empty, offer to merge or replace
          final bool? replace = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Cart Not Empty'),
                content: const Text(
                    'You have items in the current cart. Do you want to replace it with the held cart?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Replace'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          );
          if (replace == false || replace == null) {
            return; // User cancelled or chose not to replace
          }
        }

        setState(() {
          _cartItems = heldItems; // Replace current cart with held cart
          _overallDiscount = 0.0; // Reset discount when retrieving a new cart
          _discountController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Held cart retrieved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No held cart available.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to retrieve held cart: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Point of Sale', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'hold') {
                _holdCart();
              } else if (result == 'retrieve') {
                _retrieveHeldCart();
              } else if (result == 'return') {
                // Future: Implement return functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Return functionality coming soon!')),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'hold',
                child: Text('Hold Cart'),
              ),
              const PopupMenuItem<String>(
                value: 'retrieve',
                child: Text('Retrieve Last Cart'),
              ),
              const PopupMenuItem<String>(
                value: 'return',
                child: Text('Process Return'),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9)
            ], // Light green gradient for POS
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Product Search and Selection Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Product by Name or SKU',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _filterProducts,
                  ),
                  if (_filteredProducts.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2),
                              title: Text(product.name),
                              subtitle: Text(
                                  'SKU: ${product.productSku} | Price: \$${product.price.toStringAsFixed(2)} | Stock: ${product.stockQuantity}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_shopping_cart,
                                    color: Colors.deepPurple),
                                onPressed: () => _addItemToCart(product),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 2, color: Colors.deepPurple),

            // Cart Display Area
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 20),
                          Text(
                            'Your cart is empty. Add products to get started!',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                          'Base Price: \$${item.basePrice.toStringAsFixed(2)}'),
                                      if (item.itemDiscount > 0)
                                        Text(
                                            'Item Discount: -\$${item.itemDiscount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                color: Colors.red)),
                                      Text(
                                          'Subtotal: \$${item.finalSubtotal.toStringAsFixed(2)}'), // Corrected: use finalSubtotal
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () =>
                                          _decreaseCartItemQuantity(item),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      onPressed: () =>
                                          _increaseCartItemQuantity(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removeItemFromCart(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Discount Input
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Overall Discount Amount',
                        prefixIcon: const Icon(Icons.discount),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyOverallDiscount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: const Text('Apply'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _clearOverallDiscount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

            // Cart Summary and Checkout Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      Text(
                        '\$${_subtotalBeforeOverallDiscount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discount:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                      Text(
                        '-\$${_overallDiscount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Total:',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      Text(
                        '\$${_cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _processSale,
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        'Process Sale',
                        style: TextStyle(fontSize: 20),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF4CAF50), // Green for checkout
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 5,
                      ),
                    ),
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
