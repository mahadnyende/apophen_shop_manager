// lib/services/customer_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/crm/customer_model.dart';
import 'dart:async';

class CustomerService {
  final _customerStore =
      stringMapStoreFactory.store('customers'); // Define a store for customers
  final _customersStreamController =
      StreamController<List<Customer>>.broadcast();

  CustomerService() {
    _initCustomerStream(); // Initialize the stream to listen to changes
  }

  // Initialize the stream by listening to the Sembast store
  Future<void> _initCustomerStream() async {
    final db = await AppDatabase.instance;
    _customerStore.query().onSnapshots(db).listen((snapshots) {
      final customers = snapshots.map((snapshot) {
        return Customer.fromMap(snapshot.value,
            id: snapshot.key); // Pass key as ID
      }).toList();
      _customersStreamController.sink.add(customers);
    }, onError: (error) {
      print('Error listening to customer stream: $error');
      _customersStreamController.addError(error);
    });
  }

  // Add a new customer to the database
  Future<void> addCustomer(Customer customer) async {
    final db = await AppDatabase.instance;
    final key = await _customerStore.add(db, customer.toMap());
    print('Customer added with key: $key');
    _fetchAndEmitCustomers(); // Trigger refresh after adding
  }

  // Get all customers from the database (stream)
  Stream<List<Customer>> getCustomers() {
    return _customersStreamController.stream;
  }

  // Get a single customer by ID
  Future<Customer?> getCustomerById(String id) async {
    final db = await AppDatabase.instance;
    final recordSnapshot = await _customerStore.record(id).getSnapshot(db);
    if (recordSnapshot != null) {
      return Customer.fromMap(recordSnapshot.value, id: recordSnapshot.key);
    }
    return null;
  }

  // Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw Exception('Customer ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _customerStore.record(customer.id!).put(db, customer.toMap());
    print('Customer updated: ${customer.fullName}');
    _fetchAndEmitCustomers(); // Trigger refresh after updating
  }

  // Delete a customer by ID
  Future<void> deleteCustomer(String id) async {
    final db = await AppDatabase.instance;
    final count = await _customerStore.record(id).delete(db);
    if (count != null) {
      print('Customer with ID $id deleted.');
    } else {
      print('Customer with ID $id not found for deletion.');
    }
    _fetchAndEmitCustomers(); // Trigger refresh after deleting
  }

  // Helper to fetch and emit customers to the stream
  Future<void> _fetchAndEmitCustomers() async {
    final db = await AppDatabase.instance;
    final snapshots = await _customerStore.find(db);
    final customers = snapshots.map((snapshot) {
      return Customer.fromMap(snapshot.value, id: snapshot.key);
    }).toList();
    _customersStreamController.sink.add(customers);
  }

  // Don't forget to close the stream controller when the service is no longer needed
  void dispose() {
    _customersStreamController.close();
  }
}
