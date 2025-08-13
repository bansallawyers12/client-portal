class Notification {
  final int id;
  final String? title;
  final String? message;
  final String? type;
  final String? category;
  final int? userId;
  final int? clientId;
  final int? caseId;
  final int? taskId;
  final int? documentId;
  final int? appointmentId;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    this.title,
    this.message,
    this.type,
    this.category,
    this.userId,
    this.clientId,
    this.caseId,
    this.taskId,
    this.documentId,
    this.appointmentId,
    this.isRead = false,
    this.readAt,
    this.actionUrl,
    this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from JSON
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? 0,
      title: json['title'],
      message: json['message'],
      type: json['type'],
      category: json['category'],
      userId: json['user_id'],
      clientId: json['client_id'],
      caseId: json['case_id'],
      taskId: json['task_id'],
      documentId: json['document_id'],
      appointmentId: json['appointment_id'],
      isRead: json['read'] ?? false,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at']) : null,
      actionUrl: json['action_url'],
      data: json['data'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'category': category,
      'user_id': userId,
      'client_id': clientId,
      'case_id': caseId,
      'task_id': taskId,
      'document_id': documentId,
      'appointment_id': appointmentId,
      'read': isRead,
      'read_at': readAt?.toIso8601String(),
      'action_url': actionUrl,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Notification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? category,
    int? userId,
    int? clientId,
    int? caseId,
    int? taskId,
    int? documentId,
    int? appointmentId,
    bool? isRead,
    DateTime? readAt,
    String? actionUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      caseId: caseId ?? this.caseId,
      taskId: taskId ?? this.taskId,
      documentId: documentId ?? this.documentId,
      appointmentId: appointmentId ?? this.appointmentId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get type color
  String get typeColor {
    switch (type?.toLowerCase()) {
      case 'urgent':
        return '#E74C3C'; // Red
      case 'important':
        return '#F39C12'; // Orange
      case 'info':
        return '#3498DB'; // Blue
      case 'success':
        return '#27AE60'; // Green
      case 'warning':
        return '#F1C40F'; // Yellow
      case 'error':
        return '#C0392B'; // Dark Red
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get category color
  String get categoryColor {
    switch (category?.toLowerCase()) {
      case 'case_update':
        return '#5E8B7E'; // Primary color
      case 'document':
        return '#30475E'; // Secondary color
      case 'appointment':
        return '#F39C12'; // Accent color
      case 'task':
        return '#3498DB'; // Info color
      case 'payment':
        return '#27AE60'; // Success color
      case 'system':
        return '#9B59B6'; // Purple
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get category icon
  String get categoryIcon {
    switch (category?.toLowerCase()) {
      case 'case_update':
        return '📋';
      case 'document':
        return '📄';
      case 'appointment':
        return '📅';
      case 'task':
        return '✅';
      case 'payment':
        return '💰';
      case 'system':
        return '⚙️';
      case 'message':
        return '💬';
      case 'reminder':
        return '⏰';
      default:
        return '🔔';
    }
  }

  // Check if notification is urgent
  bool get isUrgent {
    return type?.toLowerCase() == 'urgent';
  }

  // Check if notification is important
  bool get isImportant {
    return type?.toLowerCase() == 'important';
  }

  // Check if notification is unread
  bool get isUnread {
    return !isRead;
  }

  // Check if notification has action
  bool get hasAction {
    return actionUrl != null && actionUrl!.isNotEmpty;
  }

  // Check if notification is case related
  bool get isCaseRelated {
    return caseId != null;
  }

  // Check if notification is document related
  bool get isDocumentRelated {
    return documentId != null;
  }

  // Check if notification is appointment related
  bool get isAppointmentRelated {
    return appointmentId != null;
  }

  // Check if notification is task related
  bool get isTaskRelated {
    return taskId != null;
  }

  // Get notification age in human readable format
  String get notificationAge {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  // Get short message preview
  String get messagePreview {
    if (message == null || message!.isEmpty) return 'No message content';
    
    if (message!.length <= 80) {
      return message!;
    } else {
      return '${message!.substring(0, 80)}...';
    }
  }

  // Get display title
  String get displayTitle {
    return title ?? 'Notification';
  }

  // Get display message
  String get displayMessage {
    return message ?? 'No message content';
  }

  // Get display type
  String get displayType {
    return type ?? 'General';
  }

  // Get display category
  String get displayCategory {
    return category ?? 'General';
  }

  // Get priority level
  int get priorityLevel {
    switch (type?.toLowerCase()) {
      case 'urgent':
        return 1;
      case 'important':
        return 2;
      case 'warning':
        return 3;
      case 'info':
        return 4;
      case 'success':
        return 5;
      default:
        return 6;
    }
  }

  // Check if notification should show badge
  bool get shouldShowBadge {
    return isUnread && (isUrgent || isImportant);
  }

  @override
  String toString() {
    return 'Notification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
