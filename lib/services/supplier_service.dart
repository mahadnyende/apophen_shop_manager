// lib/services/supplier_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/purchases/supplier_model.dart';
import 'dart:async'; // For StreamController

class SupplierService {
  final _suppliersStore =
      stringMapStoreFactory.store('suppliers'); // Define a store for suppliers
  final _suppliersStreamController =
      StreamController<List<Supplier>>.broadcast();

  SupplierService() {
    _initSupplierStream(); // Initialize the stream to listen to changes
  }

  // Initialize the stream by listening to the Sembast store
  Future<void> _initSupplierStream() async {
    final db = await AppDatabase.instance;
    _suppliersStore.query().onSnapshots(db).listen((snapshots) {
      final suppliers = snapshots.map((snapshot) {
        return Supplier.fromMap(snapshot.value,
            id: snapshot.key); // Pass key as ID
      }).toList();
      _suppliersStreamController.sink.add(suppliers);
    }, onError: (error) {
      print('Error listening to supplier stream: $error');
      _suppliersStreamController.addError(error);
    });
  }

  // Add a new supplier to the database
  Future<void> addSupplier(Supplier supplier) async {
    final db = await AppDatabase.instance;
    final key = await _suppliersStore.add(db, supplier.toMap());
    print('Supplier added with key: $key');
    _fetchAndEmitSuppliers(); // Trigger refresh after adding
  }

  // Get all suppliers from the database (stream)
  Stream<List<Supplier>> getSuppliers() {
    return _suppliersStreamController.stream;
  }

  // Get a single supplier by ID
  Future<Supplier?> getSupplierById(String id) async {
    final db = await AppDatabase.instance;
    final recordSnapshot = await _suppliersStore.record(id).getSnapshot(db);
    if (recordSnapshot != null) {
      return Supplier.fromMap(recordSnapshot.value, id: recordSnapshot.key);
    }
    return null;
  }

  // Update an existing supplier
  Future<void> updateSupplier(Supplier supplier) async {
    if (supplier.id == null) {
      throw Exception('Supplier ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _suppliersStore.record(supplier.id!).put(db, supplier.toMap());
    print('Supplier updated: ${supplier.name}');
    _fetchAndEmitSuppliers(); // Trigger refresh after updating
  }

  // Delete a supplier by ID
  Future<void> deleteSupplier(String id) async {
    final db = await AppDatabase.instance;
    final count = await _suppliersStore.record(id).delete(db);
    if (count != null) {
      print('Supplier with ID $id deleted.');
    } else {
      print('Supplier with ID $id not found for deletion.');
    }
    _fetchAndEmitSuppliers(); // Trigger refresh after deleting
  }

  // Helper to fetch and emit suppliers to the stream
  Future<void> _fetchAndEmitSuppliers() async {
    final db = await AppDatabase.instance;
    final snapshots = await _suppliersStore.find(db);
    final suppliers = snapshots.map((snapshot) {
      return Supplier.fromMap(snapshot.value, id: snapshot.key);
    }).toList();
    _suppliersStreamController.sink.add(suppliers);
  }

  // Don't forget to close the stream controller when the service is no longer needed
  void dispose() {
    _suppliersStreamController.close();
  }
}
