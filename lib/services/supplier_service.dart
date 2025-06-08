import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/purchases/supplier_model.dart';
import 'dart:async';

class SupplierService {
  final _supplierStore = stringMapStoreFactory.store('suppliers');
  final _supplierStreamController = StreamController<List<Supplier>>.broadcast();

  SupplierService() {
    _initSupplierStream();
  }

  Future<void> _initSupplierStream() async {
    final db = await AppDatabase.instance;
    _supplierStore.query().onSnapshots(db).listen((snapshots) {
      final suppliers = snapshots.map((snapshot) {
        return Supplier.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _supplierStreamController.sink.add(suppliers);
    }, onError: (error) {
      print('Error listening to supplier stream: $error');
      _supplierStreamController.addError(error);
    });
  }

  Future<void> addSupplier(Supplier supplier) async {
    final db = await AppDatabase.instance;
    final key = await _supplierStore.add(db, supplier.toMap());
    print('Supplier added with key: $key');
  }

  Stream<List<Supplier>> getSuppliers() {
    return _supplierStreamController.stream;
  }

  Future<void> updateSupplier(Supplier supplier) async {
    if (supplier.id == null) {
      throw Exception('Supplier ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _supplierStore.record(supplier.id!).put(db, supplier.toMap());
    print('Supplier updated: ${supplier.name}');
  }

  Future<void> deleteSupplier(String id) async {
    final db = await AppDatabase.instance;
    final count = await _supplierStore.record(id).delete(db);
    if (count != null) {
      print('Supplier with ID $id deleted.');
    } else {
      print('Supplier with ID $id not found for deletion.');
    }
  }

  void dispose() {
    _supplierStreamController.close();
  }
}
