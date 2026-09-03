import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/dialog/login_required_dialog.dart';

class MyFilesQuickActionsCard extends StatelessWidget {
  final VoidCallback? onViewWorkflow;
  final VoidCallback? onMyFiles;
  final VoidCallback? onBilling;
  final VoidCallback? onMessage;
  final String? currentStageName;
  final int progressPercent;
  final String? matterNumber;

  const MyFilesQuickActionsCard({
    super.key,
    this.onViewWorkflow,
    this.onMyFiles,
    this.onBilling,
    this.onMessage,
    this.currentStageName,
    this.progressPercent = 0,
    this.matterNumber,
  });

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _FileAction(
        icon: Icons.account_tree_rounded,
        label: 'View Workflow',
        tint: const Color(0xFFFFF4D6),
        iconColor: ThemeConfig.goldenYellow,
        onTap: onViewWorkflow ?? () {},
      ),
      _FileAction(
        icon: Icons.folder_open_rounded,
        label: 'My Files',
        tint: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: onMyFiles ?? () {},
      ),
      _FileAction(
        icon: Icons.receipt_long_rounded,
        label: 'Billing',
        tint: const Color(0xFFFFF0E6),
        iconColor: const Color(0xFFE67E22),
        onTap: onBilling ?? () {},
      ),
      _FileAction(
        icon: Icons.chat_bubble_rounded,
        label: 'Messages',
        tint: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF7C3AED),
        onTap: onMessage ?? () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (AuthService.isAuthenticated) ...[
          _matterHeroCard(context),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: const Color(0xFFEEF1F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _actionTile(context: context, action: actions[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _matterHeroCard(BuildContext context) {
    final matterName =
        AuthService.selectedMatterName ?? 'No matter selected';
    final stage =
        (currentStageName != null && currentStageName!.trim().isNotEmpty)
            ? currentStageName!
            : 'Not started';
    final progress = progressPercent.clamp(0, 100);
    final matterNo = (matterNumber != null && matterNumber!.trim().isNotEmpty)
        ? matterNumber!
        : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: () => _openSwitchDialog(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ThemeConfig.navyBlue, Color(0xFF2D3B8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: ThemeConfig.navyBlue.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE MATTER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.folder_special_rounded,
                                color: ThemeConfig.goldenYellow,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matterName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (matterNo != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      matterNo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.65,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Switch Case',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Stage',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$progress%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ThemeConfig.goldenYellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              ThemeConfig.goldenYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required _FileAction action,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _handleAuth(context, action.onTap),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ThemeConfig.navyBlue,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSwitchDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final dialogWidth =
        isWide ? (screenWidth > 1024 ? 440.0 : 400.0) : screenWidth * 0.92;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => Dialog(
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
                        color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
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
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  const _FileAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });
}
