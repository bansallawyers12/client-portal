class Admin {
  final int id;
  final String clientId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int role;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for client portal
  final String? avatar;
  final String? department;
  final String? position;
  final String? bio;
  final List<String>? specializations;
  final Map<String, dynamic>? metadata;

  Admin({
    required this.id,
    required this.clientId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.avatar,
    this.department,
    this.position,
    this.bio,
    this.specializations,
    this.metadata,
  });

  // Factory constructor from JSON
  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? 0,
      clientId: json['client_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 0,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
      avatar: json['avatar'],
      department: json['department'],
      position: json['position'],
      bio: json['bio'],
      specializations: json['specializations'] != null 
          ? List<String>.from(json['specializations']) : null,
      metadata: json['metadata'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'avatar': avatar,
      'department': department,
      'position': position,
      'bio': bio,
      'specializations': specializations,
      'metadata': metadata,
    };
  }

  // Copy with method
  Admin copyWith({
    int? id,
    String? clientId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    int? role,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatar,
    String? department,
    String? position,
    String? bio,
    List<String>? specializations,
    Map<String, dynamic>? metadata,
  }) {
    return Admin(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatar: avatar ?? this.avatar,
      department: department ?? this.department,
      position: position ?? this.position,
      bio: bio ?? this.bio,
      specializations: specializations ?? this.specializations,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get full name
  String get fullName {
    return '$firstName $lastName';
  }

  // Get display name
  String get displayName {
    return fullName;
  }

  // Get initials
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    }
    return '?';
  }

  // Get role name
  String get roleName {
    switch (role) {
      case 1:
        return 'Super Admin';
      case 2:
        return 'Admin';
      case 3:
        return 'Manager';
      case 4:
        return 'Agent';
      case 5:
        return 'Support';
      case 6:
        return 'Viewer';
      case 7:
        return 'Client';
      default:
        return 'Unknown';
    }
  }

  // Get role color
  String get roleColor {
    switch (role) {
      case 1:
        return '#E74C3C'; // Red
      case 2:
        return '#F39C12'; // Orange
      case 3:
        return '#9B59B6'; // Purple
      case 4:
        return '#3498DB'; // Blue
      case 5:
        return '#27AE60'; // Green
      case 6:
        return '#95A5A6'; // Gray
      case 7:
        return '#5E8B7E'; // Primary
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return '#27AE60'; // Green
      case 'inactive':
        return '#95A5A6'; // Gray
      case 'suspended':
        return '#E74C3C'; // Red
      case 'pending':
        return '#F39C12'; // Orange
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Check if admin is super admin
  bool get isSuperAdmin {
    return role == 1;
  }

  // Check if admin is admin
  bool get isAdmin {
    return role <= 2;
  }

  // Check if admin is manager
  bool get isManager {
    return role <= 3;
  }

  // Check if admin is agent
  bool get isAgent {
    return role <= 4;
  }

  // Check if admin is support
  bool get isSupport {
    return role <= 5;
  }

  // Check if admin is viewer
  bool get isViewer {
    return role <= 6;
  }

  // Check if admin is client
  bool get isClient {
    return role == 7;
  }

  // Check if admin is active
  bool get isActive {
    return status.toLowerCase() == 'active';
  }

  // Check if admin is inactive
  bool get isInactive {
    return status.toLowerCase() == 'inactive';
  }

  // Check if admin is suspended
  bool get isSuspended {
    return status.toLowerCase() == 'suspended';
  }

  // Check if admin is pending
  bool get isPending {
    return status.toLowerCase() == 'pending';
  }

  // Check if admin has avatar
  bool get hasAvatar {
    return avatar != null && avatar!.isNotEmpty;
  }

  // Check if admin has department
  bool get hasDepartment {
    return department != null && department!.isNotEmpty;
  }

  // Check if admin has position
  bool get hasPosition {
    return position != null && position!.isNotEmpty;
  }

  // Check if admin has bio
  bool get hasBio {
    return bio != null && bio!.isNotEmpty;
  }

  // Check if admin has specializations
  bool get hasSpecializations {
    return specializations != null && specializations!.isNotEmpty;
  }

  // Get specialization count
  int get specializationCount {
    return specializations?.length ?? 0;
  }

  // Get admin age in days
  int get adminAge {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Check if admin is new (less than 30 days old)
  bool get isNew {
    return adminAge < 30;
  }

  // Check if admin is experienced (more than 365 days old)
  bool get isExperienced {
    return adminAge > 365;
  }

  // Get short bio
  String get shortBio {
    if (!hasBio) return 'No bio available';
    
    if (bio!.length <= 100) {
      return bio!;
    } else {
      return '${bio!.substring(0, 100)}...';
    }
  }

  // Get display department
  String get displayDepartment {
    return department ?? 'No department';
  }

  // Get display position
  String get displayPosition {
    return position ?? 'No position';
  }

  // Get display status
  String get displayStatus {
    return status;
  }

  // Get display role
  String get displayRole {
    return roleName;
  }

  // Get contact info
  String get contactInfo {
    final parts = <String>[];
    if (email.isNotEmpty) parts.add(email);
    if (phone.isNotEmpty) parts.add(phone);
    return parts.join(' • ');
  }

  @override
  String toString() {
    return 'Admin(id: $id, name: $fullName, role: $roleName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Admin && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
