import 'dart:convert';

import 'package:client/models/pr_points_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme_config.dart';
import '../../../services/api_service_bansal_immigration.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';
import '../book_appointment/book_location_screen.dart';

class PRCalculatorScreen extends StatefulWidget {
  const PRCalculatorScreen({super.key});

  @override
  State<PRCalculatorScreen> createState() => _PRCalculatorScreenState();
}

class _PRCalculatorScreenState extends State<PRCalculatorScreen> {
  static const String _cacheKey = "pr_points_cache";
  PRData? data;
  bool loading = true;

  PointItem? age;
  PointItem? english;
  PointItem? education;
  PointItem? overseasExp;
  PointItem? ausExp;
  PointItem? partner;

  Map<AdditionalPointItem, bool> additionalPoints = {};

  static const int _eligibilityThreshold = 65;
  bool _congratsShown = false;

  int get _liveTotal {
    int total = 0;
    if (age != null) total += age!.value;
    if (english != null) total += english!.value;
    if (education != null) total += education!.value;
    if (overseasExp != null) total += overseasExp!.value;
    if (ausExp != null) total += ausExp!.value;
    if (partner != null) total += partner!.value;
    additionalPoints.forEach((k, v) {
      if (v) total += k.value;
    });
    return total;
  }

  /// Applies a selection change, then checks whether the eligibility
  /// milestone has been reached so the congratulations popup can appear.
  void _selectAndCheck(VoidCallback apply) {
    setState(apply);

    final total = _liveTotal;
    if (total >= _eligibilityThreshold) {
      if (!_congratsShown) {
        _congratsShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCongratsDialog(total);
        });
      }
    } else {
      // Allow the popup to trigger again if they drop below and cross back.
      _congratsShown = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPRPoints();
  }

  Future<void> _fetchPRPoints() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final cached = prefs.getString(_cacheKey);

      if (cached != null) {
        final cachedJson = jsonDecode(cached);
        final parsed = PRPointsResponse.fromJson(cachedJson);

        if (parsed.success) {
          final map = <AdditionalPointItem, bool>{};
          for (var item in parsed.data.additionalPoints) {
            map[item] = false;
          }

          if (!mounted) return;
          setState(() {
            data = parsed.data;
            additionalPoints = map;
            loading = false;
          });

          return;
        }
      }
    } catch (e) {
      debugPrint("Cache error: $e");
    }

    try {
      final response = await ApiServiceBansalImmigration.getPRPoints();

      await prefs.setString(_cacheKey, jsonEncode(response));

      final parsed = PRPointsResponse.fromJson(response);

      if (parsed.success) {
        final map = <AdditionalPointItem, bool>{};
        for (var item in parsed.data.additionalPoints) {
          map[item] = false;
        }

        if (!mounted) return;
        setState(() {
          data = parsed.data;
          additionalPoints = map;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CommonAppBar(
        titleName: 'PR Calculator',
        matterID: AuthService.selectedMatterId,
      ),
      body:
          loading || data == null
              ? const Center(child: AppLoader())
              : SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Pinned score bar — always visible while scrolling.
                    Container(
                      color: const Color(0xFFF5F7FA),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppResponsive.maxContentWidth,
                          ),
                          child: _livePointsBar(),
                        ),
                      ),
                    ),
                    Expanded(
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
                                _visaOptionsCard(data!.visaOptions),
                                const SizedBox(height: 20),
                                _importantNotes(data!.importantNotes),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  Icons.calculate_rounded,
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
                      "Calculate Your Points",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Estimate your skilled migration score",
                      style: TextStyle(fontSize: 12.5, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _infoBox(),
          const SizedBox(height: 22),

          // Fields are revealed one at a time as each is answered.
          _buildDropdown<PointItem>(
            "Age (at time of invitation)",
            data!.age,
            age,
            (v) => _selectAndCheck(() => age = v),
          ),
          if (age != null)
            _buildDropdown<PointItem>(
              "English Language Proficiency",
              data!.englishLanguage,
              english,
              (v) => _selectAndCheck(() => english = v),
              helper:
                  "IELTS 6/PTE 50 = Competent, IELTS 7/PTE 65 = Proficient, IELTS 8/PTE 79 = Superior",
            ),
          if (english != null)
            _buildDropdown<PointItem>(
              "Educational Qualifications",
              data!.education,
              education,
              (v) => _selectAndCheck(() => education = v),
              helper:
                  "Qualification must be recognized by the relevant assessing authority",
            ),
          if (education != null)
            _buildDropdown<PointItem>(
              "Skilled Employment Experience (Overseas)",
              data!.overseasExp,
              overseasExp,
              (v) => _selectAndCheck(() => overseasExp = v),
            ),
          if (overseasExp != null)
            _buildDropdown<PointItem>(
              "Skilled Employment Experience (Australia)",
              data!.australiaExp,
              ausExp,
              (v) => _selectAndCheck(() => ausExp = v),
            ),

          if (ausExp != null) ...[
            const SizedBox(height: 8),
            _sectionHeader("Additional Points"),
            const SizedBox(height: 12),
            ...additionalPoints.entries.map((e) {
              return _pointTile(
                e.key.label,
                e.value,
                e.key.value,
                (v) => _selectAndCheck(() => additionalPoints[e.key] = v),
                subtitle: e.key.description ?? e.key.note,
              );
            }),

            const SizedBox(height: 20),
            _buildDropdown<PointItem>(
              "Partner / Spouse Status",
              data!.partnerStatus,
              partner,
              (v) => _selectAndCheck(() => partner = v),
            ),

            const SizedBox(height: 24),
            _ctaButton(),
          ] else ...[
            const SizedBox(height: 4),
            _nextStepHint(),
          ],
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
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF3B2E9E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _calculatePoints,
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  "Calculate My Points",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: _navy.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "This calculator shows your base points. Additional points "
              "(5 for State/Territory nomination or 15 for regional nomination) "
              "may apply when you receive an invitation.",
              style: TextStyle(
                color: _navy.withValues(alpha: 0.75),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _livePointsBar() {
    final total = _liveTotal;
    final reached = total >= _eligibilityThreshold;
    final progress = (total / _eligibilityThreshold).clamp(0.0, 1.0);
    const green = Color(0xFF27AE60);
    final remaining = (_eligibilityThreshold - total).clamp(
      0,
      _eligibilityThreshold,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              reached
                  ? const [Color(0xFF1E7E45), Color(0xFF27AE60)]
                  : const [_navy, Color(0xFF3B2E9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (reached ? green : _navy).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      reached ? Colors.white : _gold,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$total",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      "of $_eligibilityThreshold",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      reached
                          ? Icons.emoji_events_rounded
                          : Icons.trending_up_rounded,
                      size: 17,
                      color: reached ? Colors.white : _gold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reached
                            ? "You've reached the minimum!"
                            : "Your current points",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reached
                      ? "You're eligible to submit an EOI for skilled migration."
                      : "$remaining more point${remaining == 1 ? '' : 's'} to reach the minimum of $_eligibilityThreshold.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStepHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_upward_rounded,
          size: 15,
          color: _textMuted.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Text(
          "Answer each field to continue",
          style: TextStyle(
            fontSize: 12.5,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _dialogCloseButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showCongratsDialog(int total) {
    const green = Color(0xFF27AE60);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [green, Color(0xFF2ECC71)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Congratulations!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You've reached $total points",
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _dialogCloseButton(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "You now meet the minimum 65 points required to be eligible "
                    "to submit an Expression of Interest (EOI) for skilled migration.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: _textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookLocationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Book Appointment",
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
    );
  }

  Widget _buildDropdown<T extends PointItem>(
    String label,
    List<T> items,
    T? value,
    ValueChanged<T?> onChanged, {
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            initialValue:
                items.any((e) => e.value == value?.value)
                    ? items.firstWhere((e) => e.value == value?.value)
                    : null,
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
                items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: _fieldFill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
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
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper,
              style: const TextStyle(
                fontSize: 11.5,
                color: _textMuted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pointTile(
    String title,
    bool value,
    int points,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: value ? _navy.withValues(alpha: 0.05) : _fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? _navy : _border,
                width: value ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: value ? _navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: value ? _navy : const Color(0xFFCBD5E1),
                      width: 1.6,
                    ),
                  ),
                  child:
                      value
                          ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              value ? FontWeight.w700 : FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        value
                            ? _navy
                            : _navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "+$points",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: value ? Colors.white : _navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _visaOptionsCard(List<VisaOption> visas) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("Visa Options"),
          const SizedBox(height: 16),
          ...visas.map(_visaItem),
        ],
      ),
    );
  }

  Widget _visaItem(VisaOption v) {
    final color =
        v.code == "189"
            ? const Color(0xFF3498DB)
            : v.code == "190"
            ? const Color(0xFF27AE60)
            : const Color(0xFF9B59B6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  v.description,
                  style: const TextStyle(fontSize: 12.5, color: _textMuted),
                ),
                if (v.additionalPointsNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    v.additionalPointsNote!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: color.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _importantNotes(List<String> notes) {
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

  void _calculatePoints() async {
    if (age == null ||
        english == null ||
        education == null ||
        overseasExp == null ||
        ausExp == null ||
        partner == null) {
      int total = 0;

      if (age != null) total += age!.value;
      if (english != null) total += english!.value;
      if (education != null) total += education!.value;
      if (overseasExp != null) total += overseasExp!.value;
      if (ausExp != null) total += ausExp!.value;
      if (partner != null) total += partner!.value;

      additionalPoints.forEach((k, v) {
        if (v) total += k.value;
      });

      final bool isEligible = total >= 65;

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          isEligible
                              ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEligible
                          ? Icons.emoji_events_rounded
                          : Icons.info_outline_rounded,
                      color:
                          isEligible
                              ? const Color(0xFF16A34A)
                              : Colors.orange,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    isEligible
                        ? 'Congratulations! 🎉'
                        : 'Your Points Summary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isEligible
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Points badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'You have $total points',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ThemeConfig.goldenYellow.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    isEligible
                        ? 'You are eligible for EOI submissions for skilled migration. Book a consultation to get started!'
                        : 'You need ${65 - total} more points to be eligible for EOI submissions.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              actions: [
                if (isEligible) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookLocationScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F3C88),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Book Consultation'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ],
            ),
      );
      return;
    }

    final selectedAdditionalPoints =
        additionalPoints.entries
            .where((e) => e.value)
            .map((e) => e.key.value)
            .toList();

    final payload = {
      "age": age!.value,
      "english_language_proficiency": english!.value,
      "educational_qualifications": education!.value,
      "skilled_employment_overseas": overseasExp!.value,
      "skilled_employment_australia": ausExp!.value,
      "additional_points": selectedAdditionalPoints,
      "partner_spouse_status": partner!.value,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoader()),
    );

    try {
      final response = await ApiServiceBansalImmigration.calculatePRPoints(payload: payload);

      Navigator.pop(context);

      if (response['success'] == true) {
        _showResultDialog(response['data']);
      } else {
        _showError("Failed to calculate points");
      }
    } catch (e) {
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showResultDialog(Map<String, dynamic> data) {
    final totalPoints = data['total_points'];
    final basePoints = data['base_points'];
    final additionalPoints = data['additional_points'];
    final message = data['message'];
    final breakdown = data['points_breakdown'] as Map<String, dynamic>;

    final breakdownList = breakdown.values.toList();

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 24,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_navy, Color(0xFF3B2E9E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "YOUR POINTS",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "$totalPoints",
                              style: const TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Base $basePoints",
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.white54,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    "Additional $additionalPoints",
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _dialogCloseButton(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF27AE60).withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF1E7E45),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    color: Color(0xFF1E7E45),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            children: List.generate(breakdownList.length, (i) {
                              final e = breakdownList[i];
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e['label'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _navy.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            "${e['points']} pts",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _navy,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (i != breakdownList.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: _border.withValues(alpha: 0.6),
                                      indent: 14,
                                      endIndent: 14,
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BookLocationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.event_available_rounded,
                              size: 20,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            label: const Text(
                              "Book Appointment",
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

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
