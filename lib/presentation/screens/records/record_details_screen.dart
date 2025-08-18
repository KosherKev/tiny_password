import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/record.dart';
import '../../widgets/custom_text_field.dart';

class RecordDetailsScreen extends ConsumerStatefulWidget {
  final String recordId;
  final bool isEditing;

  const RecordDetailsScreen({
    required this.recordId,
    this.isEditing = false,
    super.key,
  });

  @override
  ConsumerState<RecordDetailsScreen> createState() => _RecordDetailsScreenState();
}

class _RecordDetailsScreenState extends ConsumerState<RecordDetailsScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final Map<String, TextEditingController> _fieldControllers;
  bool _isEditing = false;
  bool _showSensitiveFields = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditing;
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _fieldControllers = {};
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(Record record) {
    _titleController.text = record.title;
    _notesController.text = record.notes ?? '';
    
    for (final entry in record.fields.entries) {
      _fieldControllers.putIfAbsent(
        entry.key,
        () => TextEditingController(text: entry.value),
      );
    }
  }

  Future<void> _saveRecord() async {
    try {
      final repository = ref.read(safeRepositoryProvider);
      final record = ref.read(selectedRecordProvider(widget.recordId)).value;
      
      if (record == null) return;

      final updatedRecord = record.copyWith(
        title: _titleController.text,
        notes: _notesController.text,
        fields: Map.fromEntries(
          _fieldControllers.entries.map(
            (e) => MapEntry(e.key, e.value.text),
          ),
        ),
        modifiedAt: DateTime.now(),
      );

      await repository.updateRecord(updatedRecord);
      ref.invalidate(selectedRecordProvider(widget.recordId));
      ref.invalidate(allRecordsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Record saved successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordAsync = ref.watch(selectedRecordProvider(widget.recordId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Record Details'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.save,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _saveRecord,
            )
          else
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: recordAsync.when(
        data: (record) {
          if (_fieldControllers.isEmpty && record != null) {
            _initializeControllers(record);
          }

          if (record == null) {
            return const Center(
              child: Text(
                'Record not found',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final typeColor = AppTheme.getRecordTypeColor(record.type.name, isDarkMode);

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Record Type Header
                        _buildTypeHeader(context, record, typeColor),
                        const SizedBox(height: 24),

                        // Title Field
                        _buildFieldCard(
                          context,
                          'Title',
                          _isEditing
                              ? CustomTextField(
                                  controller: _titleController,
                                  labelText: 'Title',
                                )
                              : _buildDisplayField(
                                  context,
                                  _titleController.text,
                                  showCopy: false,
                                ),
                        ),

                        // Dynamic fields based on record type
                        ...record.fields.entries.map((entry) {
                          final controller = _fieldControllers[entry.key];
                          if (controller == null) return const SizedBox.shrink();

                          final fieldLabel = _getFieldLabel(record.type, entry.key);
                          final isSensitive = record.sensitiveFieldKeys.contains(entry.key);

                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _buildFieldCard(
                              context,
                              fieldLabel,
                              _isEditing
                                  ? CustomTextField(
                                      controller: controller,
                                      labelText: fieldLabel,
                                      obscureText: isSensitive && !_showSensitiveFields,
                                    )
                                  : _buildDisplayField(
                                      context,
                                      controller.text,
                                      isSensitive: isSensitive,
                                    ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Notes Field
                        _buildFieldCard(
                          context,
                          'Notes',
                          _isEditing
                              ? CustomTextField(
                                  controller: _notesController,
                                  labelText: 'Notes',
                                  maxLines: 4,
                                )
                              : _buildDisplayField(
                                  context,
                                  _notesController.text.isEmpty
                                      ? 'No notes'
                                      : _notesController.text,
                                  showCopy: _notesController.text.isNotEmpty,
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Sensitive Fields Toggle
                        if (!_isEditing && record.hasSensitiveFields)
                          _buildSensitiveToggle(context, typeColor),

                        const SizedBox(height: 24),

                        // Metadata Card
                        _buildMetadataCard(context, record, typeColor),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading record',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeHeader(BuildContext context, Record record, Color typeColor) {
    final typeInfo = AppConstants.recordTypes[record.type.name];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getIconForRecordType(record.type),
              color: typeColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeInfo?.name ?? record.type.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  typeInfo?.description ?? record.typeDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (record.isFavorite)
            Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.tertiary,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, String label, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayField(
    BuildContext context,
    String value,
    {bool isSensitive = false, bool showCopy = true}
  ) {
    final displayValue = isSensitive && !_showSensitiveFields 
        ? '•' * (value.length.clamp(6, 12))
        : value;

    return Row(
      children: [
        Expanded(
          child: Text(
            displayValue,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: isSensitive ? 'monospace' : null,
            ),
          ),
        ),
        if (showCopy && value.isNotEmpty) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _copyToClipboard(value),
            icon: Icon(
              Icons.copy,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSensitiveToggle(BuildContext context, Color typeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          'Show Sensitive Fields',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Reveal hidden passwords and sensitive data',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        value: _showSensitiveFields,
        onChanged: (value) {
          setState(() => _showSensitiveFields = value);
        },
        activeColor: typeColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, Record record, Color typeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Record Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetadataRow(context, 'Category', record.category ?? 'No Category'),
          _buildMetadataRow(context, 'Created', _formatDate(record.createdAt)),
          _buildMetadataRow(context, 'Modified', _formatDate(record.modifiedAt)),
          _buildMetadataRow(context, 'Record ID', record.id),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Edit Record'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(navigationServiceProvider).navigateToEditRecord(widget.recordId);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                title: const Text('Toggle Favorite'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final repository = ref.read(safeRepositoryProvider);
                    await repository.toggleFavorite(widget.recordId);
                    ref.invalidate(selectedRecordProvider(widget.recordId));
                    ref.invalidate(allRecordsProvider);
                    ref.invalidate(favoriteRecordsProvider);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Delete Record'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final repository = ref.read(safeRepositoryProvider);
                await repository.deleteRecord(widget.recordId);
                ref.invalidate(allRecordsProvider);
                
                if (mounted) {
                  Navigator.of(context).pop(); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Record deleted'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
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

  String _getFieldLabel(RecordType type, String fieldKey) {
    final fields = _getFieldsForType(type);
    return fields[fieldKey] ?? fieldKey;
  }

  Map<String, String> _getFieldsForType(RecordType type) {
    switch (type) {
      case RecordType.login:
        return AppConstants.loginFields;
      case RecordType.creditCard:
        return AppConstants.creditCardFields;
      case RecordType.bankAccount:
        return AppConstants.bankAccountFields;
      case RecordType.address:
        return AppConstants.addressFields;
      case RecordType.identity:
        return AppConstants.identityFields;
      case RecordType.wifi:
        return AppConstants.wifiFields;
      case RecordType.software:
        return AppConstants.softwareFields;
      case RecordType.server:
        return AppConstants.serverFields;
      case RecordType.document:
        return AppConstants.documentFields;
      case RecordType.membership:
        return AppConstants.membershipFields;
      case RecordType.vehicle:
        return AppConstants.vehicleFields;
      case RecordType.note:
        return {};
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}