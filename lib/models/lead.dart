class Lead {
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
  final String? leadNumber;
  final String? leadType;
  final String? description;
  final String? source;
  final String? priority;
  final double? estimatedValue;
  final String? currency;
  final DateTime? expectedCloseDate;
  final String? notes;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  Lead({
    required this.id,
    required this.name,
    required this.status,
    this.packageId,
    this.userId,
    this.agentId,
    this.assignTo,
    required this.createdAt,
    required this.updatedAt,
    this.leadNumber,
    this.leadType,
    this.description,
    this.source,
    this.priority,
    this.estimatedValue,
    this.currency,
    this.expectedCloseDate,
    this.notes,
    this.tags,
    this.metadata,
  });

  // Factory constructor from JSON
  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
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
      leadNumber: json['lead_number'],
      leadType: json['lead_type'],
      description: json['description'],
      source: json['source'],
      priority: json['priority'],
      estimatedValue: json['estimated_value']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      expectedCloseDate: json['expected_close_date'] != null 
          ? DateTime.parse(json['expected_close_date']) : null,
      notes: json['notes'],
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
      'lead_number': leadNumber,
      'lead_type': leadType,
      'description': description,
      'source': source,
      'priority': priority,
      'estimated_value': estimatedValue,
      'currency': currency,
      'expected_close_date': expectedCloseDate?.toIso8601String(),
      'notes': notes,
      'tags': tags,
      'metadata': metadata,
    };
  }

  // Copy with method
  Lead copyWith({
    int? id,
    String? name,
    String? status,
    int? packageId,
    int? userId,
    int? agentId,
    int? assignTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? leadNumber,
    String? leadType,
    String? description,
    String? source,
    String? priority,
    double? estimatedValue,
    String? currency,
    DateTime? expectedCloseDate,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Lead(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      packageId: packageId ?? this.packageId,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      assignTo: assignTo ?? this.assignTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      leadNumber: leadNumber ?? this.leadNumber,
      leadType: leadType ?? this.leadType,
      description: description ?? this.description,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      currency: currency ?? this.currency,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'new':
        return '#3498DB'; // Blue
      case 'contacted':
        return '#F39C12'; // Orange
      case 'qualified':
        return '#27AE60'; // Green
      case 'proposal':
        return '#9B59B6'; // Purple
      case 'negotiation':
        return '#F1C40F'; // Yellow
      case 'closed_won':
        return '#27AE60'; // Green
      case 'closed_lost':
        return '#E74C3C'; // Red
      case 'junk':
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

  // Check if lead is new
  bool get isNew {
    return status.toLowerCase() == 'new';
  }

  // Check if lead is contacted
  bool get isContacted {
    return status.toLowerCase() == 'contacted';
  }

  // Check if lead is qualified
  bool get isQualified {
    return status.toLowerCase() == 'qualified';
  }

  // Check if lead is in proposal stage
  bool get isProposal {
    return status.toLowerCase() == 'proposal';
  }

  // Check if lead is in negotiation
  bool get isNegotiation {
    return status.toLowerCase() == 'negotiation';
  }

  // Check if lead is closed won
  bool get isClosedWon {
    return status.toLowerCase() == 'closed_won';
  }

  // Check if lead is closed lost
  bool get isClosedLost {
    return status.toLowerCase() == 'closed_lost';
  }

  // Check if lead is junk
  bool get isJunk {
    return status.toLowerCase() == 'junk';
  }

  // Check if lead is active
  bool get isActive {
    return !['closed_won', 'closed_lost', 'junk'].contains(status.toLowerCase());
  }

  // Check if lead is closed
  bool get isClosed {
    return ['closed_won', 'closed_lost'].contains(status.toLowerCase());
  }

  // Check if lead is urgent
  bool get isUrgent {
    return priority?.toLowerCase() == 'high' || 
           priority?.toLowerCase() == 'urgent';
  }

  // Check if lead has expected close date
  bool get hasExpectedCloseDate {
    return expectedCloseDate != null;
  }

  // Check if lead is overdue
  bool get isOverdue {
    if (expectedCloseDate == null || isClosed) return false;
    return expectedCloseDate!.isBefore(DateTime.now());
  }

  // Check if lead is due today
  bool get isDueToday {
    if (expectedCloseDate == null) return false;
    final now = DateTime.now();
    return expectedCloseDate!.year == now.year &&
           expectedCloseDate!.month == now.month &&
           expectedCloseDate!.day == now.day;
  }

  // Check if lead is due soon (within 7 days)
  bool get isDueSoon {
    if (expectedCloseDate == null || isClosed) return false;
    final now = DateTime.now();
    final difference = expectedCloseDate!.difference(now).inDays;
    return difference >= 0 && difference <= 7;
  }

  // Get expected close date formatted
  String get expectedCloseDateFormatted {
    if (expectedCloseDate == null) return 'No close date set';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final leadCloseDate = DateTime(expectedCloseDate!.year, expectedCloseDate!.month, expectedCloseDate!.day);
    
    if (leadCloseDate == today) {
      return 'Due today';
    } else if (leadCloseDate == today.add(const Duration(days: 1))) {
      return 'Due tomorrow';
    } else if (leadCloseDate.isBefore(today)) {
      return 'Overdue by ${today.difference(leadCloseDate).inDays} days';
    } else {
      final difference = leadCloseDate.difference(today).inDays;
      if (difference <= 7) {
        return 'Due in $difference days';
      } else {
        return 'Due ${expectedCloseDate!.day}/${expectedCloseDate!.month}/${expectedCloseDate!.year}';
      }
    }
  }

  // Get estimated value formatted
  String get estimatedValueFormatted {
    if (estimatedValue == null) return 'N/A';
    return '\$${estimatedValue!.toStringAsFixed(2)}';
  }

  // Get lead age in days
  int get leadAge {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Check if lead is fresh (less than 7 days old)
  bool get isFresh {
    return leadAge < 7;
  }

  // Check if lead is mature (more than 30 days old)
  bool get isMature {
    return leadAge > 30;
  }

  // Get days until expected close
  int? get daysUntilClose {
    if (expectedCloseDate == null || isClosed) return null;
    final now = DateTime.now();
    final difference = expectedCloseDate!.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Get days overdue
  int? get daysOverdue {
    if (expectedCloseDate == null || isClosed) return null;
    if (!isOverdue) return null;
    final now = DateTime.now();
    return now.difference(expectedCloseDate!).inDays;
  }

  // Get short description
  String get shortDescription {
    if (description == null || description!.isEmpty) return 'No description';
    
    if (description!.length <= 100) {
      return description!;
    } else {
      return '${description!.substring(0, 100)}...';
    }
  }

  // Get display lead number
  String get displayLeadNumber {
    return leadNumber ?? 'LEAD-${id.toString().padLeft(6, '0')}';
  }

  // Get display lead type
  String get displayLeadType {
    return leadType ?? 'General';
  }

  // Get display source
  String get displaySource {
    return source ?? 'Unknown';
  }

  // Get display priority
  String get displayPriority {
    return priority ?? 'Medium';
  }

  // Get display status
  String get displayStatus {
    return status;
  }

  // Get display currency
  String get displayCurrency {
    return currency ?? 'USD';
  }

  // Get tag count
  int get tagCount {
    return tags?.length ?? 0;
  }

  @override
  String toString() {
    return 'Lead(id: $id, name: $name, status: $status, estimatedValue: $estimatedValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lead && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
