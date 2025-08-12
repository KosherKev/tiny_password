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

// Repository State
enum RepositoryStatus { uninitialized, initializing, initialized, error }

class RepositoryState {
  final RepositoryStatus status;
  final String? error;
  final SQLiteRecordRepository? repository;

  const RepositoryState({
    required this.status,
    this.error,
    this.repository,
  });

  RepositoryState copyWith({
    RepositoryStatus? status,
    String? error,
    SQLiteRecordRepository? repository,
  }) {
    return RepositoryState(
      status: status ?? this.status,
      error: error ?? this.error,
      repository: repository ?? this.repository,
    );
  }
}

// Repository Providers
final repositoryStateProvider = StateNotifierProvider<RepositoryStateNotifier, RepositoryState>((ref) {
  return RepositoryStateNotifier(ref);
});

class RepositoryStateNotifier extends StateNotifier<RepositoryState> {
  final Ref _ref;
  SQLiteRecordRepository? _repository;

  RepositoryStateNotifier(this._ref) : super(const RepositoryState(status: RepositoryStatus.uninitialized));

  Future<void> initialize() async {
    if (state.status == RepositoryStatus.initializing) return;

    state = state.copyWith(
      status: RepositoryStatus.initializing,
      error: null,
    );

    try {
      _repository?.dispose();
      final cryptoUtils = _ref.read(cryptoUtilsProvider);
      _repository = SQLiteRecordRepository(cryptoUtils);
      await _repository!.initialize();

      state = state.copyWith(
        status: RepositoryStatus.initialized,
        repository: _repository,
        error: null,
      );
    } catch (e) {
      _repository?.dispose();
      _repository = null;
      state = state.copyWith(
        status: RepositoryStatus.error,
        error: e.toString(),
        repository: null,
      );
    }
  }

  Future<void> retry() async {
    if (state.status == RepositoryStatus.error) {
      await initialize();
    }
  }

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
    super.dispose();
  }
}

// Repository Access Provider
final repositoryProvider = Provider<SQLiteRecordRepository>((ref) {
  final state = ref.watch(repositoryStateProvider);
  if (state.status != RepositoryStatus.initialized || state.repository == null) {
    throw Exception('Repository not initialized');
  }
  return state.repository!;
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
  final repository = ref.watch(repositoryProvider);
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
  final repository = ref.watch(repositoryProvider);
  return repository.getRecordById(recordId);
});

// Theme Provider
final isDarkModeProvider = StateProvider<bool>((ref) => false);