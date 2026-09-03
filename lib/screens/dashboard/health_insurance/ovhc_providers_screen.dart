import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';
import '../../../widgets/webview/universal_webview.dart';

/// Shared OVHC provider list used by tourist / temporary / other visitor visas.
class OvhcProvidersScreen extends StatelessWidget {
  final String title;

  const OvhcProvidersScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleName: title,
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
                children: [
                  _providerTile(
                    context,
                    title: 'BUPA',
                    color: Colors.blue,
                    url: UrlConstants.touristVisa.bupaOVHC,
                  ),
                  const SizedBox(height: 16),
                  _providerTile(
                    context,
                    title: 'Allianz',
                    color: Colors.green,
                    url: UrlConstants.touristVisa.allianzOVHC,
                  ),
                  const SizedBox(height: 16),
                  _providerTile(
                    context,
                    title: 'Nib / IMAN',
                    color: Colors.orange,
                    url: UrlConstants.temporaryGraduate.nibIMAN,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _providerTile(
    BuildContext context, {
    required String title,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => UniversalWebView(url: url, viewId: title, title: title),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.health_and_safety, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
