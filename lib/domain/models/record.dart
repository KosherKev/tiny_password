import 'package:flutter/foundation.dart';

enum RecordType {
  login,
  creditCard,
  bankAccount,
  note,
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
    );
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
        other.modifiedAt == modifiedAt;
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
    );
  }
}