import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/crm/customer_model.dart';
import 'dart:async';

class CustomerService {
  final _customerStore = stringMapStoreFactory.store('customers');
  final _customerStreamController = StreamController<List<Customer>>.broadcast();

  CustomerService() {
    _initCustomerStream();
  }

  Future<void> _initCustomerStream() async {
    final db = await AppDatabase.instance;
    _customerStore.query().onSnapshots(db).listen((snapshots) {
      final customers = snapshots.map((snapshot) {
        return Customer.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _customerStreamController.sink.add(customers);
    }, onError: (error) {
      print('Error listening to customer stream: $error');
      _customerStreamController.addError(error);
    });
  }

  Future<void> addCustomer(Customer customer) async {
    final db = await AppDatabase.instance;
    final key = await _customerStore.add(db, customer.toMap());
    print('Customer added with key: $key');
  }

  Stream<List<Customer>> getCustomers() {
    return _customerStreamController.stream;
  }

  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw Exception('Customer ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _customerStore.record(customer.id!).put(db, customer.toMap());
    print('Customer updated: ${customer.name}');
  }

  Future<void> deleteCustomer(String id) async {
    final db = await AppDatabase.instance;
    final count = await _customerStore.record(id).delete(db);
    if (count != null) {
      print('Customer with ID $id deleted.');
    } else {
      print('Customer with ID $id not found for deletion.');
    }
  }

  void dispose() {
    _customerStreamController.close();
  }
}
