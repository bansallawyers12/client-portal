class Document {
  final int id;
  final String? title;
  final String? description;
  final String? filePath;
  final String? fileType;
  final String? status;
  final int? clientId;
  final int? uploadedBy;
  final DateTime? uploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for client portal
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? category;
  final String? urgency;
  final String? notes;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  Document({
    required this.id,
    this.title,
    this.description,
    this.filePath,
    this.fileType,
    this.status,
    this.clientId,
    this.uploadedBy,
    this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.category,
    this.urgency,
    this.notes,
    this.tags,
    this.metadata,
  });

  // Factory constructor from JSON
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] ?? 0,
      title: json['title'],
      description: json['description'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      status: json['status'] ?? 'pending',
      clientId: json['client_id'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: json['uploaded_at'] != null 
          ? DateTime.parse(json['uploaded_at']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
      fileName: json['file_name'],
      fileSize: json['file_size'],
      mimeType: json['mime_type'],
      category: json['category'],
      urgency: json['urgency'],
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
      'title': title,
      'description': description,
      'file_path': filePath,
      'file_type': fileType,
      'status': status,
      'client_id': clientId,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'category': category,
      'urgency': urgency,
      'notes': notes,
      'tags': tags,
      'metadata': metadata,
    };
  }

  // Copy with method
  Document copyWith({
    int? id,
    String? title,
    String? description,
    String? filePath,
    String? fileType,
    String? status,
    int? clientId,
    int? uploadedBy,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? category,
    String? urgency,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      category: category ?? this.category,
      urgency: urgency ?? this.urgency,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get status color
  String get statusColor {
    switch (status?.toLowerCase()) {
      case 'pending':
        return '#F39C12'; // Orange
      case 'approved':
        return '#27AE60'; // Green
      case 'rejected':
        return '#E74C3C'; // Red
      case 'under_review':
        return '#9B59B6'; // Purple
      case 'processing':
        return '#3498DB'; // Blue
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get urgency color
  String get urgencyColor {
    switch (urgency?.toLowerCase()) {
      case 'critical':
        return '#E74C3C'; // Red
      case 'high':
        return '#F39C12'; // Orange
      case 'medium':
        return '#F1C40F'; // Yellow
      case 'low':
        return '#27AE60'; // Green
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    
    if (fileSize! < 1024) {
      return '${fileSize}B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    } else if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  // Get file icon based on type
  String get fileIcon {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return '🖼️';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'ppt':
      case 'pptx':
        return '📈';
      case 'zip':
      case 'rar':
        return '📦';
      default:
        return '📎';
    }
  }

  // Check if document is approved
  bool get isApproved {
    return status?.toLowerCase() == 'approved';
  }

  // Check if document is pending
  bool get isPending {
    return status?.toLowerCase() == 'pending';
  }

  // Check if document is rejected
  bool get isRejected {
    return status?.toLowerCase() == 'rejected';
  }

  // Check if document is under review
  bool get isUnderReview {
    return status?.toLowerCase() == 'under_review';
  }

  // Check if document is urgent
  bool get isUrgent {
    return urgency?.toLowerCase() == 'critical' || 
           urgency?.toLowerCase() == 'high';
  }

  // Get display title
  String get displayTitle {
    return title ?? fileName ?? 'Untitled Document';
  }

  // Get display description
  String get displayDescription {
    return description ?? notes ?? 'No description available';
  }

  @override
  String toString() {
    return 'Document(id: $id, title: $title, status: $status, fileName: $fileName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
