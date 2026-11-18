class VisaModel {
  final String id;
  final String label;
  final String subclass;
  final String? stream;

  VisaModel({
    required this.id,
    required this.label,
    required this.subclass,
    this.stream,
  });

  factory VisaModel.fromJson(Map<String, dynamic> json) {
    final stream = (json['visa_stream'] ?? json['stream'])?.toString();
    final category = json['category']?.toString();
    final subclass = json['subclass']?.toString() ?? '';

    String label = json['label']?.toString() ?? '';
    if (label.isEmpty) {
      final namePart = stream ?? category ?? '';
      if (namePart.isNotEmpty) {
        final subPart = subclass.isNotEmpty ? '(subclass $subclass)' : '';
        label = [namePart, subPart]
            .where((s) => s.isNotEmpty)
            .join(' ')
            .trim();
      } else if (subclass.isNotEmpty) {
        label = 'Visa $subclass';
      }
    }

    return VisaModel(
      id: json['id']?.toString() ?? '',
      label: label,
      subclass: subclass,
      stream: stream,
    );
  }
}