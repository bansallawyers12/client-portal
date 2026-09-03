import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

class EnglishRequirementForStudentVisaScreen extends StatefulWidget {
  const EnglishRequirementForStudentVisaScreen({super.key});

  @override
  State<EnglishRequirementForStudentVisaScreen> createState() =>
      _EnglishRequirementForStudentVisaScreenState();
}

class _EnglishRequirementForStudentVisaScreenState
    extends State<EnglishRequirementForStudentVisaScreen> {
  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'C1',
    'CELPIP',
    'IELTS',
    'LANGUAGECERT',
    'MET',
    'OET',
    'PTE',
    'TOEFL',
  ];

  final List<Map<String, dynamic>> data = const [
    {
      "item": "1",
      "testName": "C1 Advanced",
      "col2": "Overall band score of 161",
      "col3":
          "Not accepted for purposes of subclause 500.213(1) of Schedule 2 to the Regulations.",
      "col4":
          "Not accepted for purposes of subclause 500.213(1) of Schedule 2 to the Regulations.",
    },
    {
      "item": "2",
      "testName": "CELPIP General",
      "col2": "Overall band score of 7",
      "col3": "Overall band score of 6",
      "col4": "Overall band score of 5",
    },
    {
      "item": "3",
      "testName": "IELTS Academic",
      "col2": "Average band score of 6.0",
      "col3": "Average band score of 5.5",
      "col4": "Average band score of 5.0",
    },
    {
      "item": "4",
      "testName": "IELTS General Training",
      "col2": "Average band score of 6.0",
      "col3": "Average band score of 5.5",
      "col4": "Average band score of 5.0",
    },
    {
      "item": "5",
      "testName": "LANGUAGECERT Academic",
      "col2": "Overall band score of 61",
      "col3": "Overall band score of 54",
      "col4": "Overall band score of 46",
    },
    {
      "item": "6",
      "testName": "MET",
      "col2": "Overall band score of 53",
      "col3": "Overall band score of 49",
      "col4": "Overall band score of 44",
    },
    {
      "item": "7",
      "testName": "OET",
      "col2": "Overall band score of 1210",
      "col3": "Overall band score of 1090",
      "col4": "Overall band score of 1020",
    },
    {
      "item": "8",
      "testName": "PTE Academic",
      "col2": "Overall band score of 47",
      "col3": "Overall band score of 39",
      "col4": "Overall band score of 31",
    },
    {
      "item": "9",
      "testName": "TOEFL iBT",
      "col2": "Total band score of 67",
      "col3": "Total band score of 51",
      "col4": "Total band score of 37",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredData =
        selectedFilter == 'All'
            ? data
            : data
                .where(
                  (e) => e['testName'].toString().toUpperCase().contains(
                    selectedFilter,
                  ),
                )
                .toList();

    return Scaffold(
      /*appBar: AppBar(
        backgroundColor: ThemeConfig.goldenYellow,
        title: const Text(
          "English Requirement For Student Visa",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),*/
      appBar: CommonAppBar(
        titleName: "English Requirement For Student Visa",
        matterID: AuthService.selectedMatterId,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Padding(
                  padding: AppResponsive.horizontalPadding(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        const Text(
                          'TEST TYPE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ThemeConfig.goldenYellow.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedFilter,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: ThemeConfig.navyBlue,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              dropdownColor: Colors.white,
                              items: filters.map((filter) {
                                return DropdownMenuItem<String>(
                                  value: filter,
                                  child: Text(
                                    filter,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeConfig.navyBlue,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => selectedFilter = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: AppResponsive.horizontalPadding(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Condition 1",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Minimum test score if principal course is accompanied with either at least 10 weeks of ELICOS",
                          style: TextStyle(fontSize: 12),
                        ),

                        SizedBox(height: 12),

                        Text(
                          "Condition 2",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          "Minimum test score if principal course is accompanied by at least 20 weeks of ELICOS",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    padding: AppResponsive.horizontalPadding(context),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      return _buildCard(item);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data["item"]}. ${data["testName"]}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _row("Minimum Score", data["col2"]),
            const Divider(),
            _row("Condition 1", data["col3"]),
            const Divider(),
            _row("Condition 2", data["col4"]),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }
}
