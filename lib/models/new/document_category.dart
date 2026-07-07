class DocumentCategory {
  final int id;
  final String title;
  final String name;

  DocumentCategory({
    required this.id,
    required this.title,
    required this.name,
  });

  factory DocumentCategory.fromJson(Map<String, dynamic> json) {
    return DocumentCategory(
      id: json['id'],
      title: json['title'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': name,
    };
  }
}

class DocumentChecklist {
  final int id;
  final String name;
  final String docTypeName;
  final int status;
  final bool isActive;
  final String documentType;
  final String createdAt;
  final String updatedAt;

  DocumentChecklist({
    required this.id,
    required this.name,
    required this.docTypeName,
    required this.status,
    required this.isActive,
    required this.documentType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentChecklist.fromJson(Map<String, dynamic> json) {
    return DocumentChecklist(
      id: json['id'],
      name: json['name'] ?? '',
      docTypeName: json['doc_type_name'] ?? '',
      status: json['status'] ?? 0,
      isActive: json['is_active'] ?? false,
      documentType: json['document_type'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}



class DocumentManagement {
  final int sno;
  final String checklist;
  final String addedBy;
  final String date;
  final String fileName;

  DocumentManagement({
    required this.sno,
    required this.checklist,
    required this.addedBy,
    required this.date,
    required this.fileName,
  });

  factory DocumentManagement.fromJson(Map<String, dynamic> json) {
    return DocumentManagement(
      sno: json['sno'] ?? 0,
      checklist: json['checklist'] ?? '',
      addedBy: json['addedBy'] ?? '',
      date: json['date'] ?? '',
      fileName: json['fileName'] ?? '',
    );
  }
}
