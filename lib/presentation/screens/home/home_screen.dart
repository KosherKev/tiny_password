import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/record.dart';
import 'category_view_screen.dart';
import 'record_type_view_screen.dart';

// View Mode Provider
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.recordTypes);

enum ViewMode { recordTypes, categories }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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

  void _onSearch(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final viewMode = ref.watch(viewModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final allRecords = ref.watch(allRecordsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Bauhaus styling
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Row(
                children: [
                  // Bauhaus-inspired logo
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {
                  ref.read(navigationServiceProvider).navigateToSettings();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildSearchBar(context),
            ),
          ),

          // View Mode Toggle
          if (searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildViewModeToggle(context, viewMode),
              ),
            ),

          // Stats Cards
          if (searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _buildStatsCards(context, allRecords),
              ),
            ),

          // Main Content
          if (searchQuery.isNotEmpty)
            _buildSearchResults()
          else if (viewMode == ViewMode.recordTypes)
            _buildRecordTypesGrid(context, allRecords)
          else
            _buildCategoriesGrid(context, allRecords),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
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
          hintText: 'Search your vault...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: _onSearch,
      ),
    );
  }

  Widget _buildViewModeToggle(BuildContext context, ViewMode currentMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              context,
              'Record Types',
              Icons.category,
              currentMode == ViewMode.recordTypes,
              () => ref.read(viewModeProvider.notifier).state = ViewMode.recordTypes,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              context,
              'Categories',
              Icons.folder,
              currentMode == ViewMode.categories,
              () => ref.read(viewModeProvider.notifier).state = ViewMode.categories,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String text,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, AsyncValue<List<Record>> records) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Items',
            records.value?.length.toString() ?? '0',
            Icons.inventory_2,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'Favorites',
            records.value?.where((r) => r.isFavorite).length.toString() ?? '0',
            Icons.star,
            Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchResults = ref.watch(searchResultsProvider);
    
    return searchResults.when(
      data: (records) {
        if (records.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              context,
              'No matching records',
              'Try a different search term',
              Icons.search_off,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final record = records[index];
                return _buildRecordListItem(context, record, index);
              },
              childCount: records.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildEmptyState(
          context,
          'Search Error',
          error.toString(),
          Icons.error_outline,
        ),
      ),
    );
  }

  Widget _buildRecordTypesGrid(BuildContext context, AsyncValue<List<Record>> allRecords) {
    return allRecords.when(
      data: (records) {
        if (records.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              context,
              'No records yet',
              'Tap + to add your first password',
              Icons.lock_outline,
            ),
          );
        }

        // Group records by type
        final recordsByType = <RecordType, List<Record>>{};
        for (final record in records) {
          recordsByType.putIfAbsent(record.type, () => []).add(record);
        }

        return SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppConstants.gridCrossAxisCount,
              childAspectRatio: AppConstants.gridChildAspectRatio,
              crossAxisSpacing: AppConstants.gridSpacing,
              mainAxisSpacing: AppConstants.gridSpacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recordType = RecordType.values[index];
                final count = recordsByType[recordType]?.length ?? 0;
                final typeInfo = AppConstants.recordTypes[recordType.name];
                
                return _buildGridCard(
                  context,
                  typeInfo?.name ?? recordType.name,
                  count.toString(),
                  _getIconForRecordType(recordType),
                  AppTheme.getRecordTypeColor(recordType.name, Theme.of(context).brightness == Brightness.dark),
                  () => _navigateToRecordTypeView(recordType),
                  index,
                );
              },
              childCount: RecordType.values.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildEmptyState(
          context,
          'Error loading records',
          error.toString(),
          Icons.error_outline,
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, AsyncValue<List<Record>> allRecords) {
    return allRecords.when(
      data: (records) {
        if (records.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
              context,
              'No records yet',
              'Tap + to add your first password',
              Icons.lock_outline,
            ),
          );
        }

        // Group records by category
        final recordsByCategory = <String, List<Record>>{};
        for (final record in records) {
          final category = record.category ?? 'Other';
          recordsByCategory.putIfAbsent(category, () => []).add(record);
        }

        final categories = AppConstants.defaultCategories.where((category) {
          return recordsByCategory.containsKey(category) && recordsByCategory[category]!.isNotEmpty;
        }).toList();

        return SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppConstants.gridCrossAxisCount,
              childAspectRatio: AppConstants.gridChildAspectRatio,
              crossAxisSpacing: AppConstants.gridSpacing,
              mainAxisSpacing: AppConstants.gridSpacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];
                final count = recordsByCategory[category]?.length ?? 0;
                
                return _buildGridCard(
                  context,
                  category,
                  count.toString(),
                  _getIconForCategory(category),
                  _getColorForCategory(category, Theme.of(context).brightness == Brightness.dark),
                  () => _navigateToCategoryView(category),
                  index,
                );
              },
              childCount: categories.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: _buildEmptyState(
          context,
          'Error loading records',
          error.toString(),
          Icons.error_outline,
        ),
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationDelay = (index * 0.1).clamp(0.0, 1.0);
        final animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            animationDelay,
            (animationDelay + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ));

        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: _buildCardContent(context, title, count, icon, color, onTap),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16), // Reduced from 20 to 16
                child: Row(
                  children: [
                    Container(
                      width: 44, // Reduced from 48 to 44
                      height: 44, // Reduced from 48 to 44
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 22, // Reduced from 24 to 22
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded( // Use Expanded to prevent overflow
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Minimize space usage
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Reduced from 4 to 2
                      Text(
                        '$count items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordListItem(BuildContext context, Record record, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationDelay = (index * 0.05).clamp(0.0, 1.0);
        final animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            animationDelay,
            (animationDelay + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ));

        return Transform.translate(
          offset: Offset(30 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                            color: AppTheme.getRecordTypeColor(
                              record.type.name, 
                              Theme.of(context).brightness == Brightness.dark,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getIconForRecordType(record.type),
                            color: AppTheme.getRecordTypeColor(
                              record.type.name, 
                              Theme.of(context).brightness == Brightness.dark,
                            ),
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
                              Text(
                                record.primaryFieldValue ?? record.category ?? 'No Category',
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
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(navigationServiceProvider).navigateToAddRecord();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
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

  IconData _getIconForCategory(String category) {
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

  Color _getColorForCategory(String category, bool isDarkMode) {
    switch (category.toLowerCase()) {
      case 'personal':
        return isDarkMode ? const Color(0xFF60A5FA) : AppTheme.bauhausBlue;
      case 'work':
        return isDarkMode ? const Color(0xFF34D399) : AppTheme.modernGreen;
      case 'finance':
        return isDarkMode ? const Color(0xFFFBBF24) : AppTheme.bauhausYellow;
      case 'shopping':
        return isDarkMode ? const Color(0xFFF87171) : AppTheme.bauhausRed;
      case 'social':
        return isDarkMode ? const Color(0xFFA78BFA) : AppTheme.modernPurple;
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
        return isDarkMode ? const Color(0xFFFF8A65) : AppTheme.modernOrange;
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

  void _navigateToRecordTypeView(RecordType recordType) {
    // Navigate to a filtered view showing only records of this type
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordTypeViewScreen(recordType: recordType),
      ),
    );
  }

  void _navigateToCategoryView(String category) {
    // Navigate to a filtered view showing only records in this category
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryViewScreen(category: category),
      ),
    );
  }
}