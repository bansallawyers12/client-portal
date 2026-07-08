import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../models/visa_search/visa_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

class VisaEstimateScreen extends StatefulWidget {
  final VisaModel visa;

  const VisaEstimateScreen({super.key, required this.visa});

  @override
  State<VisaEstimateScreen> createState() => _VisaEstimateScreenState();
}

class _VisaEstimateScreenState extends State<VisaEstimateScreen> {
  int adultCount = 0;
  int childCount = 0;
  bool isLoading = false;

  Map<String, dynamic>? estimate;

  int baseCharge = 0;
  int additionalAdultCharge = 0;
  int additionalChildCharge = 0;

  int topBaseCharge = 0;
  int topAdultCharge = 0;
  int topChildCharge = 0;

  final List<String> paymentMethods = [
    "BPAY",
    "PayPal",
    "VISA",
    "UnionPay",
    "Other",
  ];

  final List<double> surchargeRates = [0.0, 0.0101, 0.014, 0.019, 0.0199];

  int selectedPaymentIndex = 0;

  bool get _isSimpleVisa => widget.visa.id == "147" || widget.visa.id == "148";

  int get subtotal =>
      _isSimpleVisa
          ? baseCharge
          : baseCharge + additionalAdultCharge + additionalChildCharge;

  double get surchargeAmount => subtotal * surchargeRates[selectedPaymentIndex];

  double get finalTotal => subtotal + surchargeAmount;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _calculateTopSection();
    await _calculateEstimate();
  }

  Future<void> _calculateTopSection() async {
    try {
      final response = await ApiService.getVisaEstimate(
        visaId: widget.visa.id,
        additional18Plus: 1,
        additionalU18: 1,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final lineItems = data['line_items'] as List<dynamic>? ?? [];

        setState(() {
          topBaseCharge =
              lineItems.isNotEmpty ? lineItems[0]['price']?.toInt() ?? 0 : 0;

          topAdultCharge =
              lineItems.length > 1 ? lineItems[1]['price']?.toInt() ?? 0 : 0;

          topChildCharge =
              lineItems.length > 2 ? lineItems[2]['price']?.toInt() ?? 0 : 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _calculateEstimate() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.getVisaEstimate(
        visaId: widget.visa.id,
        additional18Plus: _isSimpleVisa ? 0 : adultCount,
        additionalU18: _isSimpleVisa ? 0 : childCount,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final lineItems = data['line_items'] as List<dynamic>? ?? [];

        setState(() {
          estimate = data;

          baseCharge =
              lineItems.isNotEmpty ? lineItems[0]['price']?.toInt() ?? 0 : 0;

          additionalAdultCharge =
              lineItems.length > 1 ? lineItems[1]['price']?.toInt() ?? 0 : 0;

          additionalChildCharge =
              lineItems.length > 2 ? lineItems[2]['price']?.toInt() ?? 0 : 0;

          isLoading = false;
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  static const Color _navy = ThemeConfig.navyBlue;
  static const Color _gold = ThemeConfig.goldenYellow;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _goldText = Color(0xFF9A6A00);

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _sectionHeader(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String number, String label, String price, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: _textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow({
    required Widget left,
    required Widget right,
    bool bold = false,
    Color? tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tint,
        border: const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(
                color: _textPrimary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                height: 1.3,
              ),
              child: left,
            ),
          ),
          const SizedBox(width: 12),
          DefaultTextStyle(
            style: TextStyle(
              color: _navy,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14.5,
            ),
            child: right,
          ),
        ],
      ),
    );
  }

  Widget _counterBox(int value, Function(int) onChanged) {
    Widget btn(IconData icon, VoidCallback? onTap) {
      final enabled = onTap != null;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _navy : _textMuted.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(
            Icons.remove_rounded,
            value > 0
                ? () async {
                    onChanged(value - 1);
                    await _calculateEstimate();
                  }
                : null,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          btn(Icons.add_rounded, () async {
            onChanged(value + 1);
            await _calculateEstimate();
          }),
        ],
      ),
    );
  }

  Widget _paymentSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(paymentMethods.length, (index) {
        final selected = selectedPaymentIndex == index;
        return GestureDetector(
          onTap: () => setState(() => selectedPaymentIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _gold.withValues(alpha: 0.18) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? _gold : _border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded, size: 15, color: _goldText),
                  const SizedBox(width: 5),
                ],
                Text(
                  paymentMethods[index],
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _goldText : _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = estimate?['currency'] ?? "AUD";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CommonAppBar(
        titleName: "Visa Estimate",
        matterID: AuthService.selectedMatterId,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Reference charges (hidden entirely for 147 & 148) ──
                  if (!_isSimpleVisa) ...[
                    _sectionHeader("Charges for additional applicants"),
                    const SizedBox(height: 12),
                    Container(
                      decoration: _cardDecoration,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _infoRow(
                            "1",
                            "Base application charge",
                            "$currency $topBaseCharge",
                          ),
                          _infoRow(
                            "2",
                            "Additional applicant (18 or over)",
                            "$currency $topAdultCharge",
                          ),
                          _infoRow(
                            "3",
                            "Additional applicant (under 18)",
                            "$currency $topChildCharge",
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],

                  // ── Payable fees & surcharge (always visible) ──────────
                  _sectionHeader("Payable fees & surcharge"),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      "Select a payment method to see the applicable surcharge.",
                      style: TextStyle(fontSize: 12.5, color: _textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _paymentSelector(),
                  const SizedBox(height: 18),

                  Container(
                    decoration: _cardDecoration,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Base charge — always shown
                        _feeRow(
                          left: const Text("Base application charge"),
                          right: Text("$currency $baseCharge"),
                        ),

                        // Additional rows — hidden for 147 & 148
                        if (!_isSimpleVisa) ...[
                          _feeRow(
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Additional applicant (18 or over)",
                                ),
                                const SizedBox(height: 10),
                                _counterBox(
                                  adultCount,
                                  (v) => setState(() => adultCount = v),
                                ),
                              ],
                            ),
                            right: Text("$currency $additionalAdultCharge"),
                          ),
                          _feeRow(
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Additional applicant (under 18)"),
                                const SizedBox(height: 10),
                                _counterBox(
                                  childCount,
                                  (v) => setState(() => childCount = v),
                                ),
                              ],
                            ),
                            right: Text("$currency $additionalChildCharge"),
                          ),
                        ],

                        // Subtotal & surcharge
                        _feeRow(
                          left: const Text("Subtotal"),
                          right: Text("$currency $subtotal"),
                          bold: true,
                          tint: const Color(0xFFF8FAFC),
                        ),
                        _feeRow(
                          left: Text(
                            "Surcharge (+${(surchargeRates[selectedPaymentIndex] * 100).toStringAsFixed(2)}%)",
                          ),
                          right: Text(
                            "$currency ${surchargeAmount.toStringAsFixed(2)}",
                          ),
                          tint: const Color(0xFFF8FAFC),
                        ),

                        // Total — highlighted
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          color: _navy,
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Total payable",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                "$currency ${finalTotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
