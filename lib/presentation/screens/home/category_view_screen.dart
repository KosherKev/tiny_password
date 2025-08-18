import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/record.dart';


// Category View Screen
class CategoryViewScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryViewScreen({required this.category, super.key});

  @override
  ConsumerState<CategoryViewScreen> createState() => _CategoryViewScreenState();
}

class _CategoryViewScreenState extends ConsumerState<CategoryViewScreen>
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
    final categoryColor = _getCategoryColor(widget.category, isDarkMode);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('${widget.category} Records'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Get the most common record type in this category as default
              final allRecordsAsync = ref.read(allRecordsProvider);
              RecordType? defaultType;
              
              allRecordsAsync.whenData((records) {
                final filteredRecords = records
                    .where((record) => record.category == widget.category)
                    .toList();
                
                if (filteredRecords.isNotEmpty) {
                  // Find the most common record type in this category
                  final typeCount = <RecordType, int>{};
                  for (final record in filteredRecords) {
                    typeCount[record.type] = (typeCount[record.type] ?? 0) + 1;
                  }
                  
                  // Get the type with the highest count
                  defaultType = typeCount.entries
                      .reduce((a, b) => a.value > b.value ? a : b)
                      .key;
                }
              });
              
              // Navigate to add record with pre-selected type
              ref.read(navigationServiceProvider).navigateToAddRecord(defaultType);
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
                    .where((record) => record.category == widget.category)
                    .toList();

                if (filteredRecords.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Group by record types
                final recordsByType = <RecordType, List<Record>>{};
                for (final record in filteredRecords) {
                  recordsByType.putIfAbsent(record.type, () => []).add(record);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recordsByType.length,
                  itemBuilder: (context, index) {
                    final recordType = recordsByType.keys.elementAt(index);
                    final typeRecords = recordsByType[recordType]!;
                    final typeInfo = AppConstants.recordTypes[recordType.name];
                    
                    return _buildTypeSection(
                      context,
                      recordType,
                      typeInfo?.name ?? recordType.displayName,
                      typeRecords,
                      categoryColor,
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

  Widget _buildTypeSection(
    BuildContext context,
    RecordType recordType,
    String typeName,
    List<Record> records,
    Color categoryColor,
    int sectionIndex,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final typeColor = AppTheme.getRecordTypeColor(recordType.name, isDarkMode);

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
                  // Type Header
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
                        Icon(
                          _getIconForRecordType(recordType),
                          color: typeColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          typeName,
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

  Widget _buildEmptyState(BuildContext context) {
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
                _getCategoryIcon(widget.category),
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${widget.category} records yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first ${widget.category.toLowerCase()} record',
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'finance':
        return Icons.account_balance_wallet;
      case 'shopping':
        return Icons.shopping_bag;
      case 'social':
        return Icons.group;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      case 'gaming':
        return Icons.sports_esports;
      case 'health':
        return Icons.local_hospital;
      case 'utilities':
        return Icons.build;
      case 'entertainment':
        return Icons.movie;
      case 'business':
        return Icons.business;
      case 'sports':
        return Icons.sports_soccer;
      case 'news':
        return Icons.newspaper;
      case 'streaming':
        return Icons.play_circle;
      default:
        return Icons.folder;
    }
  }

  Color _getCategoryColor(String category, bool isDarkMode) {
    switch (category.toLowerCase()) {
      case 'personal':
        return isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
      case 'work':
        return isDarkMode ? const Color(0xFF34D399) : const Color(0xFF10B981);
      case 'finance':
        return isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFFD69E2E);
      case 'shopping':
        return isDarkMode ? const Color(0xFFF87171) : const Color(0xFFE53E3E);
      case 'social':
        return isDarkMode ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
      case 'education':
        return isDarkMode ? const Color(0xFF4ADE80) : const Color(0xFF059669);
      case 'travel':
        return isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      case 'gaming':
        return isDarkMode ? const Color(0xFFE879F9) : const Color(0xFFBE185D);
      case 'health':
        return isDarkMode ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
      case 'utilities':
        return isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
      case 'entertainment':
        return isDarkMode ? const Color(0xFFFF8A65) : const Color(0xFFEA580C);
      case 'business':
        return isDarkMode ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
      case 'sports':
        return isDarkMode ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
      case 'news':
        return isDarkMode ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
      case 'streaming':
        return isDarkMode ? const Color(0xFFE11D48) : const Color(0xFF9F1239);
      default:
        return isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
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