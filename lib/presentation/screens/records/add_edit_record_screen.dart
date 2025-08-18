import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/record.dart';
import '../../../domain/models/attachment.dart';
import '../../../services/attachment_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddEditRecordScreen extends ConsumerStatefulWidget {
  final String? recordId;
  final RecordType? defaultType;

  const AddEditRecordScreen({this.recordId, this.defaultType, super.key});

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
  
  // Attachments
  List<Attachment> _attachments = [];
  bool _showSensitiveFields = true; // Show attachments by default
  
  String _selectedCategory = 'Personal';
  bool _isFavorite = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType ?? RecordType.login;
    
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

    _initializeFieldControllers();
    
    // Start animation and load record after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _loadRecord();
    });
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

      if (mounted) {
        setState(() {
          _selectedType = record.type;
          _titleController.text = record.title;
          _notesController.text = record.notes ?? '';
          _selectedCategory = record.category ?? 'Personal';
          _isFavorite = record.isFavorite;
          _attachments = List.from(record.attachments);

          // Populate field controllers
          for (final entry in record.fields.entries) {
            if (_fieldControllers.containsKey(entry.key)) {
              _fieldControllers[entry.key]!.text = entry.value;
            }
          }
        });
      }
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
        attachments: _attachments,
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

  bool _supportsAttachments(RecordType type) {
    return [
      RecordType.identity,
      RecordType.vehicle,
      RecordType.document,
      RecordType.membership,
      RecordType.creditCard,
    ].contains(type);
  }

  List<Widget> _buildAttachmentsSection(BuildContext context, Color typeColor) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Attachments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: typeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_attachments.isNotEmpty)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSensitiveFields = !_showSensitiveFields;
                    });
                  },
                  icon: Icon(
                    _showSensitiveFields ? Icons.visibility_off : Icons.visibility,
                    color: typeColor,
                    size: 20,
                  ),
                  tooltip: _showSensitiveFields ? 'Hide Attachments' : 'Show Attachments',
                ),
              IconButton(
                onPressed: () => _showAttachmentPicker(context),
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: typeColor,
                ),
                tooltip: 'Add Attachment',
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_attachments.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.attach_file_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No attachments yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap + to add images or PDFs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
      else
        ...List.generate(_attachments.length, (index) {
          final attachment = _attachments[index];
          return _buildAttachmentPreview(context, attachment, index, typeColor);
        }),
    ];
  }

  Future<void> _showAttachmentPicker(BuildContext context) async {
    final authService = ref.read(authServiceProvider);
    final attachmentService = AttachmentService(authService.encryptionService);
    final attachment = await attachmentService.showAttachmentPicker(context);
    
    if (attachment != null) {
      setState(() {
        _attachments.add(attachment);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Widget _buildAttachmentPreview(BuildContext context, Attachment attachment, int index, Color typeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filename and actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  attachment.type == AttachmentType.image
                      ? Icons.image_outlined
                      : Icons.picture_as_pdf_outlined,
                  color: typeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        attachment.formattedFileSize,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeAttachment(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
          // Preview content
          if (_showSensitiveFields)
            _buildAttachmentContent(context, attachment, typeColor),
        ],
      ),
    );
  }

  Widget _buildAttachmentContent(BuildContext context, Attachment attachment, Color typeColor) {
    return FutureBuilder<File?>(
      future: _getAttachmentFile(attachment),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: 100,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preview unavailable',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final file = snapshot.data!;
        
        if (attachment.type == AttachmentType.image) {
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            constraints: const BoxConstraints(
              maxHeight: 300,
              minHeight: 150,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Theme.of(context).colorScheme.error,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image preview failed',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          // PDF preview placeholder
          return Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: typeColor.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: typeColor,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF Document',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to view full document',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<File?> _getAttachmentFile(Attachment attachment) async {
    try {
      final authService = ref.read(authServiceProvider);
      final attachmentService = AttachmentService(authService.encryptionService);
      return await attachmentService.getTempFile(attachment);
    } catch (e) {
      return null;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 120, // Account for button area
                              ),
                              child: IntrinsicHeight(
                                child: Form(
                                  key: _formKey,
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

                                      const SizedBox(height: 24),

                                      // Attachments Section (for supported record types)
                                      if (_supportsAttachments(_selectedType))
                                        ..._buildAttachmentsSection(context, typeColor),

                                      const SizedBox(height: 140), // Increased space for bottom button
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Bottom button area - fixed position with safe area
                        SafeArea(
                          top: false,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: CustomButton(
                              text: widget.recordId == null ? 'Create Record' : 'Update Record',
                              onPressed: _isLoading ? null : _saveRecord,
                              isLoading: _isLoading,
                              width: double.infinity,
                              icon: widget.recordId == null ? Icons.add : Icons.save,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context, Color typeColor) {
    final typeInfo = AppConstants.recordTypes[_selectedType.name];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedTypeColor = AppTheme.getRecordTypeColor(_selectedType.name, isDarkMode);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            child: GestureDetector(
              onTap: () => _showEnhancedTypeDropdown(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selectedTypeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForRecordType(_selectedType),
                        color: selectedTypeColor,
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
                            typeInfo?.name ?? _selectedType.displayName,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnhancedTypeDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnhancedTypeDropdown(
        selectedType: _selectedType,
        onTypeSelected: (type) {
          setState(() => _selectedType = type);
          Navigator.of(context).pop();
        },
        getIconForRecordType: _getIconForRecordType,
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            child: GestureDetector(
              onTap: () => _showEnhancedCategoryDropdown(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _getIconForCategory(_selectedCategory),
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategory,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnhancedCategoryDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnhancedCategoryDropdown(
        selectedCategory: _selectedCategory,
        onCategorySelected: (category) {
          setState(() => _selectedCategory = category);
          Navigator.of(context).pop();
        },
        getIconForCategory: _getIconForCategory,
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
      width: double.infinity, // Add explicit width constraint
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
        isExpanded: true, // Add this to prevent overflow
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(
              option,
              overflow: TextOverflow.ellipsis, // Add overflow handling
            ),
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

class _EnhancedCategoryDropdown extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final IconData Function(String) getIconForCategory;

  const _EnhancedCategoryDropdown({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.getIconForCategory,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black54,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent dismissal when tapping inside
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar and close button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Handle bar
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          // Close button
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Select Category',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: AppConstants.defaultCategories.length,
                        itemBuilder: (context, index) {
                          final category = AppConstants.defaultCategories[index];
                          final isSelected = category == selectedCategory;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => onCategorySelected(category),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        getIconForCategory(category),
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          category,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                    : null,
                                              ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom padding for safe area
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EnhancedTypeDropdown extends StatelessWidget {
  final RecordType selectedType;
  final Function(RecordType) onTypeSelected;
  final IconData Function(RecordType) getIconForRecordType;

  const _EnhancedTypeDropdown({
    required this.selectedType,
    required this.onTypeSelected,
    required this.getIconForRecordType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black54,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return GestureDetector(
              onTap: () {}, // Prevent dismissal when tapping inside
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar and close button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Handle bar
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          // Close button
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Select Record Type',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Record type list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: RecordType.values.length,
                        itemBuilder: (context, index) {
                          final type = RecordType.values[index];
                          final typeInfo = AppConstants.recordTypes[type.name];
                          final isSelected = type == selectedType;
                          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                          final typeColor = AppTheme.getRecordTypeColor(type.name, isDarkMode);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected
                                  ? typeColor.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => onTypeSelected(type),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          getIconForRecordType(type),
                                          color: typeColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              typeInfo?.name ?? type.displayName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    color: isSelected
                                                        ? typeColor
                                                        : null,
                                                  ),
                                            ),
                                            if (typeInfo?.description != null)
                                              Text(
                                                typeInfo!.description,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: typeColor,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom padding for safe area
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}