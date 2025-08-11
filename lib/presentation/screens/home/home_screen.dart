import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/models/record.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  Future<void> _deleteRecord(String id) async {
    try {
      final repository = ref.read(recordRepositoryProvider);
      await repository.deleteRecord(id);
      ref.invalidate(allRecordsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      final repository = ref.read(recordRepositoryProvider);
      await repository.toggleFavorite(id);
      ref.invalidate(allRecordsProvider);
      ref.invalidate(favoriteRecordsProvider);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(allRecordsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ref.read(navigationServiceProvider).navigateToSettings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search records...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearch,
            ),
          ),
          // Records List
          Expanded(
            child: records.when(
              data: (data) {
                final displayRecords =
                    searchQuery.isEmpty ? data : searchResults.value ?? [];

                if (displayRecords.isEmpty) {
                  return Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'No records yet'
                          : 'No matching records',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: displayRecords.length,
                  itemBuilder: (context, index) {
                    final record = displayRecords[index];
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _toggleFavorite(record.id),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            icon: record.isFavorite
                                ? Icons.star
                                : Icons.star_border,
                            label: record.isFavorite
                                ? 'Unfavorite'
                                : 'Favorite',
                          ),
                          SlidableAction(
                            onPressed: (_) => _deleteRecord(record.id),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                            icon: Icons.delete_outline,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          _getIconForRecordType(record.type),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(record.title),
                        subtitle: Text(record.category ?? ''),
                        trailing: record.isFavorite
                            ? Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
            ref.read(navigationServiceProvider).navigateToRecordDetails(record.id);
          },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error: ${error.toString()}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            ref.read(navigationServiceProvider).navigateToAddRecord();
          },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForRecordType(RecordType type) {
    switch (type) {
      case RecordType.login:
        return Icons.password_outlined;
      case RecordType.creditCard:
        return Icons.credit_card_outlined;
      case RecordType.bankAccount:
        return Icons.account_balance_outlined;
      case RecordType.note:
        return Icons.note_outlined;
    }
  }
}