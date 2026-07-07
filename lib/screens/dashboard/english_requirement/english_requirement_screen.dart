import 'package:client/screens/dashboard/english_requirement/english_requirement_for_485_temporary_graduate_visa_tr_screen.dart';
import 'package:client/screens/dashboard/english_requirement/english_requirement_for_student_visa_screen.dart';
import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';
import 'english_requirement_specified_test_scores_screen.dart';

class EnglishRequirementScreen extends StatelessWidget {
  const EnglishRequirementScreen({super.key});

  static const Color _navy = ThemeConfig.navyBlue;
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final links = [
      _LinkItem(
        index: 0,
        title: "Specified Test Scores",
        subtitle: "IELTS, PTE, TOEFL and other test bands",
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFF3498DB),
      ),
      _LinkItem(
        index: 1,
        title: "485 Temporary Graduate Visa (TR)",
        subtitle: "English requirement for the 485 visa",
        icon: Icons.school_rounded,
        color: const Color(0xFF27AE60),
      ),
      _LinkItem(
        index: 2,
        title: "Student Visa",
        subtitle: "English requirement for student visas",
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFE67E22),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CommonAppBar(
        titleName: "English Requirements",
        matterID: AuthService.selectedMatterId,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: AppResponsive.pagePadding(context),
              child: Column(
                children:
                    links
                        .map(
                          (link) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _linkTile(context, link),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _linkTile(BuildContext context, _LinkItem link) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (link.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => const EnglishRequirementSpecifiedTestScoresScreen(),
              ),
            );
          } else if (link.index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        const EnglishRequirementFor485TemporaryGraduateVisaTRScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EnglishRequirementForStudentVisaScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: link.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(link.icon, color: link.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        link.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkItem {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _LinkItem({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
