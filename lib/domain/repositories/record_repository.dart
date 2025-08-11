import '../models/record.dart';

abstract class RecordRepository {
  /// Get all records
  Future<List<Record>> getAllRecords();

  /// Get record by ID
  Future<Record?> getRecordById(String id);

  /// Get records by category
  Future<List<Record>> getRecordsByCategory(String category);

  /// Get favorite records
  Future<List<Record>> getFavoriteRecords();

  /// Search records by query
  Future<List<Record>> searchRecords(String query);

  /// Create a new record
  Future<Record> createRecord(Record record);

  /// Update an existing record
  Future<Record> updateRecord(Record record);

  /// Delete a record
  Future<void> deleteRecord(String id);

  /// Delete multiple records
  Future<void> deleteRecords(List<String> ids);

  /// Mark/unmark record as favorite
  Future<Record> toggleFavorite(String id);

  /// Move record to different category
  Future<Record> moveToCategory(String id, String category);

  /// Get all categories
  Future<List<String>> getAllCategories();

  /// Create a new category
  Future<void> createCategory(String category);

  /// Delete a category and optionally its records
  Future<void> deleteCategory(String category, {bool deleteRecords = false});

  /// Rename a category
  Future<void> renameCategory(String oldName, String newName);

  /// Export records to encrypted backup
  Future<String> exportToBackup(String password);

  /// Import records from encrypted backup
  Future<void> importFromBackup(String backupData, String password);

  /// Get record count
  Future<int> getRecordCount();

  /// Get category count
  Future<int> getCategoryCount();

  /// Get records modified since date
  Future<List<Record>> getRecordsModifiedSince(DateTime date);

  /// Check if record exists
  Future<bool> recordExists(String id);

  /// Check if category exists
  Future<bool> categoryExists(String category);

  /// Clear all data (dangerous operation)
  Future<void> clearAllData();
}