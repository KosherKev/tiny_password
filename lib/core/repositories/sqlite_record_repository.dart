import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<Database> get database async {
    if (!_isInitialized) throw Exception('Repository not initialized');
    if (_database == null) throw Exception('Database not initialized');
    return _database!;
  }

  @override
  Future<void> dispose() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _isInitialized = false;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      String? dbPassword = await _secureStorage.getDatabasePassword();
      if (dbPassword == null) {
        // Generate a secure random password for the database
        dbPassword = _encryptionService.generatePassword(
          length: 32,
          useUppercase: true,
          useLowercase: true,
          useNumbers: true,
          useSpecial: true,
          excludeSimilar: true,
        );
        await _secureStorage.storeDatabasePassword(dbPassword);
      }

      // Initialize encryption service with database password
      await _encryptionService.initialize(dbPassword);

      // Initialize database with recovery
      _database = await _initDatabaseWithRecovery(dbPassword);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      throw Exception('Failed to initialize repository: $e');
    }
  }

  Future<String> _getDatabasePath() async {
    try {
      // Try to get the application documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return join(documentsDirectory.path, AppConstants.dbName);
    } catch (e) {
      // Fallback for platforms where path_provider doesn't work
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Use current directory as fallback
        final currentDir = Directory.current.path;
        return join(currentDir, 'data', AppConstants.dbName);
      } else {
        // For web or other platforms, use in-memory database
        return ':memory:';
      }
    }
  }

  Future<Database> _initDatabaseWithRecovery(String dbPassword) async {
    final path = await _getDatabasePath();

    // Create directory if it doesn't exist (for fallback path)
    if (path != ':memory:') {
      final directory = Directory(dirname(path));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    // Try to open the database
    try {
      return await _openDatabase(path, dbPassword);
    } catch (e) {
      print('Database open failed: $e');
      
      // If opening failed and it's not in-memory, try to recover
      if (path != ':memory:') {
        await _recoverDatabase(path);
        // Try again with the same password
        return await _openDatabase(path, dbPassword);
      } else {
        rethrow;
      }
    }
  }

  Future<Database> _openDatabase(String path, String dbPassword) async {
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        // Test the database is working by running a simple query
        await db.rawQuery('SELECT 1');
      },
      password: dbPassword,
    );
  }

  Future<void> _recoverDatabase(String path) async {
    try {
      print('Attempting database recovery...');
      
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
      
      // Clear the stored database password so a new one will be generated
      await _secureStorage.deleteAll();
      print('Cleared stored credentials for fresh start');
      
    } catch (e) {
      print('Database recovery failed: $e');
      // Continue anyway - the database creation will start fresh
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating new database...');
    
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

    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        name TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_records_category ON records(category)');
    await db.execute('CREATE INDEX idx_records_type ON records(type)');
    await db.execute('CREATE INDEX idx_records_is_favorite ON records(is_favorite)');

    // Insert default categories
    final batch = db.batch();
    for (final category in AppConstants.defaultCategories) {
      batch.insert('categories', {
        'name': category,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit();
    
    print('Database created successfully');
  }

  @override
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final categories = await db.query('categories', columns: ['name']);
    return categories.map((category) => category['name'] as String).toList();
  }

  @override
  Future<int> getRecordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> getCategoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<Record>> getAllRecords() async {
    final db = await database;
    final records = await db.query('records', orderBy: 'modified_at DESC');
    return records.map((record) => _decryptRecord(record)).toList();
  }

  @override
  Future<Record?> getRecordById(String id) async {
    final db = await database;
    final records = await db.query('records', where: 'id = ?', whereArgs: [id]);
    if (records.isEmpty) return null;
    return _decryptRecord(records.first);
  }

  @override
  Future<List<Record>> getRecordsByCategory(String category) async {
    final db = await database;
    final records = await db.query(
      'records',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'modified_at DESC',
    );
    return records.map((record) => _decryptRecord(record)).toList();
  }

  @override
  Future<List<Record>> getFavoriteRecords() async {
    final db = await database;
    final records = await db.query(
      'records',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'modified_at DESC',
    );
    return records.map((record) => _decryptRecord(record)).toList();
  }

  @override
  Future<List<Record>> searchRecords(String query) async {
    final db = await database;
    final records = await db.query(
      'records',
      where: 'title LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'modified_at DESC',
    );
    return records.map((record) => _decryptRecord(record)).toList();
  }

  @override
  Future<Record> createRecord(Record record) async {
    final db = await database;
    final encryptedRecord = _encryptRecord(record);
    await db.insert('records', encryptedRecord);
    return record;
  }

  @override
  Future<Record> updateRecord(Record record) async {
    final db = await database;
    final updatedRecord = record.copyWith(modifiedAt: DateTime.now());
    final encryptedRecord = _encryptRecord(updatedRecord);
    await db.update(
      'records',
      encryptedRecord,
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return updatedRecord;
  }

  @override
  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteRecords(List<String> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete('records', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit();
  }

  @override
  Future<Record> toggleFavorite(String id) async {
    final record = await getRecordById(id);
    if (record == null) throw Exception('Record not found');

    final updatedRecord = record.copyWith(
      isFavorite: !record.isFavorite,
      modifiedAt: DateTime.now(),
    );
    await updateRecord(updatedRecord);
    return updatedRecord;
  }

  @override
  Future<Record> moveToCategory(String id, String category) async {
    final record = await getRecordById(id);
    if (record == null) throw Exception('Record not found');

    final updatedRecord = record.copyWith(
      category: category,
      modifiedAt: DateTime.now(),
    );
    await updateRecord(updatedRecord);
    return updatedRecord;
  }

  @override
  Future<void> createCategory(String category) async {
    final db = await database;
    await db.insert('categories', {
      'name': category,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteCategory(String category, {bool deleteRecords = false}) async {
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
  }

  @override
  Future<void> renameCategory(String oldName, String newName) async {
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
  }

  @override
  Future<String> exportToBackup(String password) async {
    final records = await getAllRecords();
    final categories = await getAllCategories();

    final backupData = {
      'records': records.map((r) => r.toJson()).toList(),
      'categories': categories,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final jsonData = jsonEncode(backupData);
    return _encryptionService.encrypt(jsonData);
  }

  @override
  Future<void> importFromBackup(String backupData, String password) async {
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
  }

  @override
  Future<List<Record>> getRecordsModifiedSince(DateTime date) async {
    final db = await database;
    final records = await db.query(
      'records',
      where: 'modified_at > ?',
      whereArgs: [date.toIso8601String()],
      orderBy: 'modified_at DESC',
    );
    return records.map((record) => _decryptRecord(record)).toList();
  }

  @override
  Future<bool> recordExists(String id) async {
    final db = await database;
    final result = await db.query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  @override
  Future<bool> categoryExists(String category) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [category],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  @override
  Future<void> clearAllData() async {
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
  }

  Map<String, dynamic> _encryptRecord(Record record) {
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
  }

  Record _decryptRecord(Map<String, dynamic> data) {
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
  }
}