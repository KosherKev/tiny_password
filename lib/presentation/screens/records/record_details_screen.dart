import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../domain/models/record.dart';
import '../../widgets/custom_text_field.dart';
import 'dart:math' as math;

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
  bool _showPasswords = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _slideAnimation = Tween<double>(
      begin: 30.0,
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
    _particleController.dispose();
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
          backgroundColor: const Color(0xFF22c55e),
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
          backgroundColor: const Color(0xFFef4444),
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
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: const Color(0xFF22c55e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
    final recordAsync = ref.watch(selectedRecordProvider(widget.recordId));

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
                  painter: DetailParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            recordAsync.when(
              data: (record) {
                if (_fieldControllers.isEmpty && record != null) {
                  _initializeControllers(record);
                }

                if (record == null) {
                  return const Center(
                    child: Text(
                      'Record not found',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                return AnimatedBuilder(
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
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              actions: [
                                if (_isEditing)
                                  IconButton(
                                    icon: const Icon(Icons.save, color: Color(0xFF22c55e)),
                                    onPressed: _saveRecord,
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFFfbbf24)),
                                    onPressed: () => setState(() => _isEditing = true),
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
                                            _getRecordTypeColor(record.type),
                                            _getRecordTypeColor(record.type).withOpacity(0.8),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        _getRecordTypeIcon(record.type),
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        record.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                  // Record type indicator
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          _getRecordTypeColor(record.type).withOpacity(0.1),
                                          _getRecordTypeColor(record.type).withOpacity(0.05),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: _getRecordTypeColor(record.type).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getRecordTypeIcon(record.type),
                                          color: _getRecordTypeColor(record.type),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          record.type.toString().split('.').last.toUpperCase(),
                                          style: TextStyle(
                                            color: _getRecordTypeColor(record.type),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (record.isFavorite)
                                          const Icon(
                                            Icons.star,
                                            color: Color(0xFFfbbf24),
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Title field
                                  _buildFieldCard(
                                    label: 'Title',
                                    child: _isEditing
                                        ? CustomTextField(
                                            controller: _titleController,
                                            labelText: 'Title',
                                          )
                                        : _buildDisplayField(
                                            _titleController.text,
                                            showCopy: false,
                                          ),
                                  ),

                                  // Dynamic fields based on record type
                                  ...record.fields.entries.map((entry) {
                                    final controller = _fieldControllers[entry.key]!;
                                    final isPassword = entry.key.toLowerCase().contains('password');

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: _buildFieldCard(
                                        label: _formatFieldLabel(entry.key),
                                        child: _isEditing
                                            ? CustomTextField(
                                                controller: controller,
                                                labelText: _formatFieldLabel(entry.key),
                                                obscureText: isPassword && !_showPasswords,
                                              )
                                            : _buildDisplayField(
                                                controller.text,
                                                isPassword: isPassword,
                                              ),
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 16),

                                  // Notes field
                                  _buildFieldCard(
                                    label: 'Notes',
                                    child: _isEditing
                                        ? CustomTextField(
                                            controller: _notesController,
                                            labelText: 'Notes',
                                            maxLines: 4,
                                          )
                                        : _buildDisplayField(
                                            _notesController.text.isEmpty
                                                ? 'No notes'
                                                : _notesController.text,
                                            showCopy: _notesController.text.isNotEmpty,
                                          ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Password visibility toggle
                                  if (!_isEditing && record.fields.values.any((v) => v.isNotEmpty))
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.05),
                                            Colors.white.withOpacity(0.02),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: SwitchListTile(
                                        title: const Text(
                                          'Show Passwords',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Reveal hidden fields',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                        value: _showPasswords,
                                        onChanged: (value) {
                                          setState(() => _showPasswords = value);
                                        },
                                        activeColor: const Color(0xFFfbbf24),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 24),

                                  // Metadata card
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.05),
                                          Colors.white.withOpacity(0.02),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFF6b7280),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Record Information',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildMetadataRow('Category', record.category ?? 'No Category'),
                                        _buildMetadataRow('Created', _formatDate(record.createdAt)),
                                        _buildMetadataRow('Modified', _formatDate(record.modifiedAt)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 100),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFfbbf24),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading record',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard({required String label, required Widget child}) {
    return Container(
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
              label,
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
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayField(String value, {bool isPassword = false, bool showCopy = true}) {
    final displayValue = isPassword && !_showPasswords 
        ? '•' * (value.length.clamp(6, 12))
        : value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: isPassword ? 'monospace' : null,
              ),
            ),
          ),
          if (showCopy && value.isNotEmpty) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _copyToClipboard(value),
              icon: const Icon(
                Icons.copy,
                color: Color(0xFFfbbf24),
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFfbbf24).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFieldLabel(String key) {
    return key
        .split(RegExp(r'(?=[A-Z])'))
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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

// Custom painter for detail screen particles
class DetailParticlePainter extends CustomPainter {
  final double animationValue;

  DetailParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create subtle floating particles
    for (int i = 0; i < 6; i++) {
      final progress = (animationValue + i * 0.2) % 1.0;
      final x = size.width * (0.1 + i * 0.15) + 
                (15 * math.sin(progress * 2 * math.pi));
      final y = size.height * (0.2 + progress * 0.6);
      
      paint.color = const Color(0xFFfbbf24).withOpacity(0.2);
      
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}