import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../utils/responsive_utils.dart';
import '../../workflow/workflow_screen.dart';
import 'my_files_quick_action_card.dart';

class MyFilesScreen extends StatelessWidget {
  MyFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.white,
      appBar: AppBar(
        title: const Text(
          'My Files',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: ThemeConfig.goldenYellow,
        elevation: 0,
        foregroundColor: Colors.white,
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
                  MyFilesQuickActionsCard(
                    onViewWorkflow: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WorkflowScreen(),
                        ),
                      );
                    },
                    onBilling: () {
                      /*Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BillingScreen(),
                            ),
                          );*/
                      showSnack(
                        context,
                        "This feature will be available in a future update.",
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _MyFileItem {
  final String label;
  final IconData icon;
  final Color color;
  final bool vertical;
  final String? helperText;
  final VoidCallback onTap;

  _MyFileItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.vertical,
    required this.onTap,
    this.helperText,
  });
}

extension ColorUtils on Color {
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
