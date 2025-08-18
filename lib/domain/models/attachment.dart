import 'package:flutter/foundation.dart';

enum AttachmentType {
  image,
  pdf;

  String get displayName {
    switch (this) {
      case AttachmentType.image:
        return 'Image';
      case AttachmentType.pdf:
        return 'PDF';
    }
  }

  String get fileExtension {
    switch (this) {
      case AttachmentType.image:
        return '.jpg';
      case AttachmentType.pdf:
        return '.pdf';
    }
  }
}

@immutable
class Attachment {
  final String id;
  final String fileName;
  final AttachmentType type;
  final String filePath; // Encrypted file path on device
  final int fileSize; // Size in bytes
  final DateTime createdAt;
  final String? description; // Optional description for the attachment

  const Attachment({
    required this.id,
    required this.fileName,
    required this.type,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    this.description,
  });

  Attachment copyWith({
    String? id,
    String? fileName,
    AttachmentType? type,
    String? filePath,
    int? fileSize,
    DateTime? createdAt,
    String? description,
  }) {
    return Attachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'type': type.toString(),
      'filePath': filePath,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
    );
  }

  // Helper methods
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  bool get isImage => type == AttachmentType.image;
  bool get isPdf => type == AttachmentType.pdf;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attachment &&
        other.id == id &&
        other.fileName == fileName &&
        other.type == type &&
        other.filePath == filePath &&
        other.fileSize == fileSize &&
        other.createdAt == createdAt &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fileName,
      type,
      filePath,
      fileSize,
      createdAt,
      description,
    );
  }
}