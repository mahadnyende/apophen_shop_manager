import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/crm/employee_model.dart';
import 'dart:async';

class EmployeeService {
  final _employeeStore = stringMapStoreFactory.store('employees');
  final _employeeStreamController = StreamController<List<Employee>>.broadcast();

  EmployeeService() {
    _initEmployeeStream();
  }

  Future<void> _initEmployeeStream() async {
    final db = await AppDatabase.instance;
    _employeeStore.query().onSnapshots(db).listen((snapshots) {
      final employees = snapshots.map((snapshot) {
        return Employee.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _employeeStreamController.sink.add(employees);
    }, onError: (error) {
      print('Error listening to employee stream: $error');
      _employeeStreamController.addError(error);
    });
  }

  Future<void> addEmployee(Employee employee) async {
    final db = await AppDatabase.instance;
    final key = await _employeeStore.add(db, employee.toMap());
    print('Employee added with key: $key');
  }

  Stream<List<Employee>> getEmployees() {
    return _employeeStreamController.stream;
  }

  Future<void> updateEmployee(Employee employee) async {
    if (employee.id == null) {
      throw Exception('Employee ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _employeeStore.record(employee.id!).put(db, employee.toMap());
    print('Employee updated: ${employee.name}');
  }

  Future<void> deleteEmployee(String id) async {
    final db = await AppDatabase.instance;
    final count = await _employeeStore.record(id).delete(db);
    if (count != null) {
      print('Employee with ID $id deleted.');
    } else {
      print('Employee with ID $id not found for deletion.');
    }
  }

  void dispose() {
    _employeeStreamController.close();
  }
}
