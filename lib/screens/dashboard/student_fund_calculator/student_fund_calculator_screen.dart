import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme_config.dart';
import '../../../services/api_service_bansal_immigration.dart';
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
      final res = await ApiServiceBansalImmigration.getStudentCalcLists();

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

  static const Color _navy = ThemeConfig.navyBlue;
  static const Color _gold = ThemeConfig.goldenYellow;
  static const Color _fieldFill = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _green = Color(0xFF1FA64A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CommonAppBar(
        titleName: 'Student Fund Calculator',
        matterID: AuthService.selectedMatterId,
      ),
      body:
          loading || data == null
              ? const Center(child: AppLoader())
              : SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: AppResponsive.pagePadding(context),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppResponsive.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _formCard(),
                          const SizedBox(height: 20),
                          _incomeBox(),
                          const SizedBox(height: 20),
                          _notesBox(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: _gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Financial Requirements",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Estimate funds needed for your student visa",
                      style: TextStyle(fontSize: 12.5, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _courseDurationDropdown(
            "Course Duration",
            data!['course_duration'],
            "Visa funding figures below cap tuition and living at the first 12 months (pro-rata if your course is shorter).",
            selectedCourseDuration,
            (v) => setState(() => selectedCourseDuration = v),
          ),

          _numberField(
            "Annual Tuition Fee (AUD)",
            "Enter annual tuition fee",
            _tuitionCtrl,
            helper: "For visa purposes: Max 12 months of fees required",
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

          const SizedBox(height: 10),
          _ctaButton(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
      ],
    );
  }

  Widget _ctaButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        label: const Text(
          "Calculate Requirements",
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: _textMuted),
      filled: true,
      fillColor: _fieldFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _navy, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13.5,
      color: _textPrimary,
    ),
  );

  Widget _helperText(String helper) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      helper,
      style: const TextStyle(fontSize: 11.5, color: _textMuted, height: 1.4),
    ),
  );

  Widget _numberField(
    String label,
    String hint,
    TextEditingController ctrl, {
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, color: _textPrimary),
            decoration: _fieldDecoration(hint),
          ),
          if (helper != null) _helperText(helper),
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 8),
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textMuted,
            ),
            hint: const Text(
              "Select",
              style: TextStyle(fontSize: 13.5, color: _textMuted),
            ),
            style: const TextStyle(fontSize: 13.5, color: _textPrimary),
            borderRadius: BorderRadius.circular(12),
            items:
                list
                    .map<DropdownMenuItem<Map<String, dynamic>>>(
                      (e) =>
                          DropdownMenuItem(value: e, child: Text(e['label'])),
                    )
                    .toList(),
            onChanged: onChanged,
            decoration: _fieldDecoration("Select"),
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value != null ? value['id'].toString() : null,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textMuted,
            ),
            hint: const Text(
              "Select",
              style: TextStyle(fontSize: 13.5, color: _textMuted),
            ),
            style: const TextStyle(fontSize: 13.5, color: _textPrimary),
            borderRadius: BorderRadius.circular(12),
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
            decoration: _fieldDecoration("Select"),
          ),
          _helperText(helper),
        ],
      ),
    );
  }

  Widget _livingCostBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _navy.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: _navy.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Living cost requirement (primary student)",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "AUD \$${data!['fixed_rates']['annual_living_cost_primary_student']}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This corresponds to twelve months capped at the official benchmark. Partner and children use this same capped period when you calculate — courses longer than a year remain limited to twelve months in this estimator.",
            style: TextStyle(
              fontSize: 11.5,
              color: _navy.withValues(alpha: 0.6),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Official annual benchmark: AUD \$29,710 — Migration Instrument 2019 (May 2024)",
            style: TextStyle(
              fontSize: 11,
              color: _navy.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomeBox() {
    final income = data!['income_evidence_requirements'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: _green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Alternative: Income Evidence",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Instead of showing funds, you can provide evidence that your parent/spouse/de facto partner earned sufficient income in the previous 12 months.",
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 14),
          Text(
            income['note'],
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _textMuted,
              height: 1.4,
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
        color: _green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
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
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: _textMuted),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesBox() {
    final notes = data!['important_notes'] as List;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Important Notes"),
          const SizedBox(height: 14),
          ...notes.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      final res = await ApiServiceBansalImmigration.calculateStudentFund(payload: payload);

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
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_navy, Color(0xFF3B2E9E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TOTAL FINANCIAL CAPACITY REQUIRED",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "AUD \$${d['total_financial_capacity_required']}",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader("Breakdown"),
                        const SizedBox(height: 14),
                        _rowItem(
                          "Total Tuition Fees",
                          breakdown['tuition_fees']['amount'],
                          const Color(0xFF3498DB),
                        ),
                        _rowItem(
                          "Living Expenses",
                          breakdown['living_expenses']['amount'],
                          _green,
                        ),
                        _rowItem(
                          "School Fees",
                          breakdown['school_fees']['amount'],
                          const Color(0xFF9B59B6),
                        ),
                        _rowItem(
                          "Travel Expenses",
                          breakdown['travel_expenses']['amount'],
                          const Color(0xFFE67E22),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.info_rounded,
                                    color: Color(0xFF9A6A00),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Additional Requirement: OSHC",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF9A6A00),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Overseas Student Health Cover is mandatory but separate from financial capacity.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textMuted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Estimated cost: AUD \$${d['oshc']['total_cost']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE67E22),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Must cover entire visa duration",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11.5,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionHeader("Living Costs (12 months)"),
                        const SizedBox(height: 12),
                        _bullet("Student", living['primary_student']),
                        _bullet("Partner", living['partner']),
                        _bullet("Children", living['children']),
                        _bullet(
                          "Extra Accommodation",
                          living['additional_accommodation'],
                        ),
                        const SizedBox(height: 18),
                        _sectionHeader("School Fees (12 months)"),
                        const SizedBox(height: 12),
                        _bullet(
                          "1 Child",
                          breakdown['school_fees']['amount'],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22).withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Note: Calculations show 12 months maximum as per visa requirements, even though your course duration is ${d['course_duration_years']} years.",
                            style: const TextStyle(
                              color: Color(0xFFB4590F),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Close",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _rowItem(String title, dynamic amount, Color color) {
    final value = (amount as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13.5, color: _textMuted),
            ),
          ),
          Text(
            "AUD \$${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String label, dynamic amount) {
    final value = (amount as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textPrimary),
            ),
          ),
          Text(
            "AUD \$${value.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
