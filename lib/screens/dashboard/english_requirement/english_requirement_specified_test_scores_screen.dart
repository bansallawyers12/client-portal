import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

const Color _navy = ThemeConfig.navyBlue;
const Color _gold = ThemeConfig.goldenYellow;
const Color _border = Color(0xFFE2E8F0);
const Color _textPrimary = Color(0xFF1F2937);
const Color _textMuted = Color(0xFF64748B);

class EnglishRequirementSpecifiedTestScoresScreen extends StatelessWidget {
  const EnglishRequirementSpecifiedTestScoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      /*appBar: AppBar(
        title: const Text(
          "English Requirement for Specified Test Scores",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ThemeConfig.white,
          ),
        ),
        backgroundColor: ThemeConfig.goldenYellow,
        iconTheme: const IconThemeData(color: ThemeConfig.white),
        centerTitle: true,
      ),*/
      appBar: CommonAppBar(
        titleName: "English Requirement for Specified Test Scores",
        matterID: AuthService.selectedMatterId,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppResponsive.maxContentWidth,
          ),
          child: const EnglishLanguageRequirementsWidget(),
        ),
      ),
    );
  }

}

class EnglishLanguageRequirementsWidget extends StatefulWidget {
  const EnglishLanguageRequirementsWidget({super.key});

  @override
  State<EnglishLanguageRequirementsWidget> createState() =>
      _EnglishLanguageRequirementsWidgetState();
}

class _EnglishLanguageRequirementsWidgetState
    extends State<EnglishLanguageRequirementsWidget> {
  int selectedTab = 0;
  int selectedLevelTab = 0;

  final List<String> levelTabs = [
    "Functional",
    "Vocational",
    "Competent (0 points)",
    "Proficient (10 points)",
    "Superior (20 points)",
  ];

  @override
  Widget build(BuildContext context) {
    final allData =
        selectedTab == 0 ? tableDataAfterAug2025 : tableDataBeforeAug2025;

    final selectedLevel = levelTabs[selectedLevelTab];
    final data = _filteredDataByLevel(allData, selectedLevel);
    final groupedData = _groupDataByTest(data);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "English Language Requirements",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Specified test scores for visa requirements",
                  style: TextStyle(fontSize: 13, color: _textMuted),
                ),
              ],
            ),
          ),

          // ── Effective date tabs ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _labeledCard(
              label: "EFFECTIVE DATE",
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _segment(
                        "After 7 Aug 2025",
                        selectedTab == 0,
                        () => setState(() => selectedTab = 0),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _segment(
                        "Before 6 Aug 2025",
                        selectedTab == 1,
                        () => setState(() => selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Proficiency level dropdown ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _labeledCard(
              label: "PROFICIENCY LEVEL",
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withValues(alpha: 0.45)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedLevelTab,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _navy,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: Colors.white,
                    items: List.generate(levelTabs.length, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          levelTabs[index],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _navy,
                          ),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedLevelTab = value);
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: groupedData.isEmpty
                ? const Center(
                    child: Text(
                      "No test scores for this selection.",
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: groupedData.length,
                    itemBuilder: (context, index) {
                      final group = groupedData[index];
                      return _buildGroupedCard(group);
                    },
                  ),
          ),

          // ── Source footnote ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 15, color: _textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Source: Department of Home Affairs — English language visa requirements",
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledCard({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _segment(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _navy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedCard(Map<String, dynamic> group) {
    final List<Map<String, String>> values =
        (group["values"] as List).cast<Map<String, String>>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: _navy,
                  ),
                ),
              ),
              if ((group["subtitle"] as String).isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    group["subtitle"],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...values.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "${item["label"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: _textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Text(
                      item["value"] ?? "",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                        height: 1.35,
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

  List<Map<String, dynamic>> _groupDataByTest(List<Map<String, dynamic>> data) {
    final List<Map<String, dynamic>> grouped = [];

    final List<Map<String, String>> tests = [
      {"label": "IELTS", "key": "ielts"},
      {"label": "PTE", "key": "pte"},
      {"label": "TOEFL", "key": "toefl"},
      {"label": "C1", "key": "c1"},
      {"label": "OET", "key": "oet"},
      {"label": "CELPIP", "key": "celpip"},
      {"label": "LanguageCert", "key": "languageCert"},
      {"label": "MET", "key": "met"},
    ];

    final bool isFunctional =
        levelTabs[selectedLevelTab] == "Functional" && data.isNotEmpty;

    for (final test in tests) {
      final List<Map<String, String>> values = [];

      if (isFunctional) {
        final row = data.first;
        final value = row[test["key"]];
        if (value != null && value.toString().isNotEmpty) {
          values.add({"label": "Score", "value": value.toString()});
        }
      } else {
        for (final row in data) {
          if (row["isSection"] == true) continue;
          final value = row[test["key"]];
          if (value != null && value.toString().isNotEmpty) {
            values.add({
              "label": row["component"].toString(),
              "value": value.toString(),
            });
          }
        }
      }

      if (values.isNotEmpty) {
        grouped.add({
          "title": test["label"]!,
          "subtitle": isFunctional ? levelTabs[selectedLevelTab] : "",
          "values": values,
        });
      }
    }

    return grouped;
  }

  List<Map<String, dynamic>> _filteredDataByLevel(
    List<Map<String, dynamic>> allData,
    String selectedLevel,
  ) {
    final List<Map<String, dynamic>> filtered = [];

    for (int i = 0; i < allData.length; i++) {
      final row = allData[i];

      if ((selectedLevel == "Functional" && row["level"] == "Functional") ||
          (selectedLevel != "Functional" &&
              row["isSection"] == true &&
              row["level"] == selectedLevel)) {
        filtered.add(row);

        for (int j = i + 1; j < allData.length; j++) {
          final nextRow = allData[j];
          if (nextRow["isSection"] == true) {
            break;
          }
          filtered.add(nextRow);
        }
        break;
      }
    }

    return filtered;
  }

  List<Map<String, dynamic>> get tableDataAfterAug2025 => [
    _row(
      "Functional",
      "",
      "Average band score of at least 4.5",
      "Overall band score of at least 24",
      "Total band score of at least 26",
      "Excluded",
      "Overall band score of at least 1020",
      "Overall band score of at least 5",
      "Overall band score of at least 38",
      "Overall band score of at least 38",
    ),

    _section("Vocational"),
    _row("", "Listening", "5.0", "33", "8", "Excluded", "220", "5", "41", "49"),
    _row("", "Reading", "5.0", "36", "8", "Excluded", "240", "5", "44", "47"),
    _row("", "Writing", "5.0", "29", "9", "Excluded", "200", "5", "45", "45"),
    _row("", "Speaking", "5.0", "24", "14", "Excluded", "270", "5", "54", "38"),

    _section("Competent (0 points)"),
    _row("", "Listening", "6.0", "47", "16", "163", "290", "7", "57", "56"),
    _row("", "Reading", "6.0", "48", "16", "163", "310", "7", "60", "55"),
    _row("", "Writing", "6.0", "51", "19", "170", "290", "7", "64", "57"),
    _row("", "Speaking", "6.0", "54", "19", "179", "330", "7", "70", "48"),

    _section("Proficient (10 points)"),
    _row("", "Listening", "7.0", "58", "22", "175", "350", "9", "67", "61"),
    _row("", "Reading", "7.0", "59", "22", "179", "360", "8", "71", "63"),
    _row("", "Writing", "7.0", "69", "26", "193", "380", "10", "78", "74"),
    _row("", "Speaking", "7.0", "76", "24", "194", "360", "8", "82", "59"),

    _section("Superior (20 points)"),
    _row(
      "",
      "Listening",
      "8.0",
      "69",
      "26",
      "186",
      "390",
      "10",
      "80",
      "Excluded",
    ),
    _row(
      "",
      "Reading",
      "8.0",
      "70",
      "27",
      "190",
      "400",
      "10",
      "83",
      "Excluded",
    ),
    _row(
      "",
      "Writing",
      "8.0",
      "85",
      "30",
      "210",
      "420",
      "12",
      "89",
      "Excluded",
    ),
    _row(
      "",
      "Speaking",
      "8.0",
      "88",
      "28",
      "208",
      "400",
      "10",
      "89",
      "Excluded",
    ),
  ];

  List<Map<String, dynamic>> get tableDataBeforeAug2025 => [
    _row(
      "Functional",
      "",
      "Average band score of at least 4.5",
      "Overall band score of at least 30",
      "Total band score of at least 32",
      "Total band score of at least 147",
      "",
      "",
      "",
      "",
    ),

    _section("Vocational"),
    _row("", "Listening", "5.0", "36", "4", "154", "B", "", "", ""),
    _row("", "Reading", "5.0", "36", "4", "154", "B", "", "", ""),
    _row("", "Writing", "5.0", "36", "14", "154", "B", "", "", ""),
    _row("", "Speaking", "5.0", "36", "14", "154", "B", "", "", ""),

    _section("Competent (0 points)"),
    _row("", "Listening", "6.0", "50", "12", "169", "B", "", "", ""),
    _row("", "Reading", "6.0", "50", "13", "169", "B", "", "", ""),
    _row("", "Writing", "6.0", "50", "21", "169", "B", "", "", ""),
    _row("", "Speaking", "6.0", "50", "18", "169", "B", "", "", ""),

    _section("Proficient (10 points)"),
    _row("", "Listening", "7.0", "65", "24", "185", "B", "", "", ""),
    _row("", "Reading", "7.0", "65", "24", "185", "B", "", "", ""),
    _row("", "Writing", "7.0", "65", "27", "185", "B", "", "", ""),
    _row("", "Speaking", "7.0", "65", "23", "185", "B", "", "", ""),

    _section("Superior (20 points)"),
    _row("", "Listening", "8.0", "79", "28", "200", "A", "", "", ""),
    _row("", "Reading", "8.0", "79", "29", "200", "A", "", "", ""),
    _row("", "Writing", "8.0", "79", "30", "200", "A", "", "", ""),
    _row("", "Speaking", "8.0", "79", "26", "200", "A", "", "", ""),
  ];

  static Map<String, dynamic> _row(
    String level,
    String component,
    String ielts,
    String pte,
    String toefl,
    String c1,
    String oet,
    String celpip,
    String languageCert,
    String met,
  ) {
    return {
      "level": level,
      "component": component,
      "ielts": ielts,
      "pte": pte,
      "toefl": toefl,
      "c1": c1,
      "oet": oet,
      "celpip": celpip,
      "languageCert": languageCert,
      "met": met,
      "isSection": false,
    };
  }

  static Map<String, dynamic> _section(String title) {
    return {"level": title, "isSection": true};
  }
}
