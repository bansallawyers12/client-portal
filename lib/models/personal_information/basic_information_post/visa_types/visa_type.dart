class VisaType {
  final int id;
  final String title;
  final String nickName;

  VisaType({
    required this.id,
    required this.title,
    required this.nickName,
  });

  factory VisaType.fromJson(Map<String, dynamic> json) {
    return VisaType(
      id: json["id"],
      title: json["title"],
      nickName: json["nick_name"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "nick_name": nickName,
    };
  }
}

class VisaTypeResponse {
  final bool success;
  final String message;
  final List<VisaType> data;

  VisaTypeResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory VisaTypeResponse.fromJson(Map<String, dynamic> json) {
    return VisaTypeResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: (json["data"] as List)
          .map((item) => VisaType.fromJson(item))
          .toList(),
    );
  }
}
