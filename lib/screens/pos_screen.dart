import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_item_model.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart';
import 'package:apophen_shop_manager/services/pos_service.dart';

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
  final TextEditingController _discountController = TextEditingController(); // Controller for discount input
  double _overallDiscount = 0.0;
  List<Product> _availableProducts = [];
  List<Product> _filteredProducts = [];
  List<SaleItem> _cartItems = [];
  bool _isProcessingSale = false;

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
            basePrice: product.price,
            quantity: 1,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          // NEW: Show SKU in snackbar
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

  double get _cartTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.finalSubtotal);

  Future<void> _processSale() async {
    if (_isProcessingSale) {
      print('[DEBUG] Sale is already being processed. Ignoring duplicate call.');
      return;
    }
    _isProcessingSale = true;
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add products to sell!')),
      );
      _isProcessingSale = false;
      return;
    }

    try {
      await _posService.recordSale(_cartItems, _overallDiscount, null, null); // Customer and Employee ID are null for now
      print('[DEBUG] Sale processed, clearing cart and refreshing product list.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sale completed successfully! Stock updated.')),
      );
      setState(() {
        _cartItems.clear(); // Clear cart after successful sale
        _searchController.clear();
        _filterProducts(''); // Clear search results
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process sale: ${e.toString()}')),
      );
    } finally {
      _isProcessingSale = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Point of Sale', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
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
                                  'SKU: ${product.productSku} | Price: \${product.price.toStringAsFixed(2)} | Stock: ${product.stockQuantity}'),
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
                                          'Price: \${item.basePrice.toStringAsFixed(2)}'),
                                      Text(
                                          'Subtotal: \${item.finalSubtotal.toStringAsFixed(2)}'),
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
                        'Total:',
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
