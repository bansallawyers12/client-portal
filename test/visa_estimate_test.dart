import 'package:flutter_test/flutter_test.dart';
import 'package:client/models/visa_search/visa_model.dart';

void main() {
  group('VisaModel tests', () {
    test('parses new API response format correctly', () {
      final json = {
        "id": "55",
        "category": "Parent",
        "subclass": "103",
        "visa_stream": "Parent",
        "main_applicant_fee": r"$7,600",
        "additional_applicant_18_plus_fee": r"$3,300",
        "applicant_under_18_fee": r"$1,655",
        "second_vac_charges": r"$2,065 per person",
        "notes": "Second instalment applies",
        "source": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/fees-and-charges/current-visa-pricing"
      };

      final model = VisaModel.fromJson(json);

      expect(model.id, '55');
      expect(model.subclass, '103');
      expect(model.stream, 'Parent');
      expect(model.label, 'Parent (subclass 103)');
    });

    test('parses new API response with integer id and category only', () {
      final json = {
        "id": 147,
        "category": "Visitor",
        "subclass": "600",
      };

      final model = VisaModel.fromJson(json);

      expect(model.id, '147');
      expect(model.subclass, '600');
      expect(model.label, 'Visitor (subclass 600)');
    });

    test('falls back gracefully when only subclass is provided', () {
      final json = {
        "id": "485",
        "subclass": "485",
      };

      final model = VisaModel.fromJson(json);

      expect(model.id, '485');
      expect(model.subclass, '485');
      expect(model.label, 'Visa 485');
    });

    test('preserves explicit label if provided in legacy format', () {
      final json = {
        "id": "485",
        "label": "Temporary Graduate visa",
        "subclass": "485",
        "stream": "Graduate Work",
      };

      final model = VisaModel.fromJson(json);

      expect(model.id, '485');
      expect(model.label, 'Temporary Graduate visa');
      expect(model.subclass, '485');
      expect(model.stream, 'Graduate Work');
    });
  });
}
