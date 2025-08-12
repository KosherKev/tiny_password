import 'dart:convert';
import 'dart:io' show File, Directory, Platform;
import 'package:path/path.dart' show join, dirname;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/encryption/encryption_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../domain/models/record.dart';
import '../../domain/repositories/record_repository.dart';

class SQLiteRecordRepository implements RecordRepository {
  Database? _database;
  final EncryptionService _encryptionService = EncryptionService();
  final SecureStorageService _secureStorage = SecureStorageService();
  bool _isInitialized = false;
  String? _databasePath;

  Future<Database> get database async {
    if (!_isInitialized) throw Exception('Repository not initialized');
    if (_database == null) throw Exception('Database not initialized');
    return _database!;
  }

  @override
  Future<void> dispose() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      _isInitialized = false;
      print('Repository disposed successfully');
    } catch (e) {
      print('Error disposing repository: $e');
    }
  }

  /// Delete the database file completely
  Future<void> deleteDatabase() async {
    try {
      // First dispose of any open connections
      await dispose();
      
      // Then delete the file if it exists
      if (_databasePath != null) {
        final dbFile = File(_databasePath!);
        if (await dbFile.exists()) {
          await dbFile.delete();
          print('Database file deleted successfully');
        }
      }
    } catch (e) {
      print('Error deleting database file: $e');
      throw Exception('Failed to delete database file: $e');
    }
  }

  /// Initialize repository with proper error handling and recovery
  Future<void> initialize() async {
    if (_isInitialized) {
      print('Repository already initialized');
      return;
    }

    try {
      print('Starting repository initialization...');
      
      // Step 1: Get or create database password
      String? dbPassword = await _getOrCreateDatabasePassword();
      print('Database password obtained');

      // Step 2: Get database path with fallback handling
      _databasePath = await _getDatabasePath();
      print('Database path: $_databasePath');

      // Step 3: Initialize database with recovery
      _database = await _initDatabaseWithRecovery(dbPassword);
      print('Database initialized successfully');

      _isInitialized = true;
      print('Repository initialization completed');
    } catch (e) {
      _isInitialized = false;
      print('Repository initialization failed: $e');
      throw Exception('Failed to initialize repository: $e');
    }
  }

  /// Get existing database password or create a new one
  Future<String> _getOrCreateDatabasePassword() async {
    try {
      String? dbPassword = await _secureStorage.getDatabasePassword();
      
      if (dbPassword == null) {
        print('Generating new database password');
        dbPassword = _encryptionService.generateDatabasePassword();
        await _secureStorage.storeDatabasePassword(dbPassword);
        print('Database password stored securely');
      } else {
        print('Using existing database password');
      }
      
      return dbPassword;
    } catch (e) {
      print('Error handling database password: $e');
      throw Exception('Failed to get database password: $e');
    }
  }

  /// Get database path with proper platform handling
  Future<String> _getDatabasePath() async {
    try {
      // Try to get the application documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, AppConstants.dbName);
      print('Using documents directory: $path');
      return path;
    } catch (e) {
      print('Failed to get documents directory: $e');
      
      // Platform-specific fallbacks
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        try {
          final currentDir = Directory.current.path;
          final dataDir = Directory(join(currentDir, 'data'));
          
          // Create data directory if it doesn't exist
          if (!await dataDir.exists()) {
            await dataDir.create(recursive: true);
          }
          
          final path = join(dataDir.path, AppConstants.dbName);
          print('Using fallback directory: $path');
          return path;
        } catch (e2) {
          print('Fallback path creation failed: $e2');
          throw Exception('Cannot create database directory: $e2');
        }
      } else {
        // For mobile platforms, this should not happen, but provide emergency fallback
        throw Exception('Cannot determine database path for this platform');
      }
    }
  }

  /// Initialize database with recovery mechanisms
  Future<Database> _initDatabaseWithRecovery(String dbPassword) async {
    try {
      print('Attempting to open database...');
      return await _openDatabase(_databasePath!, dbPassword);
    } catch (e) {
      print('Database open failed: $e');
      
      // If we can't open the database, try recovery
      if (_databasePath != ':memory:') {
        await _recoverDatabase(_databasePath!);
        // Try again with the same password after recovery
        return await _openDatabase(_databasePath!, dbPassword);
      } else {
        throw Exception('Cannot recover in-memory database: $e');
      }
    }
  }

  /// Open database with proper error handling
  Future<Database> _openDatabase(String path, String dbPassword) async {
    try {
      print('Opening database at: $path');
      
      // Ensure directory exists
      if (path != ':memory:') {
        final directory = Directory(dirname(path));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }

      final db = await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onOpen: (db) async {
          print('Database opened successfully');
          // Test the database is working by running a simple query
          try {
            await db.rawQuery('SELECT 1');
            print('Database connectivity test passed');
          } catch (e) {
            print('Database connectivity test failed: $e');
            throw Exception('Database is not functional: $e');
          }
        },
        password: dbPassword, // Using password parameter for SQLCipher encryption
      );
      
      return db;
    } catch (e) {
      print('Failed to open database: $e');
      throw Exception('Cannot open database: $e');
    }
  }

  /// Recover corrupted database
  Future<void> _recoverDatabase(String path) async {
    try {
      print('Attempting database recovery...');
      
      // First close any open database connections
      await dispose();
      
      // Check if file exists
      final file = File(path);
      if (await file.exists()) {
        // Create backup of corrupted file
        final backupPath = '$path.corrupted.${DateTime.now().millisecondsSinceEpoch}';
        await file.copy(backupPath);
        print('Backed up corrupted database to: $backupPath');
        
        // Delete the corrupted file
        await file.delete();
        print('Deleted corrupted database file');
      }
      
      // Also check for and delete any temporary database files
      final dir = Directory(dirname(path));
      if (await dir.exists()) {
        final tempFiles = await dir.list().where((entity) =>
          entity is File && entity.path.contains('tiny_password.db-')
        ).toList();
        
        for (final entity in tempFiles) {
          await entity.delete();
          print('Deleted temporary database file: ${entity.path}');
        }
      }
      
      // Clear the stored database password so a new one will be generated
      await _secureStorage.deleteAll();
      print('Cleared stored credentials for fresh start');
      
    } catch (e) {
      print('Database recovery failed: $e');
      // Continue anyway - the database creation will start fresh
    }
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    print('Creating new database schema...');
    
    try {
      // Create records table
      await db.execute('''
        CREATE TABLE records(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          fields TEXT NOT NULL,
          notes TEXT,
          category TEXT NOT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          modified_at TEXT NOT NULL
        )
      ''');
      print('Records table created');

      // Create categories table
      await db.execute('''
        CREATE TABLE categories(
          name TEXT PRIMARY KEY,
          created_at TEXT NOT NULL
        )
      ''');
      print('Categories table created');

      // Create indexes
      await db.execute('CREATE INDEX idx_records_category ON records(category)');
      await db.execute('CREATE INDEX idx_records_type ON records(type)');
      await db.execute('CREATE INDEX idx_records_is_favorite ON records(is_favorite)');
      print('Indexes created');

      // Insert default categories
      final batch = db.batch();
      for (final category in AppConstants.defaultCategories) {
        batch.insert('categories', {
          'name': category,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
      print('Default categories inserted');
      
      print('Database schema created successfully');
    } catch (e) {
      print('Failed to create database schema: $e');
      throw Exception('Database schema creation failed: $e');
    }
  }

  /// Initialize record encryption when master password is available
  Future<void> initializeRecordEncryption(String masterPassword) async {
    try {
      print('Initializing record encryption...');
      await _encryptionService.initializeWithMasterPassword(masterPassword);
      print('Record encryption initialized successfully');
    } catch (e) {
      print('Failed to initialize record encryption: $e');
      throw Exception('Failed to initialize record encryption: $e');
    }
  }

  /// Reset record encryption (for password changes)
  void resetRecordEncryption() {
    _encryptionService.reset();
    print('Record encryption reset');
  }

  @override
  Future<List<String>> getAllCategories() async {
    try {
      final db = await database;
      final categories = await db.query('categories', columns: ['name']);
      return categories.map((category) => category['name'] as String).toList();
    } catch (e) {
      print('Error getting categories: $e');
      throw Exception('Failed to get categories: $e');
    }
  }

  @override
  Future<int> getRecordCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM records');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting record count: $e');
      return 0;
    }
  }

  @override
  Future<int> getCategoryCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting category count: $e');
      return 0;
    }
  }

  @override
  Future<List<Record>> getAllRecords() async {
    try {
      final db = await database;
      final records = await db.query('records', orderBy: 'modified_at DESC');
      return records.map((record) => _decryptRecord(record)).toList();
    } catch (e) {
      print('Error getting all records: $e');
      throw Exception('Failed to get records: $e');
    }
  }

  @override
  Future<Record?> getRecordById(String id) async {
    try {
      final db = await database;
      final records = await db.query('records', where: 'id = ?', whereArgs: [id]);
      if (records.isEmpty) return null;
      return _decryptRecord(records.first);
    } catch (e) {
      print('Error getting record by ID: $e');
      throw Exception('Failed to get record: $e');
    }
  }

  @override
  Future<List<Record>> getRecordsByCategory(String category) async {
    try {
      final db = await database;
      final records = await db.query(
        'records',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'modified_at DESC',
      );
      return records.map((record) => _decryptRecord(record)).toList();
    } catch (e) {
      print('Error getting records by category: $e');
      throw Exception('Failed to get records by category: $e');
    }
  }

  @override
  Future<List<Record>> getFavoriteRecords() async {
    try {
      final db = await database;
      final records = await db.query(
        'records',
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'modified_at DESC',
      );
      return records.map((record) => _decryptRecord(record)).toList();
    } catch (e) {
      print('Error getting favorite records: $e');
      throw Exception('Failed to get favorite records: $e');
    }
  }

  @override
  Future<List<Record>> searchRecords(String query) async {
    try {
      final db = await database;
      final records = await db.query(
        'records',
        where: 'title LIKE ? OR notes LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'modified_at DESC',
      );
      return records.map((record) => _decryptRecord(record)).toList();
    } catch (e) {
      print('Error searching records: $e');
      throw Exception('Failed to search records: $e');
    }
  }

  @override
  Future<Record> createRecord(Record record) async {
    try {
      final db = await database;
      final encryptedRecord = _encryptRecord(record);
      await db.insert('records', encryptedRecord);
      print('Record created successfully: ${record.id}');
      return record;
    } catch (e) {
      print('Error creating record: $e');
      throw Exception('Failed to create record: $e');
    }
  }

  @override
  Future<Record> updateRecord(Record record) async {
    try {
      final db = await database;
      final updatedRecord = record.copyWith(modifiedAt: DateTime.now());
      final encryptedRecord = _encryptRecord(updatedRecord);
      await db.update(
        'records',
        encryptedRecord,
        where: 'id = ?',
        whereArgs: [record.id],
      );
      print('Record updated successfully: ${record.id}');
      return updatedRecord;
    } catch (e) {
      print('Error updating record: $e');
      throw Exception('Failed to update record: $e');
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    try {
      final db = await database;
      await db.delete('records', where: 'id = ?', whereArgs: [id]);
      print('Record deleted successfully: $id');
    } catch (e) {
      print('Error deleting record: $e');
      throw Exception('Failed to delete record: $e');
    }
  }

  @override
  Future<void> deleteRecords(List<String> ids) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (final id in ids) {
        batch.delete('records', where: 'id = ?', whereArgs: [id]);
      }
      await batch.commit();
      print('Multiple records deleted successfully');
    } catch (e) {
      print('Error deleting multiple records: $e');
      throw Exception('Failed to delete records: $e');
    }
  }

  @override
  Future<Record> toggleFavorite(String id) async {
    try {
      final record = await getRecordById(id);
      if (record == null) throw Exception('Record not found');

      final updatedRecord = record.copyWith(
        isFavorite: !record.isFavorite,
        modifiedAt: DateTime.now(),
      );
      await updateRecord(updatedRecord);
      return updatedRecord;
    } catch (e) {
      print('Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  @override
  Future<Record> moveToCategory(String id, String category) async {
    try {
      final record = await getRecordById(id);
      if (record == null) throw Exception('Record not found');

      final updatedRecord = record.copyWith(
        category: category,
        modifiedAt: DateTime.now(),
      );
      await updateRecord(updatedRecord);
      return updatedRecord;
    } catch (e) {
      print('Error moving record to category: $e');
      throw Exception('Failed to move record to category: $e');
    }
  }

  @override
  Future<void> createCategory(String category) async {
    try {
      final db = await database;
      await db.insert('categories', {
        'name': category,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Category created successfully: $category');
    } catch (e) {
      print('Error creating category: $e');
      throw Exception('Failed to create category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String category, {bool deleteRecords = false}) async {
    try {
      final db = await database;
      final batch = db.batch();

      if (deleteRecords) {
        batch.delete('records', where: 'category = ?', whereArgs: [category]);
      } else {
        // Move records to 'Other' category
        batch.update(
          'records',
          {'category': 'Other'},
          where: 'category = ?',
          whereArgs: [category],
        );
      }

      batch.delete('categories', where: 'name = ?', whereArgs: [category]);
      await batch.commit();
      print('Category deleted successfully: $category');
    } catch (e) {
      print('Error deleting category: $e');
      throw Exception('Failed to delete category: $e');
    }
  }

  @override
  Future<void> renameCategory(String oldName, String newName) async {
    try {
      final db = await database;
      final batch = db.batch();

      // Update category name
      batch.update(
        'categories',
        {'name': newName},
        where: 'name = ?',
        whereArgs: [oldName],
      );

      // Update records with old category name
      batch.update(
        'records',
        {'category': newName},
        where: 'category = ?',
        whereArgs: [oldName],
      );

      await batch.commit();
      print('Category renamed successfully: $oldName -> $newName');
    } catch (e) {
      print('Error renaming category: $e');
      throw Exception('Failed to rename category: $e');
    }
  }

  @override
  Future<String> exportToBackup(String password) async {
    try {
      final records = await getAllRecords();
      final categories = await getAllCategories();

      final backupData = {
        'records': records.map((r) => r.toJson()).toList(),
        'categories': categories,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonData = jsonEncode(backupData);
      return _encryptionService.encrypt(jsonData);
    } catch (e) {
      print('Error exporting backup: $e');
      throw Exception('Failed to export backup: $e');
    }
  }

  @override
  Future<void> importFromBackup(String backupData, String password) async {
    try {
      final decryptedData = _encryptionService.decrypt(backupData);
      final jsonData = jsonDecode(decryptedData);

      final db = await database;
      await db.transaction((txn) async {
        // Clear existing data
        await txn.delete('records');
        await txn.delete('categories');

        // Import categories
        final categories = List<String>.from(jsonData['categories']);
        for (final category in categories) {
          await txn.insert('categories', {
            'name': category,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // Import records
        final records = List<Map<String, dynamic>>.from(jsonData['records']);
        for (final recordData in records) {
          final record = Record.fromJson(recordData);
          final encryptedRecord = _encryptRecord(record);
          await txn.insert('records', encryptedRecord);
        }
      });
      print('Backup imported successfully');
    } catch (e) {
      print('Error importing backup: $e');
      throw Exception('Failed to import backup: $e');
    }
  }

  @override
  Future<List<Record>> getRecordsModifiedSince(DateTime date) async {
    try {
      final db = await database;
      final records = await db.query(
        'records',
        where: 'modified_at > ?',
        whereArgs: [date.toIso8601String()],
        orderBy: 'modified_at DESC',
      );
      return records.map((record) => _decryptRecord(record)).toList();
    } catch (e) {
      print('Error getting records modified since date: $e');
      throw Exception('Failed to get modified records: $e');
    }
  }

  @override
  Future<bool> recordExists(String id) async {
    try {
      final db = await database;
      final result = await db.query(
        'records',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if record exists: $e');
      return false;
    }
  }

  @override
  Future<bool> categoryExists(String category) async {
    try {
      final db = await database;
      final result = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [category],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if category exists: $e');
      return false;
    }
  }

  @override
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('records');
        await txn.delete('categories');
        
        // Re-insert default categories
        for (final category in AppConstants.defaultCategories) {
          await txn.insert('categories', {
            'name': category,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      });
      print('All data cleared successfully');
    } catch (e) {
      print('Error clearing all data: $e');
      throw Exception('Failed to clear all data: $e');
    }
  }

  /// Encrypt record for storage
  Map<String, dynamic> _encryptRecord(Record record) {
    if (!_encryptionService.isInitialized) {
      throw Exception('Record encryption not initialized. Master password required.');
    }

    try {
      return {
        'id': record.id,
        'title': _encryptionService.encrypt(record.title),
        'type': record.type.toString().split('.').last,
        'fields': _encryptionService.encrypt(jsonEncode(record.fields)),
        'notes': record.notes != null
            ? _encryptionService.encrypt(record.notes!)
            : null,
        'category': record.category,
        'is_favorite': record.isFavorite ? 1 : 0,
        'created_at': record.createdAt.toIso8601String(),
        'modified_at': record.modifiedAt.toIso8601String(),
      };
    } catch (e) {
      print('Error encrypting record: $e');
      throw Exception('Failed to encrypt record: $e');
    }
  }

  /// Decrypt record from storage
  Record _decryptRecord(Map<String, dynamic> data) {
    if (!_encryptionService.isInitialized) {
      throw Exception('Record encryption not initialized. Master password required.');
    }

    try {
      return Record(
        id: data['id'] as String,
        title: _encryptionService.decrypt(data['title'] as String),
        type: RecordType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
        ),
        fields: Map<String, String>.from(
          jsonDecode(_encryptionService.decrypt(data['fields'] as String)),
        ),
        notes: data['notes'] != null
            ? _encryptionService.decrypt(data['notes'] as String)
            : null,
        category: data['category'] as String,
        isFavorite: data['is_favorite'] == 1,
        createdAt: DateTime.parse(data['created_at'] as String),
        modifiedAt: DateTime.parse(data['modified_at'] as String),
      );
    } catch (e) {
      print('Error decrypting record: $e');
      throw Exception('Failed to decrypt record: $e');
    }
  }
}