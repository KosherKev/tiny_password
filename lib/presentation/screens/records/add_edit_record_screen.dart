import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/record.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddEditRecordScreen extends ConsumerStatefulWidget {
  final String? recordId;

  const AddEditRecordScreen({this.recordId, super.key});

  @override
  ConsumerState<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends ConsumerState<AddEditRecordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late RecordType _selectedType;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Field controllers for different record types
  final Map<String, TextEditingController> _fieldControllers = {};
  
  String _selectedCategory = 'Personal';
  bool _isFavorite = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedType = RecordType.login;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _initializeFieldControllers();
    _loadRecord();
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

  void _initializeFieldControllers() {
    // Initialize controllers for all possible fields
    final allFields = <String>[
      // Login fields
      'username', 'password', 'url', 'email', 'twoFactorSecret',
      // Credit card fields
      'cardNumber', 'cardholderName', 'expiryDate', 'cvv', 'pin', 'issuer',
      // Bank account fields
      'accountNumber', 'routingNumber', 'bankName', 'accountType', 'swiftCode', 'ibanNumber',
      // Address fields
      'addressLine1', 'addressLine2', 'city', 'state', 'postalCode', 'country', 'addressType',
      // Identity fields
      'documentType', 'documentNumber', 'fullName', 'dateOfBirth', 'issueDate', 'expiryDate', 'issuingAuthority', 'nationality',
      // WiFi fields
      'networkName', 'password', 'securityType', 'frequency', 'location',
      // Software fields
      'softwareName', 'licenseKey', 'version', 'purchaseDate', 'expiryDate', 'vendor', 'downloadUrl',
      // Server fields
      'serverName', 'ipAddress', 'port', 'username', 'password', 'privateKey', 'protocol', 'location',
      // Document fields
      'documentTitle', 'documentType', 'documentNumber', 'issueDate', 'expiryDate', 'issuingOrganization', 'fileLocation',
      // Membership fields
      'organizationName', 'membershipNumber', 'membershipType', 'username', 'password', 'startDate', 'expiryDate', 'benefits',
      // Vehicle fields
      'vehicleMake', 'vehicleModel', 'year', 'licensePlate', 'vin', 'registrationNumber', 'insurancePolicy', 'insuranceCompany',
    ];

    for (final field in allFields) {
      _fieldControllers[field] = TextEditingController();
    }
  }

  Future<void> _loadRecord() async {
    if (widget.recordId == null) return;

    try {
      final record = await ref.read(selectedRecordProvider(widget.recordId!).future);
      if (record == null) return;

      setState(() {
        _selectedType = record.type;
        _titleController.text = record.title;
        _notesController.text = record.notes ?? '';
        _selectedCategory = record.category ?? 'Personal';
        _isFavorite = record.isFavorite;

        // Populate field controllers
        for (final entry in record.fields.entries) {
          if (_fieldControllers.containsKey(entry.key)) {
            _fieldControllers[entry.key]!.text = entry.value;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading record: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(safeRepositoryProvider);
      final fields = <String, String>{};

      // Get the relevant fields for the selected type
      final relevantFields = _getFieldsForType(_selectedType);
      for (final fieldKey in relevantFields.keys) {
        final controller = _fieldControllers[fieldKey];
        if (controller != null && controller.text.isNotEmpty) {
          fields[fieldKey] = controller.text;
        }
      }

      final now = DateTime.now();
      final record = Record(
        id: widget.recordId ?? const Uuid().v4(),
        type: _selectedType,
        title: _titleController.text,
        fields: fields,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        category: _selectedCategory,
        isFavorite: _isFavorite,
        createdAt: now,
        modifiedAt: now,
      );

      if (widget.recordId != null) {
        await repository.updateRecord(record);
      } else {
        await repository.createRecord(record);
      }

      ref.invalidate(allRecordsProvider);
      ref.invalidate(favoriteRecordsProvider);
      if (widget.recordId != null) {
        ref.invalidate(selectedRecordProvider(widget.recordId!));
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.recordId == null ? 'Record created' : 'Record updated'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving record: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final typeColor = AppTheme.getRecordTypeColor(_selectedType.name, isDarkMode);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.recordId == null ? 'Add Record' : 'Edit Record'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                key: ValueKey(_isFavorite),
                color: _isFavorite ? Theme.of(context).colorScheme.tertiary : null,
              ),
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Record Type Selector
                            _buildTypeSelector(context, typeColor),
                            const SizedBox(height: 24),

                            // Title Field
                            CustomTextField(
                              controller: _titleController,
                              labelText: 'Title',
                              validator: (value) =>
                                  value?.isEmpty == true ? 'Please enter a title' : null,
                            ),

                            const SizedBox(height: 16),

                            // Category Selector
                            _buildCategorySelector(context),

                            const SizedBox(height: 24),

                            // Dynamic Fields
                            ..._buildTypeSpecificFields(context, typeColor),

                            const SizedBox(height: 24),

                            // Notes Field
                            CustomTextField(
                              controller: _notesController,
                              labelText: 'Notes (Optional)',
                              maxLines: 4,
                            ),

                            const SizedBox(height: 100), // Space for FAB
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildSaveButton(context),
    );
  }

  Widget _buildTypeSelector(BuildContext context, Color typeColor) {
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
              'Record Type',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DropdownButtonFormField<RecordType>(
              value: _selectedType,
              style: Theme.of(context).textTheme.bodyLarge,
              dropdownColor: Theme.of(context).colorScheme.surface,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: RecordType.values.map((type) {
                final typeInfo = AppConstants.recordTypes[type.name];
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                final color = AppTheme.getRecordTypeColor(type.name, isDarkMode);
                
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForRecordType(type),
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              typeInfo?.name ?? type.displayName,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (typeInfo?.description != null)
                              Text(
                                typeInfo!.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
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
              'Category',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              style: Theme.of(context).textTheme.bodyLarge,
              dropdownColor: Theme.of(context).colorScheme.surface,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: AppConstants.defaultCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getIconForCategory(category),
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields(BuildContext context, Color typeColor) {
    final fields = _getFieldsForType(_selectedType);
    if (fields.isEmpty) return [];

    return [
      Text(
        'Details',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: typeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      ...fields.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildField(context, entry.key, entry.value, typeColor),
        );
      }),
    ];
  }

  Widget _buildField(BuildContext context, String fieldKey, String fieldLabel, Color typeColor) {
    final controller = _fieldControllers[fieldKey];
    if (controller == null) return const SizedBox.shrink();

    final isPasswordField = fieldKey.toLowerCase().contains('password') || 
                           fieldKey == 'cvv' || 
                           fieldKey == 'pin' ||
                           fieldKey == 'licenseKey' ||
                           fieldKey == 'privateKey';

    final isRequiredField = _isRequiredField(fieldKey, _selectedType);

    // Special handling for dropdowns
    if (_isDropdownField(fieldKey)) {
      return _buildDropdownField(context, fieldKey, fieldLabel, typeColor);
    }

    // Special handling for date fields
    if (_isDateField(fieldKey)) {
      return _buildDateField(context, fieldKey, fieldLabel, controller);
    }

    return CustomTextField(
      controller: controller,
      labelText: fieldLabel + (isRequiredField ? ' *' : ''),
      obscureText: isPasswordField,
      keyboardType: _getKeyboardType(fieldKey),
      suffix: _buildFieldSuffix(fieldKey, isPasswordField),
      validator: isRequiredField ? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter ${fieldLabel.toLowerCase()}';
        }
        return null;
      } : null,
    );
  }

  Widget? _buildFieldSuffix(String fieldKey, bool isPasswordField) {
    if (isPasswordField && fieldKey == 'password') {
      return IconButton(
        icon: const Icon(Icons.auto_fix_high),
        onPressed: () {
          ref.read(navigationServiceProvider).navigateToGeneratePassword();
        },
      );
    }
    return null;
  }

  Widget _buildDropdownField(BuildContext context, String fieldKey, String fieldLabel, Color typeColor) {
    final controller = _fieldControllers[fieldKey]!;
    final options = _getDropdownOptions(fieldKey);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: fieldLabel,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: Theme.of(context).colorScheme.surface,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
          }
        },
      ),
    );
  }

  Widget _buildDateField(BuildContext context, String fieldKey, String fieldLabel, TextEditingController controller) {
    return CustomTextField(
      controller: controller,
      labelText: fieldLabel,
      readOnly: true,
      suffix: IconButton(
        icon: const Icon(Icons.calendar_today),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            controller.text = '${date.day}/${date.month}/${date.year}';
          }
        },
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: CustomButton(
        text: widget.recordId == null ? 'Create Record' : 'Update Record',
        onPressed: _isLoading ? null : _saveRecord,
        isLoading: _isLoading,
        width: double.infinity,
        icon: widget.recordId == null ? Icons.add : Icons.save,
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

  bool _isRequiredField(String fieldKey, RecordType type) {
    switch (type) {
      case RecordType.login:
        return ['username', 'password'].contains(fieldKey);
      case RecordType.creditCard:
        return ['cardNumber', 'cardholderName', 'expiryDate', 'cvv'].contains(fieldKey);
      case RecordType.bankAccount:
        return ['accountNumber', 'bankName'].contains(fieldKey);
      case RecordType.address:
        return ['addressLine1', 'city'].contains(fieldKey);
      case RecordType.identity:
        return ['documentType', 'documentNumber'].contains(fieldKey);
      case RecordType.wifi:
        return ['networkName'].contains(fieldKey);
      case RecordType.software:
        return ['softwareName'].contains(fieldKey);
      case RecordType.server:
        return ['serverName'].contains(fieldKey);
      case RecordType.document:
        return ['documentTitle'].contains(fieldKey);
      case RecordType.membership:
        return ['organizationName'].contains(fieldKey);
      case RecordType.vehicle:
        return ['vehicleMake', 'vehicleModel'].contains(fieldKey);
      case RecordType.note:
        return false;
    }
  }

  bool _isDropdownField(String fieldKey) {
    return ['documentType', 'addressType', 'securityType', 'accountType', 'membershipType'].contains(fieldKey);
  }

  bool _isDateField(String fieldKey) {
    return ['dateOfBirth', 'issueDate', 'expiryDate', 'purchaseDate', 'startDate'].contains(fieldKey);
  }

  TextInputType _getKeyboardType(String fieldKey) {
    if (['cardNumber', 'cvv', 'accountNumber', 'routingNumber', 'port', 'year'].contains(fieldKey)) {
      return TextInputType.number;
    }
    if (['email'].contains(fieldKey)) {
      return TextInputType.emailAddress;
    }
    if (['url', 'downloadUrl'].contains(fieldKey)) {
      return TextInputType.url;
    }
    return TextInputType.text;
  }

  List<String> _getDropdownOptions(String fieldKey) {
    switch (fieldKey) {
      case 'documentType':
        return AppConstants.identityDocumentTypes;
      case 'addressType':
        return AppConstants.addressTypes;
      case 'securityType':
        return AppConstants.wifiSecurityTypes;
      case 'accountType':
        return AppConstants.bankAccountTypes;
      case 'membershipType':
        return ['Standard', 'Premium', 'VIP', 'Student', 'Senior', 'Family', 'Corporate'];
      default:
        return [];
    }
  }
}