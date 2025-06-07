// lib/services/pos_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_model.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_item_model.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart'; // Ensure Product is imported
import 'package:apophen_shop_manager/services/inventory_service.dart';
import 'dart:async';

class POSService {
  final _salesStore = stringMapStoreFactory.store('sales'); // Define a store for sales
  final _heldCartsStore = stringMapStoreFactory.store('heldCarts'); // Store for held carts
  final InventoryService _inventoryService = InventoryService();

  // Record a new sale transaction
  Future<Sale> recordSale(List<SaleItem> items, double overallDiscountAmount, String? customerId, String? employeeId) async {
    final db = await AppDatabase.instance;
    
    // Calculate subtotal before any overall discount
    double subtotalBeforeDiscount = items.fold(0.0, (sum, item) => sum + item.finalSubtotal);
    
    // Calculate final total amount after overall discount
    double finalTotalAmount = subtotalBeforeDiscount - overallDiscountAmount;
    if (finalTotalAmount < 0) finalTotalAmount = 0; // Prevent negative total

    final sale = Sale(
      saleDate: DateTime.now(),
      subtotalBeforeDiscount: subtotalBeforeDiscount, // Use new field
      overallDiscountAmount: overallDiscountAmount,   // Use new field
      finalTotalAmount: finalTotalAmount,             // Use new field
      items: items,
      customerId: customerId,
      employeeId: employeeId,
      transactionType: 'sale', // Explicitly mark as a sale
    );

    // Use a single transaction to ensure atomicity: record sale AND stock updates
    await db.transaction((txn) async {
      // 1. Record the sale
      final saleKey = await _salesStore.add(txn, sale.toMap());
      sale.id = saleKey; // Assign the generated ID to the sale object

      // 2. Adjust inventory for each item in the sale using the SAME transaction
      for (var item in items) {
        await _inventoryService.adjustStock(item.productId, -item.quantity, txn); // Decrease stock
      }
    });
    // After the transaction completes successfully, explicitly refresh the inventory stream
    // to ensure the UI updates.
    _inventoryService.getProducts(); // This call will trigger a refresh of the stream in InventoryService
    
    print('Sale recorded successfully: Total \$${sale.finalTotalAmount.toStringAsFixed(2)}');
    return sale;
  }

  // Hold a cart
  Future<void> holdCart(List<SaleItem> items) async {
    final db = await AppDatabase.instance;
    // For simplicity, we'll replace any existing held cart.
    // In a full implementation, you'd manage multiple held carts by key/name.
    final heldCartMap = {
      'timestamp': DateTime.now().toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
    };
    await _heldCartsStore.record('last_held_cart').put(db, heldCartMap);
    print('Cart held successfully.');
  }

  // Retrieve the last held cart
  Future<List<SaleItem>?> retrieveHeldCart() async {
    final db = await AppDatabase.instance;
    final snapshot = await _heldCartsStore.record('last_held_cart').getSnapshot(db);
    if (snapshot != null) {
      final heldCartMap = snapshot.value;
      final itemsMapList = (heldCartMap['items'] as List<dynamic>); // Cast to List<dynamic>
      final items = itemsMapList.map((itemMap) => SaleItem.fromMap(itemMap as Map<String, dynamic>)).toList(); // Cast itemMap to Map<String, dynamic>
      await _heldCartsStore.record('last_held_cart').delete(db); // Clear held cart after retrieval
      print('Cart retrieved successfully.');
      return items;
    }
    print('No held cart found.');
    return null;
  }

  // Get all sales (can be enhanced with filters, pagination later)
  Stream<List<Sale>> getSales() {
    return Stream.fromFuture(AppDatabase.instance).asyncExpand((database) {
      return _salesStore.query().onSnapshots(database).map((snapshots) {
        return snapshots.map((snapshot) => Sale.fromMap(snapshot.value, id: snapshot.key)).toList();
      });
    });
  }

  // Dispose method (if needed, e.g., for stream controllers specific to this service)
  void dispose() {
    // No internal stream controllers managed directly by POSService currently
    // _inventoryService.dispose() is handled by its owner (e.g., InventoryScreen)
  }
}
