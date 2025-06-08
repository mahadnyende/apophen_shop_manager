// lib/services/return_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/pos/return_model.dart';
import 'package:apophen_shop_manager/data/models/pos/return_item_model.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart'; // For updating product stock
import 'dart:async';

class ReturnService {
  final _returnsStore = stringMapStoreFactory.store('returns');
  final _returnsStreamController = StreamController<List<Return>>.broadcast();
  final InventoryService _inventoryService = InventoryService();

  ReturnService() {
    _initReturnsStream();
  }

  Future<void> _initReturnsStream() async {
    final db = await AppDatabase.instance;
    _returnsStore.query().onSnapshots(db).listen((snapshots) {
      final returns = snapshots.map((snapshot) {
        return Return.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _returnsStreamController.sink.add(returns);
    }, onError: (error) {
      print('Error listening to returns stream: $error');
      _returnsStreamController.addError(error);
    });
  }

  // Process a new return transaction
  Future<void> processReturn(Return returnObj) async {
    final db = await AppDatabase.instance;

    await db.transaction((txn) async {
      // 1. Record the return
      final returnKey = await _returnsStore.add(txn, returnObj.toMap());
      returnObj.id = returnKey; // Assign the generated ID

      // 2. Adjust inventory for each item in the return (increase stock)
      for (var item in returnObj.items) {
        await _inventoryService.adjustStock(
            item.productId, item.quantity, txn); // Increase stock
      }

      // 3. Update return status to processed (optional, could be done after successful inventory update)
      returnObj.status = ReturnStatus.processed;
      returnObj.lastModified = DateTime.now();
      await _returnsStore.record(returnObj.id!).put(txn, returnObj.toMap());
    });
    // After the transaction completes successfully, explicitly refresh the inventory stream
    _inventoryService.getProducts();

    print(
        'Return processed successfully: Total Refund \$${returnObj.totalRefundAmount.toStringAsFixed(2)}');
  }

  // Get all returns
  Stream<List<Return>> getReturns() {
    return _returnsStreamController.stream;
  }

  // Delete a return record (use with caution, typically returns are not deleted)
  Future<void> deleteReturn(String id) async {
    final db = await AppDatabase.instance;
    final count = await _returnsStore.record(id).delete(db);
    if (count != null) {
      print('Return with ID $id deleted.');
    } else {
      print('Return with ID $id not found for deletion.');
    }
  }

  void dispose() {
    _returnsStreamController.close();
  }
}
