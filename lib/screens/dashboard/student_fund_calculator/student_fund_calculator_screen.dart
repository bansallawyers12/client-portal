import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

class StudentFundCalculatorScreen extends StatefulWidget {
  const StudentFundCalculatorScreen({super.key});

  @override
  State<StudentFundCalculatorScreen> createState() =>
      _StudentFundCalculatorScreenState();
}

class _StudentFundCalculatorScreenState
    extends State<StudentFundCalculatorScreen> {
  static const String _studentCalcCacheKey = "student_calc_lists_cache";

  bool loading = true;
  Map<String, dynamic>? data;

  Map<String, dynamic>? selectedCourseDuration;

  final _tuitionCtrl = TextEditingController();
  final _travelCtrl = TextEditingController(text: "2000");

  Map<String, dynamic>? partner;
  Map<String, dynamic>? children;
  Map<String, dynamic>? schoolChildren;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final cached = prefs.getString(_studentCalcCacheKey);

      if (cached != null) {
        final cachedJson = jsonDecode(cached);

        if (cachedJson['success'] == true) {
          if (!mounted) return;

          setState(() {
            data = cachedJson['data'];
            loading = false;
          });

          return;
        }
      }
    } catch (e) {
      debugPrint("Cache error: $e");
    }

    try {
      final res = await ApiService.getStudentCalcLists();

      await prefs.setString(_studentCalcCacheKey, jsonEncode(res));

      if (res['success'] == true) {
        if (!mounted) return;

        setState(() {
          data = res['data'];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("API error: $e");

      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleName: 'Student Fund Calculator',
        matterID: AuthService.selectedMatterId,
      ),
      body:
          loading || data == null
              ? const Center(child: AppLoader())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: AppResponsive.pagePadding(context),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppResponsive.maxContentWidth,
                      ),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Calculate Your Financial Requirements",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 16),

                              _courseDurationDropdown(
                                "Course Duration",
                                data!['course_duration'],
                                "Visa funding figures below cap tuition and living at the first 12 months (pro‑rata if your course is shorter).",
                                selectedCourseDuration,
                                (v) =>
                                    setState(() => selectedCourseDuration = v),
                              ),

                              _numberField(
                                "Annual Tuition Fee (AUD)",
                                "Enter annual tuition fee",
                                _tuitionCtrl,
                                helper:
                                    "For visa purposes: Max 12 months of fees required",
                              ),

                              _livingCostBox(),

                              _dropdown(
                                "Partner/Spouse Accompanying You",
                                data!['partner_spouse_options'],
                                partner,
                                (v) => setState(() => partner = v),
                              ),

                              _dropdown(
                                "Number of Dependent Children",
                                data!['dependent_children_options'],
                                children,
                                (v) => setState(() => children = v),
                              ),

                              _dropdown(
                                "Number of School-age Children",
                                data!['school_age_children_options'],
                                schoolChildren,
                                (v) => setState(() => schoolChildren = v),
                              ),

                              _numberField(
                                "Travel Expenses (Return flights)",
                                "Include return airfare",
                                _travelCtrl,
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _calculate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text(
                                    "Calculate Requirements",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              _incomeBox(),

                              const SizedBox(height: 16),

                              _notesBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _numberField(
    String label,
    String hint,
    TextEditingController ctrl, {
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(height: 4),

          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),

          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                helper,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    List list,
    Map<String, dynamic>? value,
    ValueChanged<Map<String, dynamic>?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(height: 4),

          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: value,
            isExpanded: true,
            hint: const Text("Select"),
            items:
                list
                    .map<DropdownMenuItem<Map<String, dynamic>>>(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text(e['label'])),
                    )
                    .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _courseDurationDropdown(
    String label,
    List list,
    String helper,
    Map<String, dynamic>? value,
    ValueChanged<Map<String, dynamic>?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),

          DropdownButtonFormField<String>(
            value: value != null ? value['id'].toString() : null,
            isExpanded: true,
            hint: const Text("Select"),

            items:
                list.map<DropdownMenuItem<String>>((e) {
                  return DropdownMenuItem<String>(
                    value: e['id'].toString(),
                    child: Text(e['label']),
                  );
                }).toList(),

            onChanged: (selectedId) {
              final selectedItem = list.firstWhere(
                (e) => e['id'].toString() == selectedId,
                orElse: () => {},
              );

              if (selectedItem.isNotEmpty) {
                onChanged(selectedItem);
              }
            },

            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              helper,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _livingCostBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Living cost requirement (primary student)",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          Text(
            "AUD \$${data!['fixed_rates']['annual_living_cost_primary_student']}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),

          Text(
            "AUD \$29,710 corresponds to twelve months capped at benchmark AUD \$29,710. Partner and children use this same capped period when you click Calculate — courses longer than a year remain limited to twelve months in this estimator.",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const Text(
            "Official annual benchmark: AUD \$29,710 — Migration Instrument 2019 (May 2024)",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _incomeBox() {
    final income = data!['income_evidence_requirements'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FFF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB7EAC7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1FA64A), width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF1FA64A),
                  size: 12,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  "Alternative: Income Evidence",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            "Instead of showing funds, you can provide evidence that your parent/spouse/de facto partner earned sufficient income in the previous 12 months.",
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 14),

          _incomeItem(
            title: "Without Dependants",
            subtitle: "Annual income required",
            amount: "AUD \$${income['without_dependants']}",
          ),

          const SizedBox(height: 10),

          _incomeItem(
            title: "With Dependants",
            subtitle: "Annual income required",
            amount: "AUD \$${income['with_dependants']}",
          ),

          const SizedBox(height: 12),

          Text(
            income['note'],
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomeItem({
    required String title,
    required String subtitle,
    required String amount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7EAC7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1FA64A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesBox() {
    final notes = data!['important_notes'] as List;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Important Notes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...notes.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Text("• "),
                    Expanded(
                      child: Text(e, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculate() async {
    if (selectedCourseDuration == null || _tuitionCtrl.text.isEmpty) {
      _showError("Please select course duration and tuition fee");
      return;
    }

    final payload = {
      "course_duration": (selectedCourseDuration!['id'] as num).toInt(),
      "annual_tuition_fee":
          (double.tryParse(_tuitionCtrl.text) ?? 0).toDouble(),
      "partner_spouse": ((partner?['value'] ?? 0) as num).toInt(),
      "dependent_children": ((children?['value'] ?? 0) as num).toInt(),
      "school_age_children": ((schoolChildren?['value'] ?? 0) as num).toInt(),
      "travel_expenses": (double.tryParse(_travelCtrl.text) ?? 0).toDouble(),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoader()),
    );

    try {
      final res = await ApiService.calculateStudentFund(payload: payload);

      Navigator.pop(context);

      if (res['success'] == true) {
        _showFinancialResultDialog(context, res['data']);
      } else {
        _showError("Calculation failed");
      }
    } catch (e) {
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showFinancialResultDialog(
    BuildContext context,
    Map<String, dynamic> d,
  ) {
    final breakdown = d['breakdown'];
    final living = breakdown['living_expenses']['breakdown'];

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Financial Requirements",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _rowItem(
                      "Total Tuition Fees",
                      breakdown['tuition_fees']['amount'],
                      Colors.blue,
                    ),

                    _divider(),

                    _rowItem(
                      "Living Expenses",
                      breakdown['living_expenses']['amount'],
                      Colors.green,
                    ),

                    _divider(),

                    _rowItem(
                      "School Fees",
                      breakdown['school_fees']['amount'],
                      Colors.purple,
                    ),

                    _divider(),

                    _rowItem(
                      "Travel Expenses",
                      breakdown['travel_expenses']['amount'],
                      Colors.deepOrange,
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.purple.shade50],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Financial Capacity Required",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "AUD \$${d['total_financial_capacity_required']}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Additional Requirement: OSHC",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            "Overseas Student Health Cover is mandatory but separate from financial capacity",
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Estimated cost: AUD \$${d['oshc']['total_cost']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            "Must cover entire visa duration",
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Living Costs Breakdown (12 months):",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _bullet("Student", living['primary_student']),
                    _bullet("Partner", living['partner']),
                    _bullet("Children", living['children']),
                    _bullet(
                      "Extra Accommodation",
                      living['additional_accommodation'],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "School Fees (12 months):",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _bullet("1 Child", breakdown['school_fees']['amount']),

                    const SizedBox(height: 12),

                    Text(
                      "Note: Calculations show 12 months maximum as per visa requirements, even though your course duration is ${d['course_duration_years']} years.",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _rowItem(String title, dynamic amount, Color color) {
    final value = (amount as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),

        const SizedBox(height: 4),

        Text(
          "AUD \$${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(),
  );

  Widget _bullet(String label, dynamic amount) {
    final value = (amount as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Text("• "),
          Expanded(child: Text(label)),
          Text("AUD \$${value.toStringAsFixed(0)}"),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
