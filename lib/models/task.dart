class Task {
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
  
  // Additional fields for client portal
  final String? priority;
  final DateTime? dueDate;
  final String? assignedByName;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final List<String>? attachments;
  final String? notes;

  Task({
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
    this.priority,
    this.dueDate,
    this.assignedByName,
    this.tags,
    this.metadata,
    this.attachments,
    this.notes,
  });

  // Factory constructor from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      clientId: json['client_id'],
      title: json['title'],
      mailId: json['mail_id'],
      type: json['type'],
      assignedTo: json['assigned_to'],
      pin: json['pin'] ?? false,
      followupDate: json['followup_date'] != null 
          ? DateTime.parse(json['followup_date']) : null,
      followup: json['followup'] ?? false,
      status: json['status'] ?? 'pending',
      description: json['description'],
      taskGroup: json['task_group'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
      priority: json['priority'],
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date']) : null,
      assignedByName: json['assigned_by_name'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) : null,
      metadata: json['metadata'],
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments']) : null,
      notes: json['notes'],
    );
  }

  // Convert to JSON
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
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'assigned_by_name': assignedByName,
      'tags': tags,
      'metadata': metadata,
      'attachments': attachments,
      'notes': notes,
    };
  }

  // Copy with method
  Task copyWith({
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
    String? priority,
    DateTime? dueDate,
    String? assignedByName,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    String? notes,
  }) {
    return Task(
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
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignedByName: assignedByName ?? this.assignedByName,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
    );
  }

  // Get status color
  String get statusColor {
    switch (status?.toLowerCase()) {
      case 'pending':
        return '#F39C12'; // Orange
      case 'in_progress':
        return '#3498DB'; // Blue
      case 'completed':
        return '#27AE60'; // Green
      case 'cancelled':
        return '#E74C3C'; // Red
      case 'on_hold':
        return '#9B59B6'; // Purple
      case 'deferred':
        return '#95A5A6'; // Gray
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get priority color
  String get priorityColor {
    switch (priority?.toLowerCase()) {
      case 'high':
        return '#E74C3C'; // Red
      case 'medium':
        return '#F39C12'; // Orange
      case 'low':
        return '#27AE60'; // Green
      case 'urgent':
        return '#C0392B'; // Dark Red
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Check if task is pending
  bool get isPending {
    return status?.toLowerCase() == 'pending';
  }

  // Check if task is in progress
  bool get isInProgress {
    return status?.toLowerCase() == 'in_progress';
  }

  // Check if task is completed
  bool get isCompleted {
    return status?.toLowerCase() == 'completed';
  }

  // Check if task is cancelled
  bool get isCancelled {
    return status?.toLowerCase() == 'cancelled';
  }

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now()) && !isCompleted;
  }

  // Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
           dueDate!.month == now.month &&
           dueDate!.day == now.day;
  }

  // Check if task is due tomorrow
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
           dueDate!.month == tomorrow.month &&
           dueDate!.day == tomorrow.day;
  }

  // Check if task is urgent
  bool get isUrgent {
    return priority?.toLowerCase() == 'high' || 
           priority?.toLowerCase() == 'urgent' ||
           isOverdue ||
           (dueDate != null && 
            dueDate!.difference(DateTime.now()).inDays <= 1);
  }

  // Get due date formatted
  String get dueDateFormatted {
    if (dueDate == null) return 'No due date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDueDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    
    if (taskDueDate == today) {
      return 'Due today';
    } else if (taskDueDate == today.add(const Duration(days: 1))) {
      return 'Due tomorrow';
    } else if (taskDueDate.isBefore(today)) {
      return 'Overdue by ${today.difference(taskDueDate).inDays} days';
    } else {
      final difference = taskDueDate.difference(today).inDays;
      if (difference <= 7) {
        return 'Due in $difference days';
      } else {
        return 'Due ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
      }
    }
  }

  // Get follow-up date formatted
  String get followupDateFormatted {
    if (followupDate == null) return 'No follow-up date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final followupTaskDate = DateTime(followupDate!.year, followupDate!.month, followupDate!.day);
    
    if (followupTaskDate == today) {
      return 'Follow-up today';
    } else if (followupTaskDate == today.add(const Duration(days: 1))) {
      return 'Follow-up tomorrow';
    } else if (followupTaskDate.isBefore(today)) {
      return 'Follow-up overdue by ${today.difference(followupTaskDate).inDays} days';
    } else {
      final difference = followupTaskDate.difference(today).inDays;
      if (difference <= 7) {
        return 'Follow-up in $difference days';
      } else {
        return 'Follow-up ${followupDate!.day}/${followupDate!.month}/${followupDate!.year}';
      }
    }
  }

  // Get task age in days
  int get taskAge {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Get days remaining until due
  int? get daysRemaining {
    if (dueDate == null) return null;
    final remaining = dueDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  // Get display title
  String get displayTitle {
    return title ?? 'Untitled Task';
  }

  // Get display description
  String get displayDescription {
    return description ?? notes ?? 'No description available';
  }

  // Get display type
  String get displayType {
    return type ?? 'General';
  }

  // Get display group
  String get displayGroup {
    return taskGroup ?? 'Uncategorized';
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, dueDate: $dueDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
