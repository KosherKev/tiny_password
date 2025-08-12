import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/record.dart';
import '../../data/repositories/sqlite_record_repository.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';

// Authentication State
final authServiceProvider = Provider((ref) => AuthService());

final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isBiometricsAvailable();
});

final isBiometricEnabledProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isBiometricsEnabled();
});

// Record Repository Provider
// Records State
final allRecordsProvider = FutureProvider<List<Record>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  return await repository.getAllRecords();
});

final favoriteRecordsProvider = FutureProvider<List<Record>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  return await repository.getFavoriteRecords();
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(repositoryProvider);
  return await repository.getAllCategories();
});

final recordsByCategoryProvider = FutureProvider.family<List<Record>, String>(
  (ref, category) async {
    final repository = ref.watch(repositoryProvider);
    return await repository.getRecordsByCategory(category);
  },
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Record>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final repository = ref.watch(repositoryProvider);
  return await repository.searchRecords(query);
});

// Theme State
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// Auto-lock Timer State
final autoLockTimerProvider = StateProvider<DateTime?>((ref) => null);

// Selected Records for Bulk Operations
final selectedRecordsProvider = StateProvider<Set<String>>((ref) => {});

// Current Category
final currentCategoryProvider = StateProvider<String?>((ref) => null);

// Record Sort Options
enum RecordSortOption { title, modifiedDate, createdDate, category }

final recordSortOptionProvider = StateProvider<RecordSortOption>(
  (ref) => RecordSortOption.modifiedDate,
);

// Error State
final errorMessageProvider = StateProvider<String?>((ref) => null);

// Loading State
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Success Message State
final successMessageProvider = StateProvider<String?>((ref) => null);

// Record Count
final recordCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(repositoryProvider);
  return await repository.getRecordCount();
});

// Category Count
final categoryCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(repositoryProvider);
  return await repository.getCategoryCount();
});