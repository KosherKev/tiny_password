import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../domain/models/attachment.dart';
import '../core/encryption/encryption_service.dart';

class AttachmentService {
  static const _uuid = Uuid();
  static const int _maxImageSize = 2 * 1024 * 1024; // 2MB
  static const int _maxPdfSize = 10 * 1024 * 1024; // 10MB
  static const int _imageQuality = 85; // JPEG quality
  
  final EncryptionService _encryptionService;
  final ImagePicker _imagePicker = ImagePicker();
  
  AttachmentService(this._encryptionService);

  /// Get the secure attachments directory
  Future<Directory> _getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(path.join(appDir.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  /// Check and request necessary permissions
  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final cameraStatus = await Permission.camera.status;
      final storageStatus = await Permission.storage.status;
      
      if (cameraStatus.isDenied) {
        final cameraResult = await Permission.camera.request();
        if (!cameraResult.isGranted) return false;
      }
      
      if (storageStatus.isDenied) {
        final storageResult = await Permission.storage.request();
        if (!storageResult.isGranted) return false;
      }
    }
    return true;
  }

  /// Pick image from camera
  Future<Attachment?> pickImageFromCamera() async {
    try {
      if (!await _checkPermissions()) {
        throw Exception('Camera permission denied');
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: _imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image == null) return null;
      
      return await _processImageFile(image);
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<Attachment?> pickImageFromGallery() async {
    try {
      if (!await _checkPermissions()) {
        throw Exception('Gallery permission denied');
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image == null) return null;
      
      return await _processImageFile(image);
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Pick PDF file
  Future<Attachment?> pickPdfFile() async {
    try {
      if (!await _checkPermissions()) {
        throw Exception('File access permission denied');
      }
      
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return null;
      
      final file = File(result.files.first.path!);
      final fileSize = await file.length();
      
      if (fileSize > _maxPdfSize) {
        throw Exception('PDF file is too large. Maximum size is ${(_maxPdfSize / (1024 * 1024)).toStringAsFixed(1)} MB');
      }
      
      return await _processPdfFile(file, result.files.first.name);
    } catch (e) {
      debugPrint('Error picking PDF file: $e');
      rethrow;
    }
  }

  /// Process and save image file
  Future<Attachment> _processImageFile(XFile imageFile) async {
    final file = File(imageFile.path);
    final fileSize = await file.length();
    
    // Compress image if it's too large
    Uint8List imageBytes;
    if (fileSize > _maxImageSize) {
      imageBytes = await _compressImage(await file.readAsBytes());
    } else {
      imageBytes = await file.readAsBytes();
    }
    
    // Generate unique filename
    final attachmentId = _uuid.v4();
    final fileName = '${path.basenameWithoutExtension(imageFile.name)}_$attachmentId.jpg';
    
    // Encrypt and save
    final encryptedBytes = _encryptionService.encryptBytes(imageBytes);
    final attachmentsDir = await _getAttachmentsDirectory();
    final savedFile = File(path.join(attachmentsDir.path, fileName));
    await savedFile.writeAsBytes(encryptedBytes);
    
    return Attachment(
      id: attachmentId,
      fileName: path.basename(imageFile.name),
      type: AttachmentType.image,
      filePath: savedFile.path,
      fileSize: imageBytes.length,
      createdAt: DateTime.now(),
    );
  }

  /// Process and save PDF file
  Future<Attachment> _processPdfFile(File pdfFile, String originalName) async {
    final fileBytes = await pdfFile.readAsBytes();
    
    // Generate unique filename
    final attachmentId = _uuid.v4();
    final fileName = '${path.basenameWithoutExtension(originalName)}_$attachmentId.pdf';
    
    // Encrypt and save
    final encryptedBytes = _encryptionService.encryptBytes(fileBytes);
    final attachmentsDir = await _getAttachmentsDirectory();
    final savedFile = File(path.join(attachmentsDir.path, fileName));
    await savedFile.writeAsBytes(encryptedBytes);
    
    return Attachment(
      id: attachmentId,
      fileName: originalName,
      type: AttachmentType.pdf,
      filePath: savedFile.path,
      fileSize: fileBytes.length,
      createdAt: DateTime.now(),
    );
  }

  /// Compress image to reduce file size
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;
    
    // Calculate new dimensions while maintaining aspect ratio
    int newWidth = image.width;
    int newHeight = image.height;
    
    if (newWidth > 1920 || newHeight > 1920) {
      final aspectRatio = newWidth / newHeight;
      if (newWidth > newHeight) {
        newWidth = 1920;
        newHeight = (1920 / aspectRatio).round();
      } else {
        newHeight = 1920;
        newWidth = (1920 * aspectRatio).round();
      }
    }
    
    // Resize image
    final resizedImage = img.copyResize(image, width: newWidth, height: newHeight);
    
    // Encode as JPEG with quality compression
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: _imageQuality));
  }

  /// Get decrypted file bytes for display
  Future<Uint8List> getAttachmentBytes(Attachment attachment) async {
    try {
      final file = File(attachment.filePath);
      if (!await file.exists()) {
        throw Exception('Attachment file not found');
      }
      
      final encryptedBytes = await file.readAsBytes();
      return _encryptionService.decryptBytes(encryptedBytes);
    } catch (e) {
      debugPrint('Error reading attachment: $e');
      rethrow;
    }
  }

  /// Delete attachment file
  Future<void> deleteAttachment(Attachment attachment) async {
    try {
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
      rethrow;
    }
  }

  /// Get temporary file for sharing/viewing
  Future<File> getTempFile(Attachment attachment) async {
    final bytes = await getAttachmentBytes(attachment);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(path.join(tempDir.path, attachment.fileName));
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  /// Show attachment picker dialog
  Future<Attachment?> showAttachmentPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Add Attachment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            
            // Camera option
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture with camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            
            // Gallery option
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose Photo'),
              subtitle: const Text('Select from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            
            // PDF option
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Choose PDF'),
              subtitle: const Text('Select PDF document'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            
            const SizedBox(height: 10),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || !context.mounted) return null;

    Attachment? attachment;
    try {
      switch (result) {
        case 'camera':
          attachment = await pickImageFromCamera();
          break;
        case 'gallery':
          attachment = await pickImageFromGallery();
          break;
        case 'pdf':
          attachment = await pickPdfFile();
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
      return null;
    }

    if (attachment != null && context.mounted) {
      return await _showNameDialog(context, attachment);
    }

    return attachment;
  }

  /// Show dialog to name/rename an attachment
  Future<Attachment?> _showNameDialog(BuildContext context, Attachment attachment) async {
    final TextEditingController nameController = TextEditingController();
    
    // Extract filename without extension for initial value
    final fileName = attachment.fileName;
    final lastDotIndex = fileName.lastIndexOf('.');
    final nameWithoutExtension = lastDotIndex > 0 ? fileName.substring(0, lastDotIndex) : fileName;
    final extension = lastDotIndex > 0 ? fileName.substring(lastDotIndex) : '';
    
    nameController.text = nameWithoutExtension;
    
    return showDialog<Attachment>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Attachment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give this attachment a custom name:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Attachment name',
                hintText: 'Enter a descriptive name',
                suffixText: extension.isNotEmpty ? extension : null,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, attachment), // Keep original name
            child: const Text('Keep Original'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final finalName = extension.isNotEmpty ? '$newName$extension' : newName;
                final renamedAttachment = Attachment(
                  id: attachment.id,
                  fileName: finalName,
                  filePath: attachment.filePath,
                  fileSize: attachment.fileSize,
                  type: attachment.type,
                  createdAt: attachment.createdAt,
                );
                Navigator.pop(context, renamedAttachment);
              } else {
                Navigator.pop(context, attachment);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog to user
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message.replaceFirst('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}