import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/purchase_order_item_model.dart';
import 'package:apophen_shop_manager/services/inventory_service.dart'; // For updating product stock
import 'dart:async';

class PurchaseOrderService {
  final _poStore = stringMapStoreFactory.store('purchaseOrders');
  final _poStreamController = StreamController<List<PurchaseOrder>>.broadcast();
  final InventoryService _inventoryService = InventoryService();

  PurchaseOrderService() {
    _initPoStream();
  }

  Future<void> _initPoStream() async {
    final db = await AppDatabase.instance;
    _poStore.query().onSnapshots(db).listen((snapshots) {
      final pos = snapshots.map((snapshot) {
        return PurchaseOrder.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _poStreamController.sink.add(pos);
    }, onError: (error) {
      print('Error listening to purchase order stream: $error');
      _poStreamController.addError(error);
    });
  }

  // Add a new purchase order
  Future<void> addPurchaseOrder(PurchaseOrder po) async {
    final db = await AppDatabase.instance;
    final key = await _poStore.add(db, po.toMap());
    print('Purchase Order added with key: $key');
  }

  // Get all purchase orders
  Stream<List<PurchaseOrder>> getPurchaseOrders() {
    return _poStreamController.stream;
  }

  // Update an existing purchase order
  Future<void> updatePurchaseOrder(PurchaseOrder po) async {
    if (po.id == null) {
      throw Exception('Purchase Order ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _poStore.record(po.id!).put(db, po.toMap());
    print('Purchase Order updated: ${po.id}');
  }

  // Delete a purchase order
  Future<void> deletePurchaseOrder(String id) async {
    final db = await AppDatabase.instance;
    final count = await _poStore.record(id).delete(db);
    if (count != null) {
      print('Purchase Order with ID $id deleted.');
    } else {
      print('Purchase Order with ID $id not found for deletion.');
    }
  }

  // Receive items for a specific purchase order
  Future<void> receiveItems(String poId, List<PurchaseOrderItem> receivedItems) async {
    final db = await AppDatabase.instance;

    await db.transaction((txn) async {
      final poSnapshot = await _poStore.record(poId).getSnapshot(txn);
      if (poSnapshot == null) {
        throw Exception('Purchase Order with ID $poId not found.');
      }

      final po = PurchaseOrder.fromMap(poSnapshot.value, id: poSnapshot.key);
      bool allItemsFullyReceived = true;

      for (var incomingItem in receivedItems) {
        final existingItemIndex = po.items.indexWhere((item) => item.productId == incomingItem.productId);

        if (existingItemIndex != -1) {
          final existingItem = po.items[existingItemIndex];
          final newReceivedQuantity = existingItem.receivedQuantity + incomingItem.receivedQuantity;

          if (newReceivedQuantity > existingItem.orderedQuantity) {
            throw Exception('Received quantity for ${existingItem.productName} exceeds ordered quantity.');
          }

          existingItem.receivedQuantity = newReceivedQuantity;

          // Update product stock in InventoryService
          await _inventoryService.adjustStock(
            incomingItem.productId,
            incomingItem.receivedQuantity, // Increase stock
            txn, // Pass the transaction
          );

          if (existingItem.receivedQuantity < existingItem.orderedQuantity) {
            allItemsFullyReceived = false;
          }
        } else {
          // This case should ideally not happen if receiving against an existing PO,
          // but good for robustness or if partial PO creation is allowed
          print('Warning: Received item ${incomingItem.productName} not found in PO ${po.id}. Not updating stock.');
          // You might choose to throw an error or handle this differently
        }
      }

      // Update PO status based on received items
      if (allItemsFullyReceived) {
        po.status = PurchaseOrderStatus.received;
      } else {
        po.status = PurchaseOrderStatus.partiallyReceived;
      }
      po.lastModified = DateTime.now(); // Update last modified date

      await _poStore.record(po.id!).put(txn, po.toMap());
    });
    // Trigger inventory stream update after the transaction
    _inventoryService.getProducts();
    print('Items received for Purchase Order $poId.');
  }

  void dispose() {
    _poStreamController.close();
  }
}
