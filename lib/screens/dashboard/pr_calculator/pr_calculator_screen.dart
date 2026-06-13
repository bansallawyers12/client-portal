import 'dart:convert';

import 'package:client/models/pr_points_response.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service_bansal_immigration.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: const Text(
          'PR Calculator',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: ThemeConfig.goldenYellow,
        foregroundColor: Colors.white,
      ),*/
      appBar: CommonAppBar(
        titleName: 'PR Calculator',
        matterID: AuthService.selectedMatterId,
      ),
      body:
          loading || data == null
              ? const Center(child: AppLoader())
              : SingleChildScrollView(
                padding: AppResponsive.pagePadding(context),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppResponsive.maxContentWidth,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Calculate Your Points",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[850],
                                ),
                              ),
                              const SizedBox(height: 16),

                              _infoBox(),
                              const SizedBox(height: 24),

                              _buildDropdown<PointItem>(
                                "Age (at time of invitation)",
                                data!.age,
                                age,
                                (v) => setState(() => age = v),
                              ),

                              _buildDropdown<PointItem>(
                                "English Language Proficiency",
                                data!.englishLanguage,
                                english,
                                (v) => setState(() => english = v),
                                helper:
                                    "IELTS 6/PTE 50 = Competent, IELTS 7/PTE 65 = Proficient, IELTS 8/PTE 79 = Superior",
                              ),

                              _buildDropdown<PointItem>(
                                "Educational Qualifications",
                                data!.education,
                                education,
                                (v) => setState(() => education = v),
                                helper:
                                    "Qualification must be recognized by the relevant assessing authority",
                              ),

                              _buildDropdown<PointItem>(
                                "Skilled Employment Experience (Overseas)",
                                data!.overseasExp,
                                overseasExp,
                                (v) => setState(() => overseasExp = v),
                              ),

                              _buildDropdown<PointItem>(
                                "Skilled Employment Experience (Australia)",
                                data!.australiaExp,
                                ausExp,
                                (v) => setState(() => ausExp = v),
                              ),

                              const SizedBox(height: 24),
                              Text(
                                "Additional Points",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[850],
                                ),
                              ),

                              ...additionalPoints.entries.map((e) {
                                return _checkbox(
                                  e.key.label,
                                  e.value,
                                  (v) => setState(
                                    () => additionalPoints[e.key] = v,
                                  ),
                                  subtitle: e.key.description ?? e.key.note,
                                );
                              }),

                              const SizedBox(height: 24),

                              _buildDropdown<PointItem>(
                                "Partner / Spouse Status",
                                data!.partnerStatus,
                                partner,
                                (v) => setState(() => partner = v),
                              ),

                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _calculatePoints,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Calculate My Points",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),
                              _visaOptionsCard(data!.visaOptions),

                              const SizedBox(height: 24),
                              _importantNotes(data!.importantNotes),
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

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.blue, width: 4)),
      ),
      child: const Text(
        "Note: This calculator shows your base points. Additional points "
        "(5 for State/Territory nomination or 15 for regional nomination) "
        "may apply when you receive an invitation.",
        style: TextStyle(color: Colors.blueGrey, fontSize: 12),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[850],
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<T>(
            initialValue:
                items.any((e) => e.value == value?.value)
                    ? items.firstWhere((e) => e.value == value?.value)
                    : null,
            isExpanded: true,
            hint: const Text("Select", style: TextStyle(fontSize: 12)),
            items:
                items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[850],
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 2),
            Text(
              helper,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _checkbox(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(
        title,
        style: TextStyle(fontSize: 13, color: Colors.grey[850]),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              )
              : null,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _visaOptionsCard(List<VisaOption> visas) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Visa Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...visas.map(_visaItem),
          ],
        ),
      ),
    );
  }

  Widget _visaItem(VisaOption v) {
    final color =
        v.code == "189"
            ? Colors.blue
            : v.code == "190"
            ? Colors.green
            : Colors.purple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  v.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (v.additionalPointsNote != null)
                  Text(
                    v.additionalPointsNote!,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _importantNotes(List<String> notes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Important Notes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...notes.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [const Text("• "), Expanded(child: Text(e))],
                ),
              ),
            ),
          ],
        ),
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

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Total Points"),
              content: Text("You have $total points."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
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

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              // makes dialog scrollable if content is long
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Your Points",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "$totalPoints",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text("Base: $basePoints  |  Additional: $additionalPoints"),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Breakdown list
                    ...breakdown.values.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e['label'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("${e['points']} pts"),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
