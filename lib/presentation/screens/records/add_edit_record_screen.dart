import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/models/record.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'dart:math' as math;

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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Personal';
  bool _isFavorite = false;
  bool _showPassword = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedType = RecordType.login;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _slideAnimation = Tween<double>(
      begin: 50.0,
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
    _loadRecord();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _notesController.dispose();
    super.dispose();
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

        switch (record.type) {
          case RecordType.login:
            final fields = record.fields;
            _usernameController.text = fields['username'] ?? '';
            _passwordController.text = fields['password'] ?? '';
            _urlController.text = fields['url'] ?? '';
            break;
          case RecordType.creditCard:
            final fields = record.fields;
            _cardNumberController.text = fields['cardNumber'] ?? '';
            _cardHolderController.text = fields['cardHolder'] ?? '';
            _expiryDateController.text = fields['expiryDate'] ?? '';
            _cvvController.text = fields['cvv'] ?? '';
            break;
          case RecordType.bankAccount:
            final fields = record.fields;
            _bankNameController.text = fields['bankName'] ?? '';
            _accountNumberController.text = fields['accountNumber'] ?? '';
            _routingNumberController.text = fields['routingNumber'] ?? '';
            break;
          case RecordType.note:
            break;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading record: $e'),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

      switch (_selectedType) {
        case RecordType.login:
          fields['username'] = _usernameController.text;
          fields['password'] = _passwordController.text;
          fields['url'] = _urlController.text;
          break;
        case RecordType.creditCard:
          fields['cardNumber'] = _cardNumberController.text;
          fields['cardHolder'] = _cardHolderController.text;
          fields['expiryDate'] = _expiryDateController.text;
          fields['cvv'] = _cvvController.text;
          break;
        case RecordType.bankAccount:
          fields['bankName'] = _bankNameController.text;
          fields['accountNumber'] = _accountNumberController.text;
          fields['routingNumber'] = _routingNumberController.text;
          break;
        case RecordType.note:
          break;
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
          backgroundColor: const Color(0xFF22c55e),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving record: $e'),
          backgroundColor: const Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generatePassword() {
    ref.read(navigationServiceProvider).navigateToGeneratePassword();
  }

  Color _getRecordTypeColor(RecordType type) {
    switch (type) {
      case RecordType.login:
        return const Color(0xFF3b82f6);
      case RecordType.creditCard:
        return const Color(0xFFef4444);
      case RecordType.bankAccount:
        return const Color(0xFF22c55e);
      case RecordType.note:
        return const Color(0xFF8b5cf6);
    }
  }

  IconData _getRecordTypeIcon(RecordType type) {
    switch (type) {
      case RecordType.login:
        return Icons.key;
      case RecordType.creditCard:
        return Icons.credit_card;
      case RecordType.bankAccount:
        return Icons.account_balance;
      case RecordType.note:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF0f0f0f),
              Color(0xFF2d2d2d),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Marble texture overlay
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/marble_texture.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.02),
                    BlendMode.overlay,
                  ),
                ),
              ),
            ),

            // Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: EditParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: CustomScrollView(
                      slivers: [
                        // Modern App Bar
                        SliverAppBar(
                          expandedHeight: 120,
                          floating: false,
                          pinned: true,
                          backgroundColor: Colors.transparent,
                          leading: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          actions: [
                            IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _isFavorite ? Icons.star : Icons.star_border,
                                  key: ValueKey(_isFavorite),
                                  color: _isFavorite ? const Color(0xFFfbbf24) : Colors.grey[400],
                                ),
                              ),
                              onPressed: () {
                                setState(() => _isFavorite = !_isFavorite);
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
                            title: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        _getRecordTypeColor(_selectedType),
                                        _getRecordTypeColor(_selectedType).withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    _getRecordTypeIcon(_selectedType),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.recordId == null ? 'Add Record' : 'Edit Record',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Content
                        SliverPadding(
                          padding: const EdgeInsets.all(24),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Record type selector
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.08),
                                            Colors.white.withOpacity(0.04),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                            child: Text(
                                              'Record Type',
                                              style: TextStyle(
                                                color: const Color(0xFFfbbf24),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                            child: DropdownButtonFormField<RecordType>(
                                              value: _selectedType,
                                              style: const TextStyle(color: Colors.white),
                                              dropdownColor: const Color(0xFF1a1a1a),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              items: RecordType.values.map((type) {
                                                return DropdownMenuItem(
                                                  value: type,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        _getRecordTypeIcon(type),
                                                        color: _getRecordTypeColor(type),
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        type.toString().split('.').last.toUpperCase(),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w500,
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
                                    ),

                                    const SizedBox(height: 24),

                                    // Title field
                                    CustomTextField(
                                      controller: _titleController,
                                      labelText: 'Title',
                                      validator: (value) =>
                                          value?.isEmpty == true ? 'Please enter a title' : null,
                                    ),

                                    const SizedBox(height: 16),

                                    // Category selector
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.08),
                                            Colors.white.withOpacity(0.04),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                            child: Text(
                                              'Category',
                                              style: TextStyle(
                                                color: const Color(0xFFfbbf24),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                            child: DropdownButtonFormField<String>(
                                              value: _selectedCategory,
                                              style: const TextStyle(color: Colors.white),
                                              dropdownColor: const Color(0xFF1a1a1a),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              items: ['Personal', 'Work', 'Finance', 'Shopping', 'Social', 'Other']
                                                  .map((category) => DropdownMenuItem(
                                                        value: category,
                                                        child: Text(
                                                          category,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ))
                                                  .toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  setState(() => _selectedCategory = value);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Dynamic fields based on record type
                                    ..._buildTypeSpecificFields(),

                                    const SizedBox(height: 16),

                                    // Notes field
                                    CustomTextField(
                                      controller: _notesController,
                                      labelText: 'Notes (Optional)',
                                      maxLines: 4,
                                    ),

                                    const SizedBox(height: 40),

                                    // Save button
                                    CustomButton(
                                      text: widget.recordId == null ? 'Create Record' : 'Update Record',
                                      onPressed: _isLoading ? null : _saveRecord,
                                      isLoading: _isLoading,
                                      width: double.infinity,
                                      icon: widget.recordId == null ? Icons.add : Icons.save,
                                    ),

                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    switch (_selectedType) {
      case RecordType.login:
        return _buildLoginFields();
      case RecordType.creditCard:
        return _buildCreditCardFields();
      case RecordType.bankAccount:
        return _buildBankAccountFields();
      case RecordType.note:
        return [];
    }
  }

  List<Widget> _buildLoginFields() {
    return [
      CustomTextField(
        controller: _usernameController,
        labelText: 'Username',
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter a username' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _passwordController,
        labelText: 'Password',
        obscureText: !_showPassword,
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter a password' : null,
        suffix: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFFfbbf24),
              ),
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.auto_fix_high,
                color: Color(0xFFfbbf24),
              ),
              onPressed: _generatePassword,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _urlController,
        labelText: 'Website URL (Optional)',
        keyboardType: TextInputType.url,
      ),
    ];
  }

  List<Widget> _buildCreditCardFields() {
    return [
      CustomTextField(
        controller: _cardNumberController,
        labelText: 'Card Number',
        keyboardType: TextInputType.number,
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter a card number' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _cardHolderController,
        labelText: 'Card Holder Name',
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter the card holder name' : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _expiryDateController,
              labelText: 'Expiry Date (MM/YY)',
              keyboardType: TextInputType.datetime,
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter expiry date' : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomTextField(
              controller: _cvvController,
              labelText: 'CVV',
              keyboardType: TextInputType.number,
              obscureText: true,
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter CVV' : null,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildBankAccountFields() {
    return [
      CustomTextField(
        controller: _bankNameController,
        labelText: 'Bank Name',
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter bank name' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _accountNumberController,
        labelText: 'Account Number',
        keyboardType: TextInputType.number,
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter account number' : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _routingNumberController,
        labelText: 'Routing Number',
        keyboardType: TextInputType.number,
        validator: (value) =>
            value?.isEmpty == true ? 'Please enter routing number' : null,
      ),
    ];
  }
}

// Custom painter for edit screen particles
class EditParticlePainter extends CustomPainter {
  final double animationValue;

  EditParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create flowing particles
    for (int i = 0; i < 8; i++) {
      final progress = (animationValue + i * 0.125) % 1.0;
      final x = size.width * (0.1 + i * 0.1) + 
                (20 * math.sin(progress * 3 * math.pi));
      final y = size.height * (0.1 + progress * 0.8);
      
      paint.color = i % 2 == 0 
        ? const Color(0xFFfbbf24).withOpacity(0.3)
        : Colors.white.withOpacity(0.2);
      
      final radius = 1 + math.sin(progress * 4 * math.pi) * 0.5;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}