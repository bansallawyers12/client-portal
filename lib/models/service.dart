class Service {
  final int id;
  final String title;
  final int? parent;
  final String description;
  final String? servicesIcon;
  final String? servicesImage;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for client portal
  final String? category;
  final double? price;
  final String? currency;
  final int? duration;
  final String? durationUnit;
  final List<String>? features;
  final List<String>? requirements;
  final Map<String, dynamic>? metadata;

  Service({
    required this.id,
    required this.title,
    this.parent,
    required this.description,
    this.servicesIcon,
    this.servicesImage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.price,
    this.currency,
    this.duration,
    this.durationUnit,
    this.features,
    this.requirements,
    this.metadata,
  });

  // Factory constructor from JSON
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      parent: json['parent'],
      description: json['description'] ?? '',
      servicesIcon: json['services_icon'],
      servicesImage: json['services_image'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
      category: json['category'],
      price: json['price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      duration: json['duration'],
      durationUnit: json['duration_unit'],
      features: json['features'] != null 
          ? List<String>.from(json['features']) : null,
      requirements: json['requirements'] != null 
          ? List<String>.from(json['requirements']) : null,
      metadata: json['metadata'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'parent': parent,
      'description': description,
      'services_icon': servicesIcon,
      'services_image': servicesImage,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category,
      'price': price,
      'currency': currency,
      'duration': duration,
      'duration_unit': durationUnit,
      'features': features,
      'requirements': requirements,
      'metadata': metadata,
    };
  }

  // Copy with method
  Service copyWith({
    int? id,
    String? title,
    int? parent,
    String? description,
    String? servicesIcon,
    String? servicesImage,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    double? price,
    String? currency,
    int? duration,
    String? durationUnit,
    List<String>? features,
    List<String>? requirements,
    Map<String, dynamic>? metadata,
  }) {
    return Service(
      id: id ?? this.id,
      title: title ?? this.title,
      parent: parent ?? this.parent,
      description: description ?? this.description,
      servicesIcon: servicesIcon ?? this.servicesIcon,
      servicesImage: servicesImage ?? this.servicesImage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      duration: duration ?? this.duration,
      durationUnit: durationUnit ?? this.durationUnit,
      features: features ?? this.features,
      requirements: requirements ?? this.requirements,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return '#27AE60'; // Green
      case 'inactive':
        return '#95A5A6'; // Gray
      case 'pending':
        return '#F39C12'; // Orange
      case 'discontinued':
        return '#E74C3C'; // Red
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Check if service is active
  bool get isActive {
    return status.toLowerCase() == 'active';
  }

  // Check if service is inactive
  bool get isInactive {
    return status.toLowerCase() == 'inactive';
  }

  // Check if service is pending
  bool get isPending {
    return status.toLowerCase() == 'pending';
  }

  // Check if service is discontinued
  bool get isDiscontinued {
    return status.toLowerCase() == 'discontinued';
  }

  // Check if service is free
  bool get isFree {
    return price == null || price == 0;
  }

  // Check if service has parent
  bool get hasParent {
    return parent != null;
  }

  // Check if service has features
  bool get hasFeatures {
    return features != null && features!.isNotEmpty;
  }

  // Check if service has requirements
  bool get hasRequirements {
    return requirements != null && requirements!.isNotEmpty;
  }

  // Get price formatted
  String get priceFormatted {
    if (isFree) return 'Free';
    if (price == null) return 'Price not set';
    return '\$${price!.toStringAsFixed(2)}';
  }

  // Get duration formatted
  String get durationFormatted {
    if (duration == null) return 'Duration not specified';
    
    final unit = durationUnit?.toLowerCase() ?? 'hour';
    if (duration == 1) {
      return '1 $unit';
    } else {
      return '$duration ${unit}s';
    }
  }

  // Get display title
  String get displayTitle {
    return title;
  }

  // Get display description
  String get displayDescription {
    return description;
  }

  // Get display category
  String get displayCategory {
    return category ?? 'General';
  }

  // Get display status
  String get displayStatus {
    return status;
  }

  // Get display currency
  String get displayCurrency {
    return currency ?? 'USD';
  }

  // Get short description
  String get shortDescription {
    if (description.length <= 100) {
      return description;
    } else {
      return '${description.substring(0, 100)}...';
    }
  }

  // Get feature count
  int get featureCount {
    return features?.length ?? 0;
  }

  // Get requirement count
  int get requirementCount {
    return requirements?.length ?? 0;
  }

  // Get service age in days
  int get serviceAge {
    return DateTime.now().difference(createdAt).inDays;
  }

  // Check if service is new (less than 30 days old)
  bool get isNew {
    return serviceAge < 30;
  }

  // Check if service is popular (more than 100 days old)
  bool get isPopular {
    return serviceAge > 100;
  }

  @override
  String toString() {
    return 'Service(id: $id, title: $title, status: $status, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
