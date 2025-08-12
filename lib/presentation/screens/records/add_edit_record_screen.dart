import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/models/record.dart';
import '../../widgets/custom_text_field.dart';

class AddEditRecordScreen extends ConsumerStatefulWidget {
  final String? recordId;

  const AddEditRecordScreen({this.recordId, super.key});

  @override
  ConsumerState<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends ConsumerState<AddEditRecordScreen> {
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
  bool _isFavorite = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _selectedType = RecordType.login;
    _loadRecord();
  }

  @override
  void dispose() {
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

    final record = await ref.read(selectedRecordProvider(widget.recordId!).future);
    if (record == null) return;

    setState(() {
      _selectedType = record.type;
      _titleController.text = record.title;
      _notesController.text = record.notes ?? '';
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
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(repositoryProvider);
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

      final record = Record(
        id: widget.recordId ?? '',
        type: _selectedType,
        title: _titleController.text,
        fields: fields,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isFavorite: _isFavorite,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      if (widget.recordId != null) {
        await repository.updateRecord(record);
      } else {
        await repository.createRecord(record);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _generatePassword() {
    ref.read(navigationServiceProvider).navigateToGeneratePassword();
  }

  Widget _buildLoginFields() {
    return Column(
      children: [
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
                ),
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
              ),
              IconButton(
                icon: const Icon(Icons.password),
                onPressed: _generatePassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _urlController,
          labelText: 'URL',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildCreditCardFields() {
    return Column(
      children: [
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
          labelText: 'Card Holder',
          validator: (value) =>
              value?.isEmpty == true ? 'Please enter the card holder name' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _expiryDateController,
                labelText: 'Expiry Date',
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
      ],
    );
  }

  Widget _buildBankAccountFields() {
    return Column(
      children: [
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recordId == null ? 'Add Record' : 'Edit Record'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<RecordType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Record Type',
                border: OutlineInputBorder(),
              ),
              items: RecordType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _titleController,
              labelText: 'Title',
              validator: (value) =>
                  value?.isEmpty == true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            if (_selectedType == RecordType.login) _buildLoginFields(),
            if (_selectedType == RecordType.creditCard) _buildCreditCardFields(),
            if (_selectedType == RecordType.bankAccount) _buildBankAccountFields(),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _notesController,
              labelText: 'Notes',
              maxLines: 3,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveRecord,
        child: const Icon(Icons.save),
      ),
    );
  }
}