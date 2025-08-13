class Message {
  final int id;
  final String? subject;
  final String? message;
  final String? sender;
  final String? recipient;
  final int? senderId;
  final int? recipientId;
  final DateTime? sentAt;
  final DateTime? readAt;
  final bool isRead;
  final String? messageType;
  final int? caseId;
  final int? taskId;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    this.subject,
    this.message,
    this.sender,
    this.recipient,
    this.senderId,
    this.recipientId,
    this.sentAt,
    this.readAt,
    this.isRead = false,
    this.messageType,
    this.caseId,
    this.taskId,
    this.attachments,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      subject: json['subject'],
      message: json['message'],
      sender: json['sender'],
      recipient: json['recipient'],
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      sentAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at']) : null,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at']) : null,
      isRead: json['read'] ?? false,
      messageType: json['message_type'],
      caseId: json['case_id'],
      taskId: json['task_id'],
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments']) : null,
      metadata: json['metadata'],
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
      'subject': subject,
      'message': message,
      'sender': sender,
      'recipient': recipient,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'read': isRead,
      'message_type': messageType,
      'case_id': caseId,
      'task_id': taskId,
      'attachments': attachments,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Message copyWith({
    int? id,
    String? subject,
    String? message,
    String? sender,
    String? recipient,
    int? senderId,
    int? recipientId,
    DateTime? sentAt,
    DateTime? readAt,
    bool? isRead,
    String? messageType,
    int? caseId,
    int? taskId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      caseId: caseId ?? this.caseId,
      taskId: taskId ?? this.taskId,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get sender color
  String get senderColor {
    switch (sender?.toLowerCase()) {
      case 'admin':
        return '#5E8B7E'; // Primary color
      case 'lawyer':
        return '#30475E'; // Secondary color
      case 'system':
        return '#F39C12'; // Accent color
      case 'client':
        return '#3498DB'; // Info color
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get message type color
  String get messageTypeColor {
    switch (messageType?.toLowerCase()) {
      case 'urgent':
        return '#E74C3C'; // Red
      case 'important':
        return '#F39C12'; // Orange
      case 'normal':
        return '#27AE60'; // Green
      case 'low_priority':
        return '#95A5A6'; // Gray
      default:
        return '#3498DB'; // Blue
    }
  }

  // Check if message is urgent
  bool get isUrgent {
    return messageType?.toLowerCase() == 'urgent';
  }

  // Check if message is important
  bool get isImportant {
    return messageType?.toLowerCase() == 'important';
  }

  // Check if message has attachments
  bool get hasAttachments {
    return attachments != null && attachments!.isNotEmpty;
  }

  // Check if message is from system
  bool get isFromSystem {
    return sender?.toLowerCase() == 'system';
  }

  // Check if message is from admin
  bool get isFromAdmin {
    return sender?.toLowerCase() == 'admin';
  }

  // Check if message is from lawyer
  bool get isFromLawyer {
    return sender?.toLowerCase() == 'lawyer';
  }

  // Check if message is from client
  bool get isFromClient {
    return sender?.toLowerCase() == 'client';
  }

  // Get message age in human readable format
  String get messageAge {
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
    
    if (message!.length <= 100) {
      return message!;
    } else {
      return '${message!.substring(0, 100)}...';
    }
  }

  // Get display subject
  String get displaySubject {
    return subject ?? 'No Subject';
  }

  // Get display sender
  String get displaySender {
    return sender ?? 'Unknown Sender';
  }

  // Get display recipient
  String get displayRecipient {
    return recipient ?? 'Unknown Recipient';
  }

  // Get display message
  String get displayMessage {
    return message ?? 'No message content';
  }

  // Get attachment count
  int get attachmentCount {
    return attachments?.length ?? 0;
  }

  // Get attachment count text
  String get attachmentCountText {
    final count = attachmentCount;
    if (count == 0) return '';
    if (count == 1) return '1 attachment';
    return '$count attachments';
  }

  @override
  String toString() {
    return 'Message(id: $id, subject: $subject, sender: $sender, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
