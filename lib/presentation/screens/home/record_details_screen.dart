import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/models/record.dart';

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

class _RecordDetailsScreenState extends ConsumerState<RecordDetailsScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final Map<String, TextEditingController> _fieldControllers;
  bool _isEditing = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditing;
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _fieldControllers = {};
  }

  @override
  void dispose() {
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
      final repository = ref.read(repositoryProvider);
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
        const SnackBar(content: Text('Record saved')),
      );

      setState(() => _isEditing = false);
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

  Future<void> _copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordAsync = ref.watch(selectedRecordProvider(widget.recordId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save_outlined : Icons.edit_outlined),
            onPressed: () {
              if (_isEditing) {
                _saveRecord();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: recordAsync.when(
        data: (record) {
          if (_fieldControllers.isEmpty) {
            _initializeControllers(record!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),

                // Fields
                ...record!.fields.entries.map((entry) {
                  final controller = _fieldControllers[entry.key]!;
                  final isPassword = entry.key.toLowerCase().contains('password');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: controller,
                      enabled: _isEditing,
                      obscureText: isPassword && !_showPassword,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPassword)
                              IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                      () => _showPassword = !_showPassword);
                                },
                              ),
                            if (!_isEditing)
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () =>
                                    _copyToClipboard(controller.text),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Notes
                TextField(
                  controller: _notesController,
                  enabled: _isEditing,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),

                // Metadata
                const SizedBox(height: 24),
                Text(
                  'Category: ${record?.category ?? 'No Category'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Created: ${record?.createdAt?.toString() ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Modified: ${record?.modifiedAt?.toString() ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
    );
  }
}