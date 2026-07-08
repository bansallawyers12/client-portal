import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../widgets/webview/universal_webview.dart';

class ImportantLinksScreen extends StatelessWidget {
  const ImportantLinksScreen({super.key});

  static const Color _navy = ThemeConfig.navyBlue;
  static const Color _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final links = [
      _LinkItem(
        title: "Visa Processing",
        subtitle: "Check current visa processing times",
        icon: Icons.schedule_rounded,
        url: UrlConstants.importantLinks.visaProcessing,
        color: const Color(0xFF3498DB),
      ),
      _LinkItem(
        title: "VEVO Check",
        subtitle: "Verify visa entitlements online",
        icon: Icons.verified_user_rounded,
        url: UrlConstants.importantLinks.vevoCheck,
        color: const Color(0xFF27AE60),
      ),
      _LinkItem(
        title: "Invitation Rounds",
        subtitle: "Latest SkillSelect invitation results",
        icon: Icons.mark_email_read_rounded,
        url: UrlConstants.importantLinks.invitationRounds,
        color: const Color(0xFFE67E22),
      ),
      _LinkItem(
        title: "Departmental Forms",
        subtitle: "Official immigration forms",
        icon: Icons.description_rounded,
        url: UrlConstants.importantLinks.departmentalForms,
        color: const Color(0xFF9B59B6),
      ),
      _LinkItem(
        title: "Course Check (CRICOS)",
        subtitle: "Search registered courses",
        icon: Icons.school_rounded,
        url: UrlConstants.importantLinks.courseCheck,
        color: const Color(0xFF14B8A6),
      ),
      _LinkItem(
        title: "Consumer Guide",
        subtitle: "Know your rights and protections",
        icon: Icons.menu_book_rounded,
        url: UrlConstants.importantLinks.consumerGuide,
        color: const Color(0xFFE74C3C),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CommonAppBar(
        titleName: 'Important Links',
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cols = AppResponsive.gridColumns(
                    context,
                    mobile: 1,
                    tablet: 2,
                    desktop: 3,
                  );
                  if (cols == 1) {
                    return Column(
                      children:
                          links
                              .map(
                                (link) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _linkTile(context, link),
                                ),
                              )
                              .toList(),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 3.2,
                    ),
                    itemCount: links.length,
                    itemBuilder:
                        (context, index) => _linkTile(context, links[index]),
                  );
                },
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => UniversalWebView(
                    url: link.url,
                    viewId: link.title,
                    title: link.title,
                  ),
            ),
          );
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
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
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  final Color color;

  const _LinkItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.color,
  });
}
