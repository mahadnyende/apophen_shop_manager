import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController(); // NEW: Controller for costPrice
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose(); // Dispose new controller
    _stockController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _inventoryService.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _skuController.clear();
    _nameController.clear();
    _priceController.clear();
    _costPriceController.clear(); // Clear new controller
    _stockController.clear();
    _descriptionController.clear();
    _categoryController.clear();
  }

  void _addProduct() async {
    if (_skuController.text.isEmpty || _nameController.text.isEmpty ||
        _priceController.text.isEmpty || _costPriceController.text.isEmpty || // NEW: costPrice required
        _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields!')),
      );
      return;
    }

    try {
      final product = Product(
        productSku: _skuController.text,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        costPrice: double.parse(_costPriceController.text), // NEW: Parse costPrice
        stockQuantity: int.parse(_stockController.text),
        category: _categoryController.text.isEmpty ? 'General' : _categoryController.text,
      );
      await _inventoryService.addProduct(product);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: ${e.toString()}')),
      );
    }
  }

  void _updateProduct(Product product) async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty ||
        _costPriceController.text.isEmpty || // NEW: costPrice required for update
        _stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields for update!')),
      );
      return;
    }

    try {
      final updatedProduct = Product(
        id: product.id,
        productSku: product.productSku,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        costPrice: double.parse(_costPriceController.text), // NEW: Parse costPrice for update
        stockQuantity: int.parse(_stockController.text),
        category: _categoryController.text.isEmpty ? 'General' : _categoryController.text,
        createdAt: product.createdAt,
        lastModified: DateTime.now(),
      );
      await _inventoryService.updateProduct(updatedProduct);
      _clearControllers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: ${e.toString()}')),
      );
    }
  }


  void _showAddProductDialog(BuildContext context) {
    _clearControllers();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU (Unique)*'),
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name*'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Selling Price*'), // Updated label
                  keyboardType: TextInputType.number,
                ),
                TextField( // NEW: Cost Price Input Field
                  controller: _costPriceController,
                  decoration: const InputDecoration(labelText: 'Cost Price*'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity*'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category (Optional, default: General)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addProduct();
                Navigator.of(context).pop();
              },
              child: const Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    _skuController.text = product.productSku;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _costPriceController.text = product.costPrice.toString(); // NEW: Populate costPrice
    _stockController.text = product.stockQuantity.toString();
    _categoryController.text = product.category;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Product: ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _skuController,
                  decoration: const InputDecoration(labelText: 'SKU (Cannot be changed)'),
                  readOnly: true,
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name*'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Selling Price*'), // Updated label
                  keyboardType: TextInputType.number,
                ),
                TextField( // NEW: Cost Price Input Field
                  controller: _costPriceController,
                  decoration: const InputDecoration(labelText: 'Cost Price*'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity*'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category (Optional, default: General)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearControllers();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProduct(product);
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
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
        title: const Text('Inventory Management', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add New Product',
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<List<Product>>(
          stream: _inventoryService.getProducts(),
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
                    Icon(Icons.category, size: 80, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      'No products found. Add your first product!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final products = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: const Icon(Icons.shopping_bag, color: Colors.deepPurple),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SKU: ${product.productSku}'),
                        Text('Selling Price: \$${product.price.toStringAsFixed(2)}'), // Updated label
                        Text('Cost Price: \$${product.costPrice.toStringAsFixed(2)}'), // NEW: Display costPrice
                        Text('Stock: ${product.stockQuantity} units'),
                        Text('Category: ${product.category}'),
                        Text('Last Modified: ${product.lastModified.toLocal().toString().split(' ')[0]}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _showEditProductDialog(context, product);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await _inventoryService.deleteProduct(product.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} deleted!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
