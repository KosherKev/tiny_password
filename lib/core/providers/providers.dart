import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../utils/crypto_utils.dart';
import '../../data/repositories/sqlite_record_repository.dart';
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
  return RepositoryStateNotifier();
});

class RepositoryStateNotifier extends StateNotifier<RepositoryState> {
  SQLiteRecordRepository? _repository;
  // final Ref _ref;

  RepositoryStateNotifier() : super(const RepositoryState(status: RepositoryStatus.uninitialized));

  Future<void> initialize() async {
    if (state.status == RepositoryStatus.initializing) {
      print('Repository initialization already in progress');
      return;
    }

    print('Starting repository initialization...');
    state = state.copyWith(
      status: RepositoryStatus.initializing,
      error: null,
    );

    try {
      // Dispose existing repository if any
      if (_repository != null) {
        await _repository!.dispose();
        _repository = null;
      }

      // Create new repository instance
      _repository = SQLiteRecordRepository();
      
      // Initialize the repository (database setup)
      await _repository!.initialize();
      print('Repository database initialized');

      state = state.copyWith(
        status: RepositoryStatus.initialized,
        repository: _repository,
        error: null,
      );
      
      print('Repository initialization completed successfully');
    } catch (e) {
      print('Repository initialization failed: $e');
      
      // Clean up on failure
      if (_repository != null) {
        try {
          await _repository!.dispose();
        } catch (e2) {
          print('Error disposing failed repository: $e2');
        }
        _repository = null;
      }
      
      state = state.copyWith(
        status: RepositoryStatus.error,
        error: e.toString(),
        repository: null,
      );
    }
  }

  Future<void> initializeRecordEncryption(String masterPassword) async {
    if (state.status != RepositoryStatus.initialized || _repository == null) {
      throw Exception('Repository must be initialized before setting up encryption');
    }

    try {
      print('Initializing record encryption...');
      await _repository!.initializeRecordEncryption(masterPassword);
      print('Record encryption initialized successfully');
    } catch (e) {
      print('Failed to initialize record encryption: $e');
      throw Exception('Failed to initialize record encryption: $e');
    }
  }

  void resetRecordEncryption() {
    if (_repository != null) {
      _repository!.resetRecordEncryption();
      print('Record encryption reset');
    }
  }

  Future<void> retry() async {
    if (state.status == RepositoryStatus.error) {
      print('Retrying repository initialization...');
      
      // Try to clean up any existing database file
      if (_repository != null) {
        try {
          final sqliteRepo = _repository!;
          await sqliteRepo.deleteDatabase();
          print('Existing database file deleted during retry');
        } catch (e) {
          print('Could not delete existing database file: $e');
        }
      }
      
      await initialize();
    }
  }

  Future<void> clearAllData() async {
    if (state.status != RepositoryStatus.initialized || _repository == null) {
      throw Exception('Repository not initialized');
    }

    try {
      await _repository!.clearAllData();
      print('All repository data cleared');
    } catch (e) {
      print('Error clearing repository data: $e');
      throw Exception('Failed to clear data: $e');
    }
  }

  @override
  void dispose() {
    if (_repository != null) {
      _repository!.dispose();
      _repository = null;
    }
    super.dispose();
  }
}

// Repository Access Provider
final repositoryProvider = Provider<SQLiteRecordRepository?>((ref) {
  final state = ref.watch(repositoryStateProvider);
  return state.status == RepositoryStatus.initialized ? state.repository : null;
});

// Add this new provider for safe access
final safeRepositoryProvider = Provider<SQLiteRecordRepository>((ref) {
  final repository = ref.watch(repositoryProvider);
  if (repository == null) {
    throw StateError('Repository not available. Please wait for initialization.');
  }
  return repository;
});

// Authentication State Providers
final hasMasterPasswordProvider = FutureProvider<bool>((ref) async {
  try {
    final authService = ref.watch(authServiceProvider);
    final result = await authService.isMasterPasswordSet();
    print('Master password check result: $result');
    return result;
  } catch (e) {
    print('Error checking master password: $e');
    return false;
  }
});

final isBiometricsEnabledProvider = FutureProvider<bool>((ref) async {
  try {
    final authService = ref.watch(authServiceProvider);
    return await authService.isBiometricsEnabled();
  } catch (e) {
    print('Error checking biometrics: $e');
    return false;
  }
});

final isBiometricsAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    final authService = ref.watch(authServiceProvider);
    return await authService.isBiometricsAvailable();
  } catch (e) {
    print('Error checking biometrics availability: $e');
    return false;
  }
});

// App State Providers
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

final autoLockDurationProvider = StateProvider<Duration>((ref) {
  return const Duration(minutes: 1); // Default auto-lock duration
});

// Record State Providers
final allRecordsProvider = FutureProvider<List<Record>>((ref) async {
  try {
    final repository = ref.watch(safeRepositoryProvider);
    return await repository.getAllRecords();
  } catch (e) {
    print('Error getting all records: $e');
    throw Exception('Failed to get records: $e');
  }
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Record>>((ref) async {
  try {
    final query = ref.watch(searchQueryProvider);
    if (query.isEmpty) return <Record>[];

    final repository = ref.watch(safeRepositoryProvider);
    return await repository.searchRecords(query);
  } catch (e) {
    print('Error searching records: $e');
    return <Record>[];
  }
});

final favoriteRecordsProvider = FutureProvider<List<Record>>((ref) async {
  try {
    final repository = ref.watch(safeRepositoryProvider);
    return await repository.getFavoriteRecords();
  } catch (e) {
    print('Error getting favorite records: $e');
    throw Exception('Failed to get favorite records: $e');
  }
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final repository = ref.watch(safeRepositoryProvider);
    return await repository.getAllCategories();
  } catch (e) {
    print('Error getting categories: $e');
    throw Exception('Failed to get categories: $e');
  }
});

final recordsByCategoryProvider = FutureProvider.family<List<Record>, String>(
  (ref, category) async {
    try {
      final repository = ref.watch(safeRepositoryProvider);
      return await repository.getRecordsByCategory(category);
    } catch (e) {
      print('Error getting records by category: $e');
      throw Exception('Failed to get records by category: $e');
    }
  },
);

// Selected Record Provider
final selectedRecordProvider = FutureProvider.family<Record?, String>((ref, recordId) async {
  try {
    final repository = ref.watch(safeRepositoryProvider);
    return await repository.getRecordById(recordId);
  } catch (e) {
    print('Error getting record by ID: $e');
    return null;
  }
});

// Theme Provider
final isDarkModeProvider = StateProvider<bool>((ref) => false);

// Statistics Providers
final recordCountProvider = FutureProvider<int>((ref) async {
  try {
    final repository = ref.watch(safeRepositoryProvider);
    return await repository.getRecordCount();
  } catch (e) {
    print('Error getting record count: $e');
    return 0;
  }
});

final categoryCountProvider = FutureProvider<int>((ref) async {
  try {
    final repository = ref.watch(safeRepositoryProvider);
    return await repository.getCategoryCount();
  } catch (e) {
    print('Error getting category count: $e');
    return 0;
  }
});

// UI State Providers
final selectedRecordsProvider = StateProvider<Set<String>>((ref) => {});

final currentCategoryProvider = StateProvider<String?>((ref) => null);

enum RecordSortOption { title, modifiedDate, createdDate, category }

final recordSortOptionProvider = StateProvider<RecordSortOption>(
  (ref) => RecordSortOption.modifiedDate,
);

final errorMessageProvider = StateProvider<String?>((ref) => null);

final isLoadingProvider = StateProvider<bool>((ref) => false);

final successMessageProvider = StateProvider<String?>((ref) => null);

// Auto-lock Timer State
final autoLockTimerProvider = StateProvider<DateTime?>((ref) => null);