class NotificationResponse {
  final bool success;
  final NotificationData data;

  NotificationResponse({
    required this.success,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'],
      data: NotificationData.fromJson(json['data']),
    );
  }
}

class NotificationData {
  final List<NotificationModel> notifications;
  final Pagination pagination;

  NotificationData({
    required this.notifications,
    required this.pagination,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    var list = json['notifications'] as List;
    List<NotificationModel> notificationsList =
    list.map((i) => NotificationModel.fromJson(i)).toList();

    return NotificationData(
      notifications: notificationsList,
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class NotificationModel {
  final int id;
  final int senderId;
  final int clientMatterId;
  final String url;
  final String notificationType;
  final String message;
  bool isRead;
  final bool seen;
  final String senderName;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.senderId,
    required this.clientMatterId,
    required this.url,
    required this.notificationType,
    required this.message,
    required this.isRead,
    required this.seen,
    required this.senderName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      senderId: json['sender_id'],
      clientMatterId: json['client_matter_id'],
      url: json['url'],
      notificationType: json['notification_type'],
      message: json['message'],
      isRead: json['is_read'] == 1,
      seen: json['seen'] == 1,
      senderName: json['sender_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'client_matter_id': clientMatterId,
    'url': url,
    'notification_type': notificationType,
    'message': message,
    'is_read': isRead ? 1 : 0,
    'seen': seen ? 1 : 0,
    'sender_name': senderName,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class Pagination {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  Pagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'],
      perPage: json['per_page'],
      total: json['total'],
      lastPage: json['last_page'],
    );
  }
}
