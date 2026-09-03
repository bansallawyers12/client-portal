import 'package:client/screens/dashboard/health_insurance/ovhc_providers_screen.dart';
import 'package:client/screens/dashboard/health_insurance/student_visa_oshc_screen/student_visa_oshcs_screen.dart';
import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

class _VisaCard {
  final String title;
  final String subclass;
  final String coverType;
  final IconData icon;
  final Color color;
  final Widget Function() screenBuilder;
  final bool featured;

  const _VisaCard({
    required this.title,
    required this.subclass,
    required this.coverType,
    required this.icon,
    required this.color,
    required this.screenBuilder,
    this.featured = false,
  });
}

class HealthInsuranceScreen extends StatelessWidget {
  const HealthInsuranceScreen({super.key});

  static final List<_VisaCard> _visas = [
    _VisaCard(
      title: 'Student Visa',
      subclass: '500',
      coverType: 'OSHC',
      icon: Icons.school_rounded,
      color: const Color(0xFF22C55E),
      featured: true,
      screenBuilder: () => const StudentVisaOSHCScreen(),
    ),
    _VisaCard(
      title: 'Tourist Visa',
      subclass: '600',
      coverType: 'OVHC',
      icon: Icons.travel_explore_rounded,
      color: const Color(0xFFF97316),
      screenBuilder:
          () => const OvhcProvidersScreen(title: 'Tourist Visa - OVHC'),
    ),
    _VisaCard(
      title: 'Skills in Demand',
      subclass: '482',
      coverType: 'OVHC',
      icon: Icons.work_rounded,
      color: const Color(0xFF8B5CF6),
      screenBuilder:
          () => const OvhcProvidersScreen(title: 'Skills in Demand - OVHC'),
    ),
    _VisaCard(
      title: 'Temporary Graduate',
      subclass: '485',
      coverType: 'OVHC',
      icon: Icons.person_rounded,
      color: const Color(0xFF3B82F6),
      screenBuilder:
          () =>
              const OvhcProvidersScreen(title: 'Temporary Graduate - OVHC'),
    ),
    _VisaCard(
      title: 'Training Visa',
      subclass: '407',
      coverType: 'OVHC',
      icon: Icons.biotech_rounded,
      color: const Color(0xFF14B8A6),
      screenBuilder:
          () => const OvhcProvidersScreen(title: 'Training Visa - OVHC'),
    ),
    _VisaCard(
      title: 'Temporary Activity',
      subclass: '408',
      coverType: 'OVHC',
      icon: Icons.event_rounded,
      color: const Color(0xFFEC4899),
      screenBuilder:
          () =>
              const OvhcProvidersScreen(title: 'Temporary Activity - OVHC'),
    ),
    _VisaCard(
      title: 'Sponsored Parent',
      subclass: '870',
      coverType: 'OVHC',
      icon: Icons.favorite_rounded,
      color: const Color(0xFFEAB308),
      screenBuilder:
          () => const OvhcProvidersScreen(title: 'Sponsored Parent - OVHC'),
    ),
  ];

  void _open(BuildContext context, _VisaCard visa) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => visa.screenBuilder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = _visas.firstWhere((v) => v.featured);
    final gridVisas = _visas.where((v) => !v.featured).toList();

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
            child: ListView(
              padding: AppResponsive.pagePadding(context),
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ThemeConfig.goldenYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Select your visa type',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ThemeConfig.navyBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FeaturedVisaCard(
                  visa: featured,
                  onTap: () => _open(context, featured),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gridVisas.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 132,
                  ),
                  itemBuilder: (context, index) {
                    final visa = gridVisas[index];
                    return _GridVisaCard(
                      visa: visa,
                      onTap: () => _open(context, visa),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration get _cardDecoration => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: ThemeConfig.navyBlue.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );

class _FeaturedVisaCard extends StatelessWidget {
  final _VisaCard visa;
  final VoidCallback onTap;

  const _FeaturedVisaCard({required this.visa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: visa.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visa.icon, color: visa.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visa.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ThemeConfig.navyBlue,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            visa.subclass,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: visa.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            visa.coverType,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: visa.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: visa.color.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridVisaCard extends StatelessWidget {
  final _VisaCard visa;
  final VoidCallback onTap;

  const _GridVisaCard({required this.visa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: visa.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visa.icon, color: visa.color, size: 22),
                ),
                const Spacer(),
                Text(
                  visa.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ThemeConfig.navyBlue,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      visa.subclass,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: visa.color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      visa.coverType,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
