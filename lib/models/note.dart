import 'package:flutter/foundation.dart';

@immutable
class Note {
  final int id;
  final int? userId;
  final int? clientId;
  final String? title;
  final String? mailId;
  final String? type;
  final int? assignedTo;
  final bool? pin;
  final DateTime? followupDate;
  final bool? followup;
  final String? status;
  final String? description;
  final String? taskGroup;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    this.userId,
    this.clientId,
    this.title,
    this.mailId,
    this.type,
    this.assignedTo,
    this.pin,
    this.followupDate,
    this.followup,
    this.status,
    this.description,
    this.taskGroup,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    int? id,
    int? userId,
    int? clientId,
    String? title,
    String? mailId,
    String? type,
    int? assignedTo,
    bool? pin,
    DateTime? followupDate,
    bool? followup,
    String? status,
    String? description,
    String? taskGroup,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      mailId: mailId ?? this.mailId,
      type: type ?? this.type,
      assignedTo: assignedTo ?? this.assignedTo,
      pin: pin ?? this.pin,
      followupDate: followupDate ?? this.followupDate,
      followup: followup ?? this.followup,
      status: status ?? this.status,
      description: description ?? this.description,
      taskGroup: taskGroup ?? this.taskGroup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'title': title,
      'mail_id': mailId,
      'type': type,
      'assigned_to': assignedTo,
      'pin': pin,
      'followup_date': followupDate?.toIso8601String(),
      'followup': followup,
      'status': status,
      'description': description,
      'task_group': taskGroup,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      clientId: json['client_id'] as int?,
      title: json['title'] as String?,
      mailId: json['mail_id'] as String?,
      type: json['type'] as String?,
      assignedTo: json['assigned_to'] as int?,
      pin: json['pin'] as bool?,
      followupDate:
          json['followup_date'] != null
              ? DateTime.parse(json['followup_date'] as String)
              : null,
      followup: json['followup'] as bool?,
      status: json['status'] as String?,
      description: json['description'] as String?,
      taskGroup: json['task_group'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, type: $type, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.userId == userId &&
        other.clientId == clientId &&
        other.title == title &&
        other.mailId == mailId &&
        other.type == type &&
        other.assignedTo == assignedTo &&
        other.pin == pin &&
        other.followupDate == followupDate &&
        other.followup == followup &&
        other.status == status &&
        other.description == description &&
        other.taskGroup == taskGroup &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      clientId,
      title,
      mailId,
      type,
      assignedTo,
      pin,
      followupDate,
      followup,
      status,
      description,
      taskGroup,
      createdAt,
      updatedAt,
    );
  }
}
