class Appointment {
  final int id;
  final int? userId;
  final int? clientId;
  final String? clientUniqueId;
  final String? timezone;
  final String? email;
  final int? noeId;
  final int? serviceId;
  final int? assignee;
  final String? fullName;
  final DateTime? date;
  final String? time;
  final String? title;
  final String? description;
  final int? invites;
  final String? status;
  final String? relatedTo;
  final String? preferredLanguage;
  final String? inpersonAddress;
  final String? timeslotFull;
  final String? appointmentDetails;
  final String? orderHash;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for client portal
  final int? duration;
  final String? location;
  final String? notes;
  final String? serviceName;
  final String? staffName;
  final List<String>? attendees;
  final Map<String, dynamic>? metadata;

  Appointment({
    required this.id,
    this.userId,
    this.clientId,
    this.clientUniqueId,
    this.timezone,
    this.email,
    this.noeId,
    this.serviceId,
    this.assignee,
    this.fullName,
    this.date,
    this.time,
    this.title,
    this.description,
    this.invites,
    this.status,
    this.relatedTo,
    this.preferredLanguage,
    this.inpersonAddress,
    this.timeslotFull,
    this.appointmentDetails,
    this.orderHash,
    required this.createdAt,
    required this.updatedAt,
    this.duration,
    this.location,
    this.notes,
    this.serviceName,
    this.staffName,
    this.attendees,
    this.metadata,
  });

  // Factory constructor from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      clientId: json['client_id'],
      clientUniqueId: json['client_unique_id'],
      timezone: json['timezone'],
      email: json['email'],
      noeId: json['noe_id'],
      serviceId: json['service_id'],
      assignee: json['assignee'],
      fullName: json['full_name'],
      date: json['appointment_date'] != null 
          ? DateTime.parse(json['appointment_date']) : null,
      time: json['appointment_time'],
      title: json['title'],
      description: json['description'],
      invites: json['invites'],
      status: json['status'] ?? 'pending',
      relatedTo: json['related_to'],
      preferredLanguage: json['preferred_language'],
      inpersonAddress: json['inperson_address'],
      timeslotFull: json['timeslot_full'],
      appointmentDetails: json['appointment_details'],
      orderHash: json['order_hash'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
      duration: json['duration'],
      location: json['location'],
      notes: json['notes'],
      serviceName: json['service_name'],
      staffName: json['staff_name'],
      attendees: json['attendees'] != null 
          ? List<String>.from(json['attendees']) : null,
      metadata: json['metadata'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'client_unique_id': clientUniqueId,
      'timezone': timezone,
      'email': email,
      'noe_id': noeId,
      'service_id': serviceId,
      'assignee': assignee,
      'full_name': fullName,
      'appointment_date': date?.toIso8601String(),
      'appointment_time': time,
      'title': title,
      'description': description,
      'invites': invites,
      'status': status,
      'related_to': relatedTo,
      'preferred_language': preferredLanguage,
      'inperson_address': inpersonAddress,
      'timeslot_full': timeslotFull,
      'appointment_details': appointmentDetails,
      'order_hash': orderHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'duration': duration,
      'location': location,
      'notes': notes,
      'service_name': serviceName,
      'staff_name': staffName,
      'attendees': attendees,
      'metadata': metadata,
    };
  }

  // Copy with method
  Appointment copyWith({
    int? id,
    int? userId,
    int? clientId,
    String? clientUniqueId,
    String? timezone,
    String? email,
    int? noeId,
    int? serviceId,
    int? assignee,
    String? fullName,
    DateTime? date,
    String? time,
    String? title,
    String? description,
    int? invites,
    String? status,
    String? relatedTo,
    String? preferredLanguage,
    String? inpersonAddress,
    String? timeslotFull,
    String? appointmentDetails,
    String? orderHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? duration,
    String? location,
    String? notes,
    String? serviceName,
    String? staffName,
    List<String>? attendees,
    Map<String, dynamic>? metadata,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      clientUniqueId: clientUniqueId ?? this.clientUniqueId,
      timezone: timezone ?? this.timezone,
      email: email ?? this.email,
      noeId: noeId ?? this.noeId,
      serviceId: serviceId ?? this.serviceId,
      assignee: assignee ?? this.assignee,
      fullName: fullName ?? this.fullName,
      date: date ?? this.date,
      time: time ?? this.time,
      title: title ?? this.title,
      description: description ?? this.description,
      invites: invites ?? this.invites,
      status: status ?? this.status,
      relatedTo: relatedTo ?? this.relatedTo,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      inpersonAddress: inpersonAddress ?? this.inpersonAddress,
      timeslotFull: timeslotFull ?? this.timeslotFull,
      appointmentDetails: appointmentDetails ?? this.appointmentDetails,
      orderHash: orderHash ?? this.orderHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      serviceName: serviceName ?? this.serviceName,
      staffName: staffName ?? this.staffName,
      attendees: attendees ?? this.attendees,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get status color
  String get statusColor {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return '#27AE60'; // Green
      case 'pending':
        return '#F39C12'; // Orange
      case 'cancelled':
        return '#E74C3C'; // Red
      case 'rescheduled':
        return '#9B59B6'; // Purple
      case 'completed':
        return '#3498DB'; // Blue
      case 'no_show':
        return '#95A5A6'; // Gray
      default:
        return '#95A5A6'; // Gray
    }
  }

  // Check if appointment is confirmed
  bool get isConfirmed {
    return status?.toLowerCase() == 'confirmed';
  }

  // Check if appointment is pending
  bool get isPending {
    return status?.toLowerCase() == 'pending';
  }

  // Check if appointment is cancelled
  bool get isCancelled {
    return status?.toLowerCase() == 'cancelled';
  }

  // Check if appointment is completed
  bool get isCompleted {
    return status?.toLowerCase() == 'completed';
  }

  // Check if appointment is today
  bool get isToday {
    if (date == null) return false;
    final now = DateTime.now();
    return date!.year == now.year &&
           date!.month == now.month &&
           date!.day == now.day;
  }

  // Check if appointment is tomorrow
  bool get isTomorrow {
    if (date == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date!.year == tomorrow.year &&
           date!.month == tomorrow.month &&
           date!.day == tomorrow.day;
  }

  // Check if appointment is in the past
  bool get isPast {
    if (date == null) return false;
    return date!.isBefore(DateTime.now());
  }

  // Check if appointment is upcoming
  bool get isUpcoming {
    if (date == null) return false;
    return date!.isAfter(DateTime.now());
  }

  // Get appointment date formatted
  String get dateFormatted {
    if (date == null) return 'No date set';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date!.year, date!.month, date!.day);
    
    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (appointmentDate.isBefore(today)) {
      return '${date!.day}/${date!.month}/${date!.year}';
    } else {
      final difference = appointmentDate.difference(today).inDays;
      if (difference <= 7) {
        return 'In $difference days';
      } else {
        return '${date!.day}/${date!.month}/${date!.year}';
      }
    }
  }

  // Get time formatted
  String get timeFormatted {
    if (time == null) return 'No time set';
    
    try {
      final timeParts = time!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      if (hour == 0) {
        return '12:${minute.toString().padLeft(2, '0')} AM';
      } else if (hour < 12) {
        return '${hour}:${minute.toString().padLeft(2, '0')} AM';
      } else if (hour == 12) {
        return '12:${minute.toString().padLeft(2, '0')} PM';
      } else {
        return '${hour - 12}:${minute.toString().padLeft(2, '0')} PM';
      }
    } catch (e) {
      return time!;
    }
  }

  // Get duration formatted
  String get durationFormatted {
    if (duration == null) return 'No duration set';
    
    if (duration! < 60) {
      return '${duration} minutes';
    } else {
      final hours = duration! ~/ 60;
      final minutes = duration! % 60;
      if (minutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} $minutes minutes';
      }
    }
  }

  // Get display title
  String get displayTitle {
    return title ?? 'Appointment';
  }

  // Get display description
  String get displayDescription {
    return description ?? notes ?? 'No description available';
  }

  // Get display location
  String get displayLocation {
    return location ?? inpersonAddress ?? 'Location not specified';
  }

  @override
  String toString() {
    return 'Appointment(id: $id, title: $title, date: $date, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
