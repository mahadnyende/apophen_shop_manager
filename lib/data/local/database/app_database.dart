import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart'; // For mobile/desktop file system
import 'package:sembast_web/sembast_web.dart'; // For web browser IndexedDB
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:async'; // For Completer
import 'package:flutter/foundation.dart' show kIsWeb; // To check if running on web

class AppDatabase {
  static Database? _database;
  static bool _initialized = false;
  static final Completer<Database> _databaseCompleter = Completer<Database>();

  // Initialize the Sembast database
  static Future<void> initialize() async {
    if (_initialized) {
      return; // Already initialized
    }
    try {
      if (kIsWeb) {
        // Use web factory for browser
        _database = await databaseFactoryWeb.openDatabase('apophen_shop_manager.db');
      } else {
        // Use file system factory for mobile/desktop
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final dbPath = join(documentsDirectory.path, 'apophen_shop_manager.db');
        _database = await databaseFactoryIo.openDatabase(dbPath);
      }
      
      _initialized = true;
      _databaseCompleter.complete(_database); // Complete the completer
      print('Sembast database initialized successfully!');
    } catch (e) {
      print('Error initializing Sembast database: $e');
      if (!_databaseCompleter.isCompleted) {
        _databaseCompleter.completeError(e); // Complete with error if initialization fails
      }
      rethrow;
    }
  }

  // Get the Sembast database instance
  static Future<Database> get instance async {
    if (_database != null) {
      return _database!;
    }
    // If not initialized, wait for it to be completed
    return _databaseCompleter.future;
  }

  // Close the Sembast database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initialized = false;
      print('Sembast database closed.');
    }
  }
}
