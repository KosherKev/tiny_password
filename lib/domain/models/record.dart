import 'package:flutter/foundation.dart';
import 'attachment.dart';

enum RecordType {
  login,
  creditCard,
  bankAccount,
  note,
  address,
  identity,
  wifi,
  software,
  server,
  document,
  membership,
  vehicle;

  String get displayName {
    switch (this) {
      case RecordType.login:
        return 'Login';
      case RecordType.creditCard:
        return 'Payment Card';
      case RecordType.bankAccount:
        return 'Bank Account';
      case RecordType.note:
        return 'Secure Note';
      case RecordType.address:
        return 'Address';
      case RecordType.identity:
        return 'Identity';
      case RecordType.wifi:
        return 'WiFi';
      case RecordType.software:
        return 'Software';
      case RecordType.server:
        return 'Server';
      case RecordType.document:
        return 'Document';
      case RecordType.membership:
        return 'Membership';
      case RecordType.vehicle:
        return 'Vehicle';
    }
  }
}

@immutable
class Record {
  final String id;
  final String title;
  final RecordType type;
  final Map<String, String> fields;
  final String? notes;
  final String? category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<Attachment> attachments;

  const Record({
    required this.id,
    required this.title,
    required this.type,
    required this.fields,
    this.notes,
    this.category,
    required this.isFavorite,
    required this.createdAt,
    required this.modifiedAt,
    this.attachments = const [],
  });

  Record copyWith({
    String? id,
    String? title,
    RecordType? type,
    Map<String, String>? fields,
    String? notes,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<Attachment>? attachments,
  }) {
    return Record(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      fields: fields ?? Map.from(this.fields),
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      attachments: attachments ?? List.from(this.attachments),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString(),
      'fields': fields,
      'notes': notes,
      'category': category,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'] as String,
      title: json['title'] as String,
      type: RecordType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      fields: Map<String, String>.from(json['fields'] as Map),
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      isFavorite: json['isFavorite'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  // Helper methods for UI display

  String get typeDescription {
    switch (type) {
      case RecordType.login:
        return 'Website login credentials';
      case RecordType.creditCard:
        return 'Credit or debit card';
      case RecordType.bankAccount:
        return 'Bank account information';
      case RecordType.note:
        return 'Private secure note';
      case RecordType.address:
        return 'Physical address';
      case RecordType.identity:
        return 'Identity document';
      case RecordType.wifi:
        return 'WiFi network credentials';
      case RecordType.software:
        return 'Software license';
      case RecordType.server:
        return 'Server access credentials';
      case RecordType.document:
        return 'Important document';
      case RecordType.membership:
        return 'Membership or subscription';
      case RecordType.vehicle:
        return 'Vehicle information';
    }
  }

  // Get the primary field for display (like username for login, card number for credit card)
  String? get primaryFieldValue {
    switch (type) {
      case RecordType.login:
        return fields['username'] ?? fields['email'];
      case RecordType.creditCard:
        final cardNumber = fields['cardNumber'];
        if (cardNumber != null && cardNumber.length >= 4) {
          return '•••• ${cardNumber.substring(cardNumber.length - 4)}';
        }
        return cardNumber;
      case RecordType.bankAccount:
        final accountNumber = fields['accountNumber'];
        if (accountNumber != null && accountNumber.length >= 4) {
          return '•••• ${accountNumber.substring(accountNumber.length - 4)}';
        }
        return accountNumber;
      case RecordType.address:
        return fields['city'] ?? fields['addressLine1'];
      case RecordType.identity:
        return fields['documentType'] ?? fields['documentNumber'];
      case RecordType.wifi:
        return fields['networkName'];
      case RecordType.software:
        return fields['softwareName'] ?? fields['version'];
      case RecordType.server:
        return fields['serverName'] ?? fields['ipAddress'];
      case RecordType.document:
        return fields['documentType'] ?? fields['documentTitle'];
      case RecordType.membership:
        return fields['organizationName'] ?? fields['membershipType'];
      case RecordType.vehicle:
        return '${fields['vehicleMake'] ?? ''} ${fields['vehicleModel'] ?? ''}'.trim();
      case RecordType.note:
        return notes?.length != null && notes!.length > 50 
            ? '${notes!.substring(0, 50)}...' 
            : notes;
    }
  }

  // Get the secondary field for display
  String? get secondaryFieldValue {
    switch (type) {
      case RecordType.login:
        return fields['url'];
      case RecordType.creditCard:
        return fields['cardholderName'];
      case RecordType.bankAccount:
        return fields['bankName'];
      case RecordType.address:
        return fields['state'] ?? fields['country'];
      case RecordType.identity:
        return fields['expiryDate'];
      case RecordType.wifi:
        return fields['securityType'];
      case RecordType.software:
        return fields['vendor'];
      case RecordType.server:
        return fields['protocol'];
      case RecordType.document:
        return fields['issueDate'];
      case RecordType.membership:
        return fields['expiryDate'];
      case RecordType.vehicle:
        return fields['licensePlate'] ?? fields['year'];
      case RecordType.note:
        return null;
    }
  }

  // Check if record has sensitive fields that should be hidden by default
  bool get hasSensitiveFields {
    switch (type) {
      case RecordType.login:
      case RecordType.creditCard:
      case RecordType.bankAccount:
      case RecordType.wifi:
      case RecordType.server:
      case RecordType.software:
        return true;
      case RecordType.address:
      case RecordType.identity:
      case RecordType.document:
      case RecordType.membership:
      case RecordType.vehicle:
      case RecordType.note:
        return false;
    }
  }

  // Get list of field keys that should be treated as sensitive (hidden/password fields)
  List<String> get sensitiveFieldKeys {
    switch (type) {
      case RecordType.login:
        return ['password', 'twoFactorSecret'];
      case RecordType.creditCard:
        return ['cardNumber', 'cvv', 'pin'];
      case RecordType.bankAccount:
        return ['accountNumber', 'routingNumber'];
      case RecordType.wifi:
        return ['password'];
      case RecordType.server:
        return ['password', 'privateKey'];
      case RecordType.software:
        return ['licenseKey'];
      case RecordType.identity:
        return ['documentNumber'];
      default:
        return [];
    }
  }

  // Check if this record type supports attachments
  bool get supportsAttachments {
    switch (type) {
      case RecordType.identity:
      case RecordType.vehicle:
      case RecordType.document:
      case RecordType.membership:
      case RecordType.creditCard:
      case RecordType.software:
        return true;
      case RecordType.login:
      case RecordType.bankAccount:
      case RecordType.note:
      case RecordType.address:
      case RecordType.wifi:
      case RecordType.server:
        return false;
    }
  }

  // Get attachment count by type
  int get imageAttachmentCount => attachments.where((a) => a.isImage).length;
  int get pdfAttachmentCount => attachments.where((a) => a.isPdf).length;
  
  // Get attachments by type
  List<Attachment> get imageAttachments => attachments.where((a) => a.isImage).toList();
  List<Attachment> get pdfAttachments => attachments.where((a) => a.isPdf).toList();
  
  // Check if record has any attachments
  bool get hasAttachments => attachments.isNotEmpty;
  
  // Get total attachment file size
  int get totalAttachmentSize => attachments.fold(0, (sum, attachment) => sum + attachment.fileSize);
  
  // Get formatted total attachment size
  String get formattedTotalAttachmentSize {
    final totalSize = totalAttachmentSize;
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Record &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        mapEquals(other.fields, fields) &&
        other.notes == notes &&
        other.category == category &&
        other.isFavorite == isFavorite &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        listEquals(other.attachments, attachments);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      type,
      Object.hashAll(fields.entries),
      notes,
      category,
      isFavorite,
      createdAt,
      modifiedAt,
      Object.hashAll(attachments),
    );
  }
}