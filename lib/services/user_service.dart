import 'package:sembast/sembast.dart';
import 'package:apophen_shop_manager/data/local/database/app_database.dart';
import 'package:apophen_shop_manager/models/user_model.dart';
import 'dart:async';

class UserService {
  final _userStore = stringMapStoreFactory.store('users'); // Define a store for users
  final _usersStreamController = StreamController<List<User>>.broadcast();

  UserService() {
    _initUserStream();
  }

  Future<void> _initUserStream() async {
    final db = await AppDatabase.instance;
    _userStore.query().onSnapshots(db).listen((snapshots) {
      final users = snapshots.map((snapshot) {
        return User.fromMap(snapshot.value, id: snapshot.key);
      }).toList();
      _usersStreamController.sink.add(users);
    }, onError: (error) {
      print('Error listening to user stream: $error');
      _usersStreamController.addError(error);
    });
  }

  // Add a new user
  Future<void> addUser(User user) async {
    final db = await AppDatabase.instance;
    // Check for unique username
    final existingUser = await _userStore.findFirst(db,
        finder: Finder(filter: Filter.equals('username', user.username)));

    if (existingUser != null) {
      throw Exception('Username ${user.username} already exists.');
    }
    final key = await _userStore.add(db, user.toMap());
    print('User added with key: $key');
  }

  // Get all users
  Stream<List<User>> getUsers() {
    return _usersStreamController.stream;
  }

  // Find a user by username and password (for authentication)
  Future<User?> findUser(String username, String password) async {
    final db = await AppDatabase.instance;
    final recordSnapshot = await _userStore.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('username', username),
          Filter.equals('password', password), // In production, compare hashed passwords
        ])));
    if (recordSnapshot != null) {
      return User.fromMap(recordSnapshot.value, id: recordSnapshot.key);
    }
    return null;
  }

  // NEW: Public method to check if any users exist in the store
  Future<bool> hasUsers() async {
    final db = await AppDatabase.instance;
    final count = await _userStore.count(db);
    return count > 0;
  }

  // Update an existing user
  Future<void> updateUser(User user) async {
    if (user.id == null) {
      throw Exception('User ID is required for update.');
    }
    final db = await AppDatabase.instance;
    await _userStore.record(user.id!).put(db, user.toMap());
    print('User updated: ${user.username}');
  }

  // Delete a user
  Future<void> deleteUser(String id) async {
    final db = await AppDatabase.instance;
    final count = await _userStore.record(id).delete(db);
    if (count != null) {
      print('User with ID $id deleted.');
    } else {
      print('User with ID $id not found for deletion.');
    }
  }

  void dispose() {
    _usersStreamController.close();
  }
}
