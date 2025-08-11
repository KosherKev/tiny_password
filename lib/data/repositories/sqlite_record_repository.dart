import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/encryption/encryption_service.dart';
import '../../domain/models/record.dart';
import '../../domain/repositories/record_repository.dart';

class SQLiteRecordRepository implements RecordRepository {
  static final SQLiteRecordRepository _instance = SQLiteRecordRepository._internal();
  factory SQLiteRecordRepository() => _instance;
  SQLiteRecordRepository._internal();

  Database? _database;
  final EncryptionService _encryptionService = EncryptionService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      password: 'your_database_password', // This should be securely stored and retrieved
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
    final encryptedRecord = _encryptRecord(record);
    await db.update(
      'records',
      encryptedRecord,
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return record;
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
    final db = await database;
    final record = await getRecordById(id);
    if (record == null) throw Exception('Record not found');

    final updatedRecord = record.copyWith(isFavorite: !record.isFavorite);
    await updateRecord(updatedRecord);
    return updatedRecord;
  }

  @override
  Future<Record> moveToCategory(String id, String category) async {
    final db = await database;
    final record = await getRecordById(id);
    if (record == null) throw Exception('Record not found');

    final updatedRecord = record.copyWith(category: category);
    await updateRecord(updatedRecord);
    return updatedRecord;
  }

  @override
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final categories = await db.query('categories', orderBy: 'name');
    return categories.map((category) => category['name'] as String).toList();
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
      // Move records to 'Uncategorized' category
      batch.update(
        'records',
        {'category': 'Uncategorized'},
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