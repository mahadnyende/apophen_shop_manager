// lib/services/employee_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/employees/employee_model.dart';
import 'dart:async'; // For StreamController

class EmployeeService {
  final _employeesStore =
      stringMapStoreFactory.store('employees'); // Define a store for employees
  final _employeesStreamController =
      StreamController<List<Employee>>.broadcast();

  EmployeeService() {
    _initEmployeeStream(); // Initialize the stream to listen to changes
  }

  // Initialize the stream by listening to the Sembast store
  Future<void> _initEmployeeStream() async {
    final db = await AppDatabase.instance;
    _employeesStore.query().onSnapshots(db).listen((snapshots) {
      final employees = snapshots.map((snapshot) {
        return Employee.fromMap(snapshot.value,
            id: snapshot.key); // Pass key as ID
      }).toList();
      _employeesStreamController.sink.add(employees);
    }, onError: (error) {
      print('Error listening to employee stream: $error');
      _employeesStreamController.addError(error);
    });
  }

  // Add a new employee to the database
  Future<void> addEmployee(Employee employee) async {
    final db = await AppDatabase.instance;
    final key = await _employeesStore.add(db, employee.toMap());
    print('Employee added with key: $key');
    _fetchAndEmitEmployees(); // Trigger refresh after adding
  }

  // Get all employees from the database (stream)
  Stream<List<Employee>> getEmployees() {
    return _employeesStreamController.stream;
  }

  // Get a single employee by ID
  Future<Employee?> getEmployeeById(String id) async {
    final db = await AppDatabase.instance;
    final recordSnapshot = await _employeesStore.record(id).getSnapshot(db);
    if (recordSnapshot != null) {
      return Employee.fromMap(recordSnapshot.value, id: recordSnapshot.key);
    }
    return null;
  }

  // Update an existing employee
  Future<void> updateEmployee(Employee employee) async {
    if (employee.id == null) {
      throw Exception('Employee ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _employeesStore.record(employee.id!).put(db, employee.toMap());
    print('Employee updated: ${employee.fullName}');
    _fetchAndEmitEmployees(); // Trigger refresh after updating
  }

  // Delete an employee by ID
  Future<void> deleteEmployee(String id) async {
    final db = await AppDatabase.instance;
    final count = await _employeesStore.record(id).delete(db);
    if (count != null) {
      print('Employee with ID $id deleted.');
    } else {
      print('Employee with ID $id not found for deletion.');
    }
    _fetchAndEmitEmployees(); // Trigger refresh after deleting
  }

  // Helper to fetch and emit employees to the stream
  Future<void> _fetchAndEmitEmployees() async {
    final db = await AppDatabase.instance;
    final snapshots = await _employeesStore.find(db);
    final employees = snapshots.map((snapshot) {
      return Employee.fromMap(snapshot.value, id: snapshot.key);
    }).toList();
    _employeesStreamController.sink.add(employees);
  }

  // Don't forget to close the stream controller when the service is no longer needed
  void dispose() {
    _employeesStreamController.close();
  }
}
