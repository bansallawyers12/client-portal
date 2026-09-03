import 'package:client/screens/dashboard/health_insurance/student_visa_oshc_screen/student_visa_oshcs_screen.dart';
import 'package:client/screens/dashboard/health_insurance/temporary_graduate_health_insurance/temporary_graduate_ovhc_screen.dart';
import 'package:client/screens/dashboard/health_insurance/tourist_visa_ovhcs_screen/tourist_visa_ovhcs_screen.dart';
import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

class _VisaOption {
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() screenBuilder;

  const _VisaOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.screenBuilder,
  });
}

class HealthInsuranceScreen extends StatefulWidget {
  const HealthInsuranceScreen({super.key});

  @override
  State<HealthInsuranceScreen> createState() => _HealthInsuranceScreenState();
}

class _HealthInsuranceScreenState extends State<HealthInsuranceScreen> {
  static final List<_VisaOption> _options = [
    _VisaOption(
      label: 'Student Visa (OSHC)',
      icon: Icons.school_rounded,
      color: Colors.green,
      screenBuilder: () => const StudentVisaOSHCScreen(),
    ),
    _VisaOption(
      label: 'Tourist Visa (OVHC)',
      icon: Icons.airplanemode_active_rounded,
      color: Colors.orange,
      screenBuilder: () => const TouristVisaOVHCScreen(),
    ),
    _VisaOption(
      label: 'Temporary Graduate (OVHC)',
      icon: Icons.person_rounded,
      color: Colors.blue,
      screenBuilder: () => const TemporaryGraduateOVHCScreen(),
    ),
  ];

  _VisaOption? _selected;

  void _continue() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a visa type'),
          backgroundColor: ThemeConfig.errorColor,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _selected!.screenBuilder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CommonAppBar(
        titleName: 'Health Insurance',
        matterID: AuthService.selectedMatterId,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: Padding(
              padding: AppResponsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Visa Type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ThemeConfig.navyBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the visa type to view health insurance options',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selected != null
                            ? ThemeConfig.goldenYellow.withValues(alpha: 0.6)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_VisaOption>(
                        value: _selected,
                        isExpanded: true,
                        hint: const Text(
                          'Select a visa',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: ThemeConfig.navyBlue,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        items: _options.map((option) {
                          return DropdownMenuItem<_VisaOption>(
                            value: option,
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: option.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    size: 18,
                                    color: option.color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeConfig.navyBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selected = value);
                        },
                      ),
                    ),
                  ),
                  if (_selected != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selected!.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selected!.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selected!.icon,
                            color: _selected!.color,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Selected: ${_selected!.label}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _selected!.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.goldenYellow,
                        foregroundColor: ThemeConfig.navyBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
