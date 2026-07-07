import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/dialog/login_required_dialog.dart';

class MyFilesQuickActionsCard extends StatelessWidget {
  final VoidCallback? onViewWorkflow;
  final VoidCallback? onBilling;
  final VoidCallback? onMessage;

  const MyFilesQuickActionsCard({
    super.key,
    this.onViewWorkflow,
    this.onBilling,
    this.onMessage,
  });

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _FileAction(
        icon: Icons.account_tree_rounded,
        label: 'View Workflow',
        gradient: const [Color(0xFF6A1B9A), Color(0xFFCE93D8)],
        onTap: onViewWorkflow ?? () {},
      ),
      _FileAction(
        icon: Icons.receipt_long_rounded,
        label: 'Billing',
        gradient: const [Color(0xFFC62828), Color(0xFFEF9A9A)],
        onTap: onBilling ?? () {},
      ),
      _FileAction(
        icon: Icons.chat_bubble_rounded,
        label: 'Messages',
        gradient: const [Color(0xFF2E7D32), Color(0xFF81C784)],
        onTap: onMessage ?? () {},
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
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
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ThemeConfig.goldenYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Files',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: ThemeConfig.navyBlue,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage your case, documents and payments',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (AuthService.isAuthenticated) ...[
            const SizedBox(height: 16),
            _matterSelector(context),
          ],
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _actionTile(context: context, action: actions[0]),
                        const SizedBox(height: 14),
                        _actionTile(context: context, action: actions[2]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionTile(context: context, action: actions[1]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required _FileAction action,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: () => _handleAuth(context, action.onTap),
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: action.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: action.gradient.first.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 108),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _matterSelector(BuildContext context) {
    void openDialog() {
      final screenWidth = MediaQuery.of(context).size.width;
      final isWide = screenWidth >= 600;
      final dialogWidth =
          isWide ? (screenWidth > 1024 ? 440.0 : 400.0) : screenWidth * 0.92;

      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder:
            (dialogContext) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 16,
                vertical: 24,
              ),
              child: SizedBox(
                width: dialogWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeConfig.surfaceLight,
                    borderRadius: BorderRadius.circular(_radius),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeConfig.navyBlue.withValues(alpha: 0.14),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isWide ? 28 : 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ThemeConfig.goldenYellow.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(_radius),
                            ),
                            child: const Icon(
                              Icons.folder_special_rounded,
                              color: ThemeConfig.goldenYellow,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Switch matter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ThemeConfig.navyBlue,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                            color: ThemeConfig.textSecondaryLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.pushNamed(
                              context,
                              '/matters',
                              arguments: {'from_my_files': true},
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeConfig.goldenYellow,
                            foregroundColor: ThemeConfig.navyBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radius),
                            ),
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text(
                            'Choose matter',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: openDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ThemeConfig.goldenYellow.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(_radius),
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  color: ThemeConfig.goldenYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE MATTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ThemeConfig.textSecondaryLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AuthService.selectedMatterName ?? 'No matter selected',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ThemeConfig.navyBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ThemeConfig.goldenYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: ThemeConfig.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Switch',
                      style: TextStyle(
                        color: ThemeConfig.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAuth(BuildContext context, VoidCallback onTap) {
    if (!AuthService.isAuthenticated) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => LoginRequiredDialog(parentContext: context),
      );
      return;
    }
    onTap();
  }
}

class _FileAction {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FileAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}
