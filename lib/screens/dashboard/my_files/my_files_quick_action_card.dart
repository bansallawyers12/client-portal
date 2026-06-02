import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../config/theme_config.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/dialog/login_required_dialog.dart';

class MyFilesQuickActionsCard extends StatelessWidget {
  final VoidCallback? onViewWorkflow;
  final VoidCallback? onBilling;
  final VoidCallback? onDocumentStatus;
  final VoidCallback? onUpcomingDeadlines;
  final VoidCallback? onMessage;

  const MyFilesQuickActionsCard({
    super.key,
    this.onViewWorkflow,
    this.onBilling,
    this.onDocumentStatus,
    this.onUpcomingDeadlines,
    this.onMessage,
  });

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 600;
        final tilePadding = isWeb ? 12.0 : 16.0;
        final iconSize = isWeb ? 20.0 : 18.0;
        final fontSize = isWeb ? 12.5 : 13.5;
        final iconPad = isWeb ? 8.0 : 5.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
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
                      color: const Color(0xFFF9B000),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'My Files',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (AuthService.isAuthenticated) ...[
                _matterSelector(context),
                const SizedBox(height: 16),
              ],

              StaggeredGrid.count(
                crossAxisCount: isWeb ? 6 : 4,
                mainAxisSpacing: isWeb ? 10 : 12,
                crossAxisSpacing: isWeb ? 10 : 12,
                children: [
                  // Big tiles: horizontal at uniform height
                  StaggeredGridTile.count(
                    crossAxisCellCount: isWeb ? 3 : 2,
                    mainAxisCellCount: isWeb ? 0.85 : 1.1,
                    child: _horizontalTile(
                      context: context,
                      icon: Icons.account_tree_rounded,
                      label: 'View Workflow',
                      gradient: const [Color(0xFF6A1B9A), Color(0xFFCE93D8)],
                      onTap: onViewWorkflow ?? () {},
                      iconSize: iconSize,
                      fontSize: fontSize,
                      padding: tilePadding,
                      iconPad: iconPad,
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: isWeb ? 3 : 2,
                    mainAxisCellCount: isWeb ? 0.85 : 1.1,
                    child: _horizontalTile(
                      context: context,
                      icon: Icons.receipt_long_rounded,
                      label: 'Billing',
                      gradient: const [Color(0xFFC62828), Color(0xFFEF9A9A)],
                      onTap: onBilling ?? () {},
                      iconSize: iconSize,
                      fontSize: fontSize,
                      padding: tilePadding,
                      iconPad: iconPad,
                    ),
                  ),

                  // Small tiles
                  _tile(
                    context: context,
                    icon: Icons.chat_bubble_rounded,
                    label: 'Messages',
                    gradient: const [Color(0xFF2E7D32), Color(0xFF81C784)],
                    onTap: onMessage ?? () {},
                    iconSize: iconSize - 2,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad - 2,
                    crossAxisCellCount: isWeb ? 3 : 2,
                    isWeb: isWeb,
                  ),

                  /*_tile(
                    context: context,
                    icon: Icons.folder_copy_rounded,
                    label: 'Documents',
                    gradient: const [Color(0xFF1565C0), Color(0xFF90CAF9)],
                    onTap: onDocumentStatus ?? () {},
                    iconSize: iconSize - 2,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad - 2,
                    crossAxisCellCount: 2,
                    isWeb: isWeb,
                  ),

                  _tile(
                    context: context,
                    icon: Icons.alarm_rounded,
                    label: 'Upcoming Deadlines',
                    gradient: const [Color(0xFFE65100), Color(0xFFFFCC80)],
                    onTap: onUpcomingDeadlines ?? () {},
                    iconSize: iconSize - 2,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad - 2,
                    crossAxisCellCount: isWeb ? 2 : 4,
                    isWeb: isWeb,
                  ),*/
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _matterSelector(BuildContext context) {
    void openDialog() {
      final screenWidth = MediaQuery.of(context).size.width;
      final isWide = screenWidth >= 600;
      final dialogWidth = isWide
          ? (screenWidth > 1024 ? 440.0 : 400.0)
          : screenWidth * 0.92;

      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ThemeConfig.navyBlue.withValues(alpha: 0.14),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 22,
                      isWide ? 26 : 22,
                      isWide ? 28 : 22,
                      isWide ? 22 : 18,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeConfig.navyBlue,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isWide ? 11 : 9),
                          decoration: BoxDecoration(
                            color: ThemeConfig.goldenYellow.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: ThemeConfig.goldenYellow,
                            size: isWide ? 24 : 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Matter',
                                style: TextStyle(
                                  fontSize: isWide ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeConfig.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Switch your active matter',
                                style: TextStyle(
                                  fontSize: isWide ? 13 : 12,
                                  color: ThemeConfig.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close icon
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: ThemeConfig.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: ThemeConfig.white.withValues(alpha: 0.7),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 22,
                      isWide ? 22 : 18,
                      isWide ? 28 : 22,
                      isWide ? 24 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current matter display
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 16 : 14,
                            vertical: isWide ? 13 : 11,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeConfig.goldenYellow.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ThemeConfig.goldenYellow.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.folder_rounded,
                                  color: ThemeConfig.goldenYellow,
                                  size: isWide ? 16 : 15,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENTLY ACTIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ThemeConfig.textSecondaryLight,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AuthService.selectedMatterName ?? 'No matter selected',
                                      style: TextStyle(
                                        fontSize: isWide ? 14 : 13,
                                        fontWeight: FontWeight.w700,
                                        color: ThemeConfig.navyBlue,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isWide ? 16 : 13),

                        // Description
                        Text(
                          'Select a different matter to update your active view. All case actions will apply to the new matter.',
                          style: TextStyle(
                            fontSize: isWide ? 14 : 13,
                            color: ThemeConfig.textSecondaryLight,
                            height: 1.55,
                          ),
                        ),
                        SizedBox(height: isWide ? 22 : 18),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: isWide ? 46 : 44,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: ThemeConfig.borderLight,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    foregroundColor: ThemeConfig.textSecondaryLight,
                                    backgroundColor: ThemeConfig.backgroundLight,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: isWide ? 14.5 : 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: isWide ? 46 : 44,
                                child: ElevatedButton(
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
                                    foregroundColor: ThemeConfig.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.swap_horiz_rounded, size: 17),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Switch',
                                        style: TextStyle(
                                          fontSize: isWide ? 14.5 : 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: openDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ThemeConfig.navyBlue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Folder icon badge
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.folder_special_rounded,
                  color: ThemeConfig.goldenYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Matter info
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
                      AuthService.selectedMatterName ?? 'No Matter Selected',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ThemeConfig.navyBlue,
                      ),
                      maxLines: 2,
                    ),
                    if (AuthService.selectedMatterId != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        'ID: ${AuthService.selectedMatterId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: ThemeConfig.textSecondaryLight.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Switch button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: ThemeConfig.goldenYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: ThemeConfig.white, size: 14),
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

  // Horizontal tile — icon left, label right (web big tiles)
  Widget _horizontalTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
    required double padding,
    required double iconPad,
  }) {
    return InkWell(
      onTap: () => _handleAuth(context, onTap),
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding + 2, vertical: padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(iconPad),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: iconSize, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  height: 1.3,
                ),
              ),
            ),
            //const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  // Small tile — always horizontal, wraps in StaggeredGridTile
  Widget _tile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
    required double padding,
    required double iconPad,
    required int crossAxisCellCount,
    required bool isWeb,
  }) {
    return StaggeredGridTile.count(
      crossAxisCellCount: crossAxisCellCount,
      mainAxisCellCount: isWeb ? 0.85 : 1.1,
      child: InkWell(
        onTap: () => _handleAuth(context, onTap),
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padding + 2, vertical: padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: iconSize, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                    height: 1.25,
                  ),
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
