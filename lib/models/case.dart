class Case {
  final int id;
  final String name;
  final String status;
  final int? packageId;
  final int? userId;
  final int? agentId;
  final int? assignTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for client portal
  final String? caseNumber;
  final String? caseType;
  final String? description;
  final String? priority;
  final DateTime? estimatedCompletion;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  Case({
    required this.id,
    required this.name,
    required this.status,
    this.packageId,
    this.userId,
    this.agentId,
    this.assignTo,
    required this.createdAt,
    required this.updatedAt,
    this.caseNumber,
    this.caseType,
    this.description,
    this.priority,
    this.estimatedCompletion,
    this.tags,
    this.metadata,
  });

  // Factory constructor from JSON
  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      packageId: json['package_id'],
      userId: json['user_id'],
      agentId: json['agent_id'],
      assignTo: json['assign_to'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
      caseNumber: json['case_number'],
      caseType: json['case_type'],
      description: json['description'],
      priority: json['priority'],
      estimatedCompletion: json['estimated_completion'] != null 
          ? DateTime.parse(json['estimated_completion']) : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) : null,
      metadata: json['metadata'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'package_id': packageId,
      'user_id': userId,
      'agent_id': agentId,
      'assign_to': assignTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'case_number': caseNumber,
      'case_type': caseType,
      'description': description,
      'priority': priority,
      'estimated_completion': estimatedCompletion?.toIso8601String(),
      'tags': tags,
      'metadata': metadata,
    };
  }

  // Copy with method
  Case copyWith({
    int? id,
    String? name,
    String? status,
    int? packageId,
    int? userId,
    int? agentId,
    int? assignTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? caseNumber,
    String? caseType,
    String? description,
    String? priority,
    DateTime? estimatedCompletion,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Case(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      packageId: packageId ?? this.packageId,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      assignTo: assignTo ?? this.assignTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      caseNumber: caseNumber ?? this.caseNumber,
      caseType: caseType ?? this.caseType,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#F39C12'; // Orange
      case 'in_progress':
        return '#3498DB'; // Blue
      case 'completed':
        return '#27AE60'; // Green
      case 'cancelled':
        return '#E74C3C'; // Red
      case 'under_review':
        return '#9B59B6'; // Purple
      case 'on_hold':
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
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Check if case is active
  bool get isActive {
    return !['completed', 'cancelled', 'closed'].contains(status.toLowerCase());
  }

  // Check if case is urgent
  bool get isUrgent {
    return priority?.toLowerCase() == 'high' || 
           (estimatedCompletion != null && 
            estimatedCompletion!.difference(DateTime.now()).inDays <= 7);
  }

  // Get case age in days
  int get caseAge {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Get estimated days remaining
  int? get daysRemaining {
    if (estimatedCompletion == null) return null;
    final remaining = estimatedCompletion!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  @override
  String toString() {
    return 'Case(id: $id, name: $name, status: $status, caseNumber: $caseNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Case && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
