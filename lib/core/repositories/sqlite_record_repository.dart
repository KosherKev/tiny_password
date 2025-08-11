import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../domain/models/record.dart';
import '../utils/crypto_utils.dart';

class SQLiteRecordRepository {
  static const String _dbName = 'tiny_password.db';
  static const int _dbVersion = 1;

  late final Database _db;
  final CryptoUtils _cryptoUtils;

  SQLiteRecordRepository(this._cryptoUtils);

  Future<void> initialize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      password: await _cryptoUtils.hashPassword('db_password'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        fields TEXT NOT NULL,
        notes TEXT,
        category TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        modified_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_type ON records (type)');
    await db.execute('CREATE INDEX idx_category ON records (category)');
  }

  Future<List<Record>> getAllRecords() async {
    final records = await _db.query('records');
    return records.map((record) {
      final decryptedFields = _decryptFields(record['fields'] as String);
      return Record.fromJson({
        ...record,
        'fields': decryptedFields,
        'isFavorite': record['is_favorite'] == 1,
      });
    }).toList();
  }

  Future<Record?> getRecordById(String id) async {
    final records = await _db.query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (records.isEmpty) return null;

    final record = records.first;
    final decryptedFields = _decryptFields(record['fields'] as String);
    return Record.fromJson({
      ...record,
      'fields': decryptedFields,
      'isFavorite': record['is_favorite'] == 1,
    });
  }

  Future<void> createRecord(Record record) async {
    final encryptedFields = _encryptFields(record.fields);
    await _db.insert(
      'records',
      {
        'id': record.id,
        'title': record.title,
        'type': record.type.toString(),
        'fields': encryptedFields,
        'notes': record.notes,
        'category': record.category,
        'is_favorite': record.isFavorite ? 1 : 0,
        'created_at': record.createdAt.toIso8601String(),
        'modified_at': record.modifiedAt.toIso8601String(),
      },
    );
  }

  Future<void> updateRecord(Record record) async {
    final encryptedFields = _encryptFields(record.fields);
    await _db.update(
      'records',
      {
        'title': record.title,
        'type': record.type.toString(),
        'fields': encryptedFields,
        'notes': record.notes,
        'category': record.category,
        'is_favorite': record.isFavorite ? 1 : 0,
        'modified_at': record.modifiedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> toggleFavorite(String id) async {
    final record = await getRecordById(id);
    if (record != null) {
      await updateFavorite(id, !record.isFavorite);
    }
  }

  Future<void> deleteRecord(String id) async {
    await _db.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFavorite(String id, bool isFavorite) async {
    await _db.update(
      'records',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Record>> searchRecords(String query) async {
    final records = await _db.query(
      'records',
      where: 'title LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return records.map((record) {
      final decryptedFields = _decryptFields(record['fields'] as String);
      return Record.fromJson({
        ...record,
        'fields': decryptedFields,
        'isFavorite': record['is_favorite'] == 1,
      });
    }).toList();
  }

  Future<String> exportData() async {
    final records = await getAllRecords();
    final exportData = {
      'version': _dbVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'records': records.map((r) => r.toJson()).toList(),
    };
    return jsonEncode(exportData);
  }

  Future<void> importData(String jsonData) async {
    final data = jsonDecode(jsonData) as Map<String, dynamic>;
    final version = data['version'] as int;
    
    if (version > _dbVersion) {
      throw Exception('Cannot import data from a newer version');
    }

    final recordsList = (data['records'] as List).cast<Map<String, dynamic>>();
    await _db.transaction((txn) async {
      await txn.delete('records');
      for (final recordData in recordsList) {
        final record = Record.fromJson(recordData);
        final encryptedFields = _encryptFields(record.fields);
        await txn.insert(
          'records',
          {
            'id': record.id,
            'title': record.title,
            'type': record.type.toString(),
            'fields': encryptedFields,
            'notes': record.notes,
            'category': record.category,
            'is_favorite': record.isFavorite ? 1 : 0,
            'created_at': record.createdAt.toIso8601String(),
            'modified_at': record.modifiedAt.toIso8601String(),
          },
        );
      }
    });
  }

  String _encryptFields(Map<String, String> fields) {
    final jsonStr = jsonEncode(fields);
    return _cryptoUtils.encrypt(jsonStr);
  }

  Map<String, String> _decryptFields(String encrypted) {
    final jsonStr = _cryptoUtils.decrypt(encrypted);
    return Map<String, String>.from(jsonDecode(jsonStr));
  }

  Future<void> close() async {
    await _db.close();
  }
}