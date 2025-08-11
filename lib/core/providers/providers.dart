import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../utils/crypto_utils.dart';
import '../repositories/sqlite_record_repository.dart';
import '../../domain/models/record.dart' show Record;

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final navigationServiceProvider = Provider<NavigationService>((ref) => NavigationService());

final cryptoUtilsProvider = Provider<CryptoUtils>((ref) => CryptoUtils());

// Repository Providers
final recordRepositoryProvider = Provider<SQLiteRecordRepository>((ref) {
  final cryptoUtils = ref.watch(cryptoUtilsProvider);
  return SQLiteRecordRepository(cryptoUtils);
});

// State Providers
final hasMasterPasswordProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.isMasterPasswordSet();
});

final isBiometricsEnabledProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.isBiometricsEnabled();
});

final autoLockDurationProvider = StateProvider<Duration>((ref) {
  return const Duration(minutes: 1); // Default auto-lock duration
});

// Record State Providers
final allRecordsProvider = FutureProvider<List<Record>>((ref) async {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getAllRecords();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Record>>((ref) async {
  final records = await ref.watch(allRecordsProvider.future);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) return records;

  return records.where((record) {
    final searchTerm = query.toLowerCase();
    return record.title.toLowerCase().contains(searchTerm) ||
           record.notes?.toLowerCase().contains(searchTerm) == true;
  }).toList();
});

final favoriteRecordsProvider = FutureProvider<List<Record>>((ref) async {
  final records = await ref.watch(allRecordsProvider.future);
  return records.where((record) => record.isFavorite).toList();
});

// Selected Record Provider
final selectedRecordProvider = FutureProvider.family<Record?, String>((ref, recordId) async {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getRecordById(recordId);
});

// Theme Provider
final isDarkModeProvider = StateProvider<bool>((ref) => false);