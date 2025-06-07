// lib/services/expense_service.dart
import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/data/models/purchases/expense_model.dart';
import 'dart:async'; // For StreamController

class ExpenseService {
  final _expensesStore =
      stringMapStoreFactory.store('expenses'); // Define a store for expenses
  final _expensesStreamController = StreamController<List<Expense>>.broadcast();

  ExpenseService() {
    _initExpenseStream();
  }

  Future<void> _initExpenseStream() async {
    final db = await AppDatabase.instance;
    _expensesStore.query().onSnapshots(db).listen((snapshots) {
      final expenses = snapshots.map((snapshot) {
        return Expense.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _expensesStreamController.sink.add(expenses);
    }, onError: (error) {
      print('Error listening to expense stream: $error');
      _expensesStreamController.addError(error);
    });
  }

  Future<void> addExpense(Expense expense) async {
    final db = await AppDatabase.instance;
    final key = await _expensesStore.add(db, expense.toMap());
    print('Expense added with key: $key');
  }

  Stream<List<Expense>> getExpenses() {
    return _expensesStreamController.stream;
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw Exception('Expense ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _expensesStore.record(expense.id!).put(db, expense.toMap());
    print('Expense updated: ${expense.title}');
  }

  Future<void> deleteExpense(String id) async {
    final db = await AppDatabase.instance;
    final count = await _expensesStore.record(id).delete(db);
    if (count != null) {
      print('Expense with ID $id deleted.');
    } else {
      print('Expense with ID $id not found for deletion.');
    }
  }

  void dispose() {
    _expensesStreamController.close();
  }
}
