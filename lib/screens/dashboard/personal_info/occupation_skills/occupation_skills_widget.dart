import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/theme_config.dart';
import '../../../../models/personal_information/occupation.dart';
import '../../../../services/api_service.dart';
import '../../../../services/api_service_bansal_immigration.dart';

class OccupationSkillsWidget extends StatefulWidget {
  final List<Occupation> occupations;

  const OccupationSkillsWidget({super.key, required this.occupations});

  @override
  State<OccupationSkillsWidget> createState() => _OccupationSkillsWidgetState();
}

class _OccupationSkillsWidgetState extends State<OccupationSkillsWidget> {
  bool isEditing = false;
  bool isLoading = false;

  Map<int, List<String>> occupationSuggestions = {};

  Future<void> _saveOccupations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final payload = widget.occupations.map((e) => e.toJson()).toList();
      final res = await ApiService.updateClientOccupationDetail(payload);

      if (res["success"] == true &&
          res["data"] != null &&
          res["data"]["occupations"] != null) {
        final List<dynamic> updatedData = res["data"]["occupations"];

        for (int i = 0; i < updatedData.length; i++) {
          final apiOcc = updatedData[i];
          final localOcc = widget.occupations[i];

          localOcc.id = apiOcc["id"];
          localOcc.skillAssessment = apiOcc["skill_assessment"];
          localOcc.nominatedOccupation = apiOcc["nominated_occupation"];
          localOcc.occupationCode = apiOcc["occupation_code"];
          localOcc.assessingAuthority = apiOcc["assessing_authority"];
          localOcc.visaSubclass = apiOcc["visa_subclass"];
          localOcc.assessmentDate = apiOcc["assessment_date"];
          localOcc.expiryDate = apiOcc["expiry_date"];
          localOcc.referenceNo = apiOcc["reference_no"];
          localOcc.relevantOccupation = apiOcc["relevant_occupation"];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Occupations updated successfully!")),
        );

        setState(() {
          isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Occupation update failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchOccupation(String query, int index) async {
    if (query.isEmpty) {
      setState(() => occupationSuggestions[index] = []);
      return;
    }

    final response = await ApiServiceBansalImmigration.searchOccupation(query);

    if (response["success"] == true && response["data"] != null) {
      List<String> titles = List<String>.from(
        response["data"].map((item) => item["occupation_title"]),
      );
      setState(() {
        occupationSuggestions[index] = titles;
      });
    }
  }

  void _addOccupation() {
    setState(() {
      widget.occupations.add(
        Occupation(
          id: null,
          skillAssessment: "",
          nominatedOccupation: "",
          occupationCode: "",
          assessingAuthority: "",
          visaSubclass: "",
          assessmentDate: "",
          expiryDate: "",
          referenceNo: "",
          relevantOccupation: false,
        ),
      );
      isEditing = true;
    });
  }

  Future<void> _deleteOccupation(Occupation occ) async {
    if (occ.id == null || occ.id == 0) {
      setState(() {
        widget.occupations.remove(occ);
      });
      return;
    }

    final res = await ApiService.deleteClientTabDetail(
      id: occ.id!,
      type: "occupation",
    );

    if (res["success"] == true) {
      setState(() {
        widget.occupations.remove(occ);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Occupation deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Delete failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                context,
                "Occupation & Skills",
                icon: Icons.assessment_rounded,
                isEditing: isEditing,
                showAdd: true,
                onEdit: () {
                  if (isEditing) {
                    _saveOccupations();
                  } else {
                    setState(() => isEditing = true);
                  }
                },
                onAdd: _addOccupation,
              ),
              const SizedBox(height: 18),
              ...widget.occupations.asMap().entries.map((entry) {
                int index = entry.key;
                Occupation occupation = entry.value;
                return _buildSkillCard(context, occupation, index);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    required bool isEditing,
    required VoidCallback onEdit,
    bool showAdd = false,
    VoidCallback? onAdd,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? ThemeConfig.textPrimaryDark : ThemeConfig.textPrimaryLight;
    final cardColor = isDark ? ThemeConfig.cardDark : ThemeConfig.cardLight;
    final borderColor =
        isDark ? ThemeConfig.borderDark : ThemeConfig.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeConfig.primaryColor.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ThemeConfig.primaryColor.withValues(alpha:0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: ThemeConfig.primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (showAdd && onAdd != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeConfig.successColor.withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ThemeConfig.successColor.withValues(alpha:0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: ThemeConfig.successColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          if (showAdd) const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      isEditing
                          ? ThemeConfig.successColor.withValues(alpha:0.12)
                          : ThemeConfig.primaryColor.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isEditing
                            ? ThemeConfig.successColor.withValues(alpha:0.25)
                            : ThemeConfig.primaryColor.withValues(alpha:0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  color:
                      isEditing
                          ? ThemeConfig.successColor
                          : ThemeConfig.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(
    BuildContext context,
    Occupation occupation,
    int index,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? ThemeConfig.cardDark : ThemeConfig.cardLight;
    final borderColor =
        isDark ? ThemeConfig.borderDark : ThemeConfig.borderLight;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 26,
            runSpacing: 14,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildEditableRow(
                      context,
                      "Skill Assessment",
                      occupation.skillAssessment,
                      (v) => occupation.skillAssessment = v,
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: ThemeConfig.errorColor,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: Text(
                                  "Delete Occupation",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                content: Text(
                                  "Are you sure you want to delete this occupation?",
                                  style: GoogleFonts.inter(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: ThemeConfig.errorColor,
                                    ),
                                    child: Text(
                                      "Delete",
                                      style: GoogleFonts.inter(),
                                    ),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
                          await _deleteOccupation(occupation);
                        }
                      },
                    ),
                ],
              ),
              _buildDateRow(
                context,
                "Assessment Date",
                occupation.assessmentDate,
                (val) => occupation.assessmentDate = val,
              ),
              _buildSearchableRow(
                context,
                "Nominated Occupation",
                occupation.nominatedOccupation,
                index,
                (val) => occupation.nominatedOccupation = val,
              ),
              _buildEditableRow(
                context,
                "Occupation Code",
                occupation.occupationCode,
                (val) => occupation.occupationCode = val,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 26,
            runSpacing: 14,
            children: [
              _buildDateRow(
                context,
                "Expiry Date",
                occupation.expiryDate,
                (val) => occupation.expiryDate = val,
              ),
              _buildEditableRow(
                context,
                "Reference No",
                occupation.referenceNo,
                (val) => occupation.referenceNo = val,
              ),
              _buildEditableRow(
                context,
                "Assessing Authority",
                occupation.assessingAuthority,
                (val) => occupation.assessingAuthority = val,
              ),
              _buildEditableRow(
                context,
                "Visa Subclass",
                occupation.visaSubclass ?? "",
                (val) => occupation.visaSubclass = val,
              ),
              _buildCheckboxRow(
                context,
                "Relevant",
                occupation.relevantOccupation,
                (val) => occupation.relevantOccupation = val,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
    BuildContext context,
    String label,
    String value,
    Function(String) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isDark
                      ? ThemeConfig.textPrimaryDark
                      : ThemeConfig.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            enabled: isEditing,
            onChanged: onChanged,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color:
                  isDark
                      ? ThemeConfig.textPrimaryDark
                      : ThemeConfig.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color:
                    isDark
                        ? ThemeConfig.textSecondaryDark
                        : ThemeConfig.textSecondaryLight,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? ThemeConfig.borderDark : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      isDark ? ThemeConfig.borderDark : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeConfig.primaryColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: isDark ? ThemeConfig.cardDark : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableRow(
    BuildContext context,
    String label,
    String value,
    int index,
    Function(String) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    TextEditingController controller = TextEditingController(text: value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark
                        ? ThemeConfig.textPrimaryDark
                        : ThemeConfig.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextFormField(
                controller: controller,
                enabled: isEditing,
                onChanged: (val) {
                  onChanged(val);
                  _searchOccupation(val, index);
                },
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color:
                      isDark
                          ? ThemeConfig.textPrimaryDark
                          : ThemeConfig.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color:
                        isDark
                            ? ThemeConfig.textSecondaryDark
                            : ThemeConfig.textSecondaryLight,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark
                              ? ThemeConfig.borderDark
                              : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          isDark
                              ? ThemeConfig.borderDark
                              : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ThemeConfig.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? ThemeConfig.cardDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon:
                      isEditing && controller.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color:
                                  isDark
                                      ? ThemeConfig.textSecondaryDark
                                      : ThemeConfig.textSecondaryLight,
                            ),
                            onPressed: () {
                              setState(() {
                                controller.clear();
                                onChanged("");
                                occupationSuggestions[index] = [];
                              });
                            },
                          )
                          : null,
                ),
              ),
            ),
            if (occupationSuggestions[index] != null &&
                occupationSuggestions[index]!.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDark ? ThemeConfig.cardDark : ThemeConfig.cardLight,
                  border: Border.all(
                    color:
                        isDark
                            ? ThemeConfig.borderDark
                            : ThemeConfig.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView(
                  shrinkWrap: true,
                  children:
                      occupationSuggestions[index]!
                          .map(
                            (suggestion) => ListTile(
                              title: Text(
                                suggestion,
                                style: GoogleFonts.inter(),
                              ),
                              onTap: () {
                                setState(() {
                                  controller.text = suggestion;
                                  onChanged(suggestion);
                                  occupationSuggestions[index] = [];
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    String label,
    String value,
    Function(String) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    TextEditingController controller = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isDark
                        ? ThemeConfig.textPrimaryDark
                        : ThemeConfig.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap:
                    isEditing
                        ? () async {
                          DateTime initialDate;
                          if (value.isNotEmpty) {
                            final parts = value.split('/');
                            initialDate = DateTime(
                              int.parse(parts[2]),
                              int.parse(parts[1]),
                              int.parse(parts[0]),
                            );
                          } else {
                            initialDate = DateTime.now();
                          }

                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            String formattedDate =
                                "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                            controller.text = formattedDate;
                            setState(() {
                              onChanged(formattedDate);
                            });
                          }
                        }
                        : null,
                child: AbsorbPointer(
                  absorbing: true,
                  child: TextFormField(
                    controller: controller,
                    enabled: isEditing,
                    readOnly: true,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color:
                          isDark
                              ? ThemeConfig.textPrimaryDark
                              : ThemeConfig.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: label,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color:
                            isDark
                                ? ThemeConfig.textSecondaryDark
                                : ThemeConfig.textSecondaryLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? ThemeConfig.borderDark
                                  : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? ThemeConfig.borderDark
                                  : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: ThemeConfig.primaryColor,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? ThemeConfig.cardDark : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color:
                            isDark
                                ? ThemeConfig.textSecondaryDark
                                : ThemeConfig.textSecondaryLight,
                      ),
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

  Widget _buildCheckboxRow(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? ThemeConfig.textPrimaryDark : ThemeConfig.textPrimaryLight;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: textColor,
            ),
          ),
          Checkbox(
            value: value,
            activeColor: ThemeConfig.primaryColor,
            checkColor: Colors.white,
            onChanged:
                isEditing
                    ? (val) {
                      setState(() {
                        onChanged(val ?? false);
                      });
                    }
                    : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
