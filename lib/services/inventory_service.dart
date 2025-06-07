// lib/services/inventory_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart';
import 'dart:async'; // For StreamController

class InventoryService {
  final _productsStore =
      stringMapStoreFactory.store('products'); // Define a store for products
  final _productsStreamController = StreamController<List<Product>>.broadcast();

  InventoryService() {
    _initProductStream(); // Initialize the stream to listen to changes
  }

  // Initialize the stream by listening to the Sembast store
  Future<void> _initProductStream() async {
    final db = await AppDatabase.instance;
    _productsStore.query().onSnapshots(db).listen((snapshots) {
      final products = snapshots.map((snapshot) {
        return Product.fromMap(snapshot.value,
            id: snapshot.key); // Pass key as ID
      }).toList();
      _productsStreamController.sink.add(products);
    }, onError: (error) {
      print('Error listening to product stream: $error');
      _productsStreamController.addError(error);
    });
  }

  // Add a new product to the database
  Future<void> addProduct(Product product) async {
    final db = await AppDatabase.instance;
    // Check if productSku already exists to ensure uniqueness manually
    final existingProduct = await _productsStore.findFirst(db,
        finder:
            Finder(filter: Filter.equals('productSku', product.productSku)));

    if (existingProduct != null) {
      throw Exception('Product with SKU ${product.productSku} already exists.');
    }

    final key = await _productsStore.add(db, product.toMap());
    print('Product added with key: $key');
  }

  // Get all products from the database (stream)
  Stream<List<Product>> getProducts() {
    return _productsStreamController.stream;
  }

  // Get a single product by its SKU
  Future<Product?> getProductBySku(String sku) async {
    final db = await AppDatabase.instance;
    final recordSnapshot = await _productsStore.findFirst(db,
        finder: Finder(filter: Filter.equals('productSku', sku)));
    if (recordSnapshot != null) {
      return Product.fromMap(recordSnapshot.value, id: recordSnapshot.key);
    }
    return null;
  }

  // Get a single product by its ID
  Future<Product?> getProductById(String id) async {
    // NEW: Method to get product by ID
    final db = await AppDatabase.instance;
    final recordSnapshot = await _productsStore.record(id).getSnapshot(db);
    if (recordSnapshot != null) {
      return Product.fromMap(recordSnapshot.value, id: recordSnapshot.key);
    }
    return null;
  }

  // Update an existing product
  Future<void> updateProduct(Product product) async {
    if (product.id == null) {
      throw Exception('Product ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _productsStore.record(product.id!).put(db, product.toMap());
    print('Product updated: ${product.name}');
  }

  // Delete a product by its ID
  Future<void> deleteProduct(String id) async {
    final db = await AppDatabase.instance;
    final count = await _productsStore.record(id).delete(db);
    if (count != null) {
      print('Product with ID $id deleted.');
    } else {
      print('Product with ID $id not found for deletion.');
    }
  }

  // Adjust product stock quantity (for sales/returns)
  // This method now accepts a 'Transaction' object to participate in an existing transaction.
  Future<void> adjustStock(
      String productId, int quantityChange, Transaction txn) async {
    final productRecord = _productsStore.record(productId);
    final snapshot =
        await productRecord.getSnapshot(txn); // Use the provided transaction

    if (snapshot == null) {
      throw Exception('Product not found for stock adjustment: $productId');
    }

    final product = Product.fromMap(snapshot.value, id: snapshot.key);
    if (product.stockQuantity + quantityChange < 0) {
      throw Exception(
          'Not enough stock for ${product.name}. Available: ${product.stockQuantity}');
    }
    product.updateStock(quantityChange); // This also updates lastModified
    await productRecord.put(
        txn, product.toMap()); // Use the provided transaction
    print(
        'Stock for ${product.name} adjusted by $quantityChange to ${product.stockQuantity}');
  }

  // Helper to fetch and emit products to the stream (newly added for explicit refresh)
  Future<void> _fetchAndEmitProducts() async {
    final db = await AppDatabase.instance;
    final snapshots = await _productsStore.find(db);
    final products = snapshots.map((snapshot) {
      return Product.fromMap(snapshot.value, id: snapshot.key);
    }).toList();
    _productsStreamController.sink.add(products);
  }

  // Don't forget to close the stream controller when the service is no longer needed
  void dispose() {
    _productsStreamController.close();
  }
}
