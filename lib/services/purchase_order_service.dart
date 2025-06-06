// lib/services/purchase_order_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_item_model.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart';
import 'dart:async';

class PurchaseOrderService {
  final _purchaseOrdersStore = stringMapStoreFactory.store('purchaseOrders');
  final _purchaseOrdersStreamController =
      StreamController<List<PurchaseOrder>>.broadcast();
  final InventoryService _inventoryService = InventoryService();

  PurchaseOrderService() {
    _initPurchaseOrderStream();
  }

  Future<void> _initPurchaseOrderStream() async {
    final db = await AppDatabase.instance;
    _purchaseOrdersStore.query().onSnapshots(db).listen((snapshots) {
      final purchaseOrders = snapshots.map((snapshot) {
        return PurchaseOrder.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _purchaseOrdersStreamController.sink.add(purchaseOrders);
    }, onError: (error) {
      print('Error listening to purchase order stream: $error');
      _purchaseOrdersStreamController.addError(error);
    });
  }

  // Add a new purchase order
  Future<void> addPurchaseOrder(PurchaseOrder po) async {
    final db = await AppDatabase.instance;
    final key = await _purchaseOrdersStore.add(db, po.toMap());
    print('Purchase Order added with key: $key');
    _fetchAndEmitPurchaseOrders(); // Refresh stream
  }

  // Get all purchase orders
  Stream<List<PurchaseOrder>> getPurchaseOrders() {
    return _purchaseOrdersStreamController.stream;
  }

  // Get a single purchase order by ID
  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    final db = await AppDatabase.instance;
    final recordSnapshot =
        await _purchaseOrdersStore.record(id).getSnapshot(db);
    if (recordSnapshot != null) {
      return PurchaseOrder.fromMap(recordSnapshot.value,
          id: recordSnapshot.key);
    }
    return null;
  }

  // Update an existing purchase order
  Future<void> updatePurchaseOrder(PurchaseOrder po) async {
    if (po.id == null) {
      throw Exception('Purchase Order ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _purchaseOrdersStore.record(po.id!).put(db, po.toMap());
    print('Purchase Order updated: ${po.id}');
    _fetchAndEmitPurchaseOrders(); // Refresh stream
  }

  // Delete a purchase order by ID
  Future<void> deletePurchaseOrder(String id) async {
    final db = await AppDatabase.instance;
    final count = await _purchaseOrdersStore.record(id).delete(db);
    if (count != null) {
      print('Purchase Order with ID $id deleted.');
    } else {
      print('Purchase Order with ID $id not found for deletion.');
    }
    _fetchAndEmitPurchaseOrders(); // Refresh stream
  }

  // Receive stock for a purchase order (or part of it)
  Future<void> receiveStock(
      String poId, List<PurchaseOrderItem> receivedItems) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      final poRecord = _purchaseOrdersStore.record(poId);
      final snapshot = await poRecord.getSnapshot(txn);

      if (snapshot == null) {
        throw Exception('Purchase Order not found: $poId');
      }

      final po = PurchaseOrder.fromMap(snapshot.value, id: snapshot.key);

      // Update received quantities for items in the PO
      for (var receivedItem in receivedItems) {
        final poItemIndex = po.items
            .indexWhere((item) => item.productId == receivedItem.productId);
        if (poItemIndex != -1) {
          final currentPoItem = po.items[poItemIndex];
          final totalReceived =
              currentPoItem.receivedQuantity + receivedItem.receivedQuantity;

          if (totalReceived > currentPoItem.orderedQuantity) {
            throw Exception(
                'Received quantity for ${currentPoItem.productName} exceeds ordered quantity.');
          }
          currentPoItem.receivedQuantity =
              totalReceived; // Update received quantity on the PO item

          // Also update inventory stock
          await _inventoryService.adjustStock(
            receivedItem.productId,
            receivedItem.receivedQuantity, // Increase stock
            txn, // Pass the transaction object
          );
        } else {
          print(
              'Warning: Received item ${receivedItem.productName} not found in PO $poId.');
        }
      }

      // Update PO status based on received quantities
      bool allReceived = po.items
          .every((item) => item.receivedQuantity >= item.orderedQuantity);
      bool anyReceived = po.items.any((item) => item.receivedQuantity > 0);

      if (allReceived) {
        po.status = PurchaseOrderStatus.received;
      } else if (anyReceived) {
        po.status = PurchaseOrderStatus.partiallyReceived;
      } else {
        // Status remains as it was (e.g., pending, ordered)
      }

      await poRecord.put(txn, po.toMap());
      print('Stock received for PO $poId. New status: ${po.status.name}');
    });
    _fetchAndEmitPurchaseOrders(); // Refresh PO stream
    _inventoryService
        .getProducts(); // Refresh inventory stream after stock update
  }

  // Helper to fetch and emit purchase orders to the stream
  Future<void> _fetchAndEmitPurchaseOrders() async {
    final db = await AppDatabase.instance;
    final snapshots = await _purchaseOrdersStore.find(db);
    final purchaseOrders = snapshots.map((snapshot) {
      return PurchaseOrder.fromMap(snapshot.value, id: snapshot.key);
    }).toList();
    _purchaseOrdersStreamController.sink.add(purchaseOrders);
  }

  // Dispose method
  void dispose() {
    _purchaseOrdersStreamController.close();
  }
}
