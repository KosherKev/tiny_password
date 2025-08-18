import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/record.dart';

// Record Type View Screen
class RecordTypeViewScreen extends ConsumerStatefulWidget {
  final RecordType recordType;

  const RecordTypeViewScreen({required this.recordType, super.key});

  @override
  ConsumerState<RecordTypeViewScreen> createState() => _RecordTypeViewScreenState();
}

class _RecordTypeViewScreenState extends ConsumerState<RecordTypeViewScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allRecords = ref.watch(allRecordsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final typeColor = AppTheme.getRecordTypeColor(widget.recordType.name, isDarkMode);
    final typeInfo = AppConstants.recordTypes[widget.recordType.name];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(typeInfo?.name ?? widget.recordType.displayName),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add record with the current record type as default
              ref.read(navigationServiceProvider).navigateToAddRecord(widget.recordType);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSearchBar(context),
          ),
          
          // Records List
          Expanded(
            child: allRecords.when(
              data: (records) {
                final filteredRecords = records
                    .where((record) => record.type == widget.recordType)
                    .toList();

                if (filteredRecords.isEmpty) {
                  return _buildEmptyState(context, typeInfo?.name ?? widget.recordType.displayName);
                }

                // Group by categories
                final recordsByCategory = <String, List<Record>>{};
                for (final record in filteredRecords) {
                  final category = record.category ?? 'Other';
                  recordsByCategory.putIfAbsent(category, () => []).add(record);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recordsByCategory.length,
                  itemBuilder: (context, index) {
                    final category = recordsByCategory.keys.elementAt(index);
                    final categoryRecords = recordsByCategory[category]!;
                    
                    return _buildCategorySection(
                      context,
                      category,
                      categoryRecords,
                      typeColor,
                      index,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search records...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<Record> records,
    Color typeColor,
    int sectionIndex,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationDelay = (sectionIndex * 0.1).clamp(0.0, 1.0);
        final animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            animationDelay,
            (animationDelay + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ));

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          category,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${records.length}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Records List
                  ...records.asMap().entries.map((entry) {
                    final recordIndex = entry.key;
                    final record = entry.value;
                    return _buildRecordCard(context, record, typeColor, recordIndex);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordCard(BuildContext context, Record record, Color typeColor, int index) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _toggleFavorite(record.id),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            foregroundColor: Theme.of(context).colorScheme.onTertiary,
            icon: record.isFavorite ? Icons.star : Icons.star_border,
            label: record.isFavorite ? 'Unfavorite' : 'Favorite',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) => _deleteRecord(record.id),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(navigationServiceProvider).navigateToRecordDetails(record.id);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForRecordType(record.type),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                record.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (record.isFavorite)
                              Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (record.primaryFieldValue != null)
                          Text(
                            record.primaryFieldValue!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String typeName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForRecordType(widget.recordType),
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No $typeName records yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first ${typeName.toLowerCase()} record',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForRecordType(RecordType type) {
    switch (type) {
      case RecordType.login:
        return Icons.key;
      case RecordType.creditCard:
        return Icons.credit_card;
      case RecordType.bankAccount:
        return Icons.account_balance;
      case RecordType.note:
        return Icons.note;
      case RecordType.address:
        return Icons.location_on;
      case RecordType.identity:
        return Icons.badge;
      case RecordType.wifi:
        return Icons.wifi;
      case RecordType.software:
        return Icons.memory;
      case RecordType.server:
        return Icons.dns;
      case RecordType.document:
        return Icons.description;
      case RecordType.membership:
        return Icons.card_membership;
      case RecordType.vehicle:
        return Icons.directions_car;
    }
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      final repository = ref.read(safeRepositoryProvider);
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

  Future<void> _deleteRecord(String id) async {
    try {
      final repository = ref.read(safeRepositoryProvider);
      await repository.deleteRecord(id);
      ref.invalidate(allRecordsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Record deleted'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
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
}