import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../services/auth_service.dart';
import '../common/pressable_scale.dart';
import '../dialog/login_signup_dialog.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onBookAppointment;
  final VoidCallback? onHealthInsurance;
  final VoidCallback? onUpcomingDeadlines;
  final VoidCallback? onPRCalculator;
  final VoidCallback? onStudentFundCalculator;
  final VoidCallback? onOccupationSearch;
  final VoidCallback? onPostCodeChecker;
  final VoidCallback? onImportantLinks;
  final VoidCallback? onEnglishRequirement;
  final VoidCallback? onVACSearch;

  const QuickActionsCard({
    super.key,
    required this.onBookAppointment,
    this.onHealthInsurance,
    this.onUpcomingDeadlines,
    this.onPRCalculator,
    this.onStudentFundCalculator,
    this.onOccupationSearch,
    this.onPostCodeChecker,
    this.onImportantLinks,
    this.onEnglishRequirement,
    this.onVACSearch,
  });

  static const double _radius = 14;

  void _handleTap(BuildContext context, VoidCallback callback) {
    if (AuthService.isAuthenticated) {
      callback();
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: LoginSignupDialog(parentContext: context),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 600;

        // Web: compact horizontal tiles. Mobile: original vertical/horizontal mix.
        final tilePadding = isWeb ? 12.0 : 16.0;
        final iconSize = isWeb ? 16.0 : 14.0;
        final fontSize = isWeb ? 12.5 : 13.5;
        final iconPad = isWeb ? 6.0 : 4.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
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
                      color: const Color(0xFFF9B000),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              StaggeredGrid.count(
                crossAxisCount: isWeb ? 6 : 4,
                mainAxisSpacing: isWeb ? 10 : 12,
                crossAxisSpacing: isWeb ? 10 : 12,
                children: [
                  // Row 1 — all tiles horizontal at uniform height
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: isWeb ? 0.85 : 1.1,
                    child: _horizontalTile(
                      context: context,
                      icon: Icons.event_available_rounded,
                      label: 'Book Appointment',
                      gradient: const [Color(0xFF2E7D32), Color(0xFF81C784)],
                      onTap: onBookAppointment,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      padding: tilePadding,
                      iconPad: iconPad,
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: isWeb ? 0.85 : 1.1,
                    child: _horizontalTile(
                      context: context,
                      icon: Icons.health_and_safety_rounded,
                      label: 'Health Insurance',
                      gradient: const [Color(0xFF6D4C41), Color(0xFFBCAAA4)],
                      onTap: onHealthInsurance ?? () {},
                      iconSize: iconSize,
                      fontSize: fontSize,
                      padding: tilePadding,
                      iconPad: iconPad,
                    ),
                  ),

                  StaggeredGridTile.count(
                    crossAxisCellCount: isWeb ? 2 : 4,
                    mainAxisCellCount: isWeb ? 0.85 : 1.1,
                    child: _horizontalTile(
                      context: context,
                      icon: Icons.calculate_rounded,
                      label: 'PR Calculator',
                      gradient: const [Color(0xFFC2185B), Color(0xFFF48FB1)],
                      onTap: onPRCalculator ?? () {},
                      iconSize: iconSize,
                      fontSize: fontSize,
                      padding: tilePadding,
                      iconPad: iconPad,
                    ),
                  ),

                  // Row 2 — small tiles: all horizontal, 3-per-row on web, 2 on mobile
                  _tile(
                    context: context,
                    icon: Icons.school_rounded,
                    label: 'Student Fund Calculator',
                    gradient: const [Color(0xFF3949AB), Color(0xFF9FA8DA)],
                    onTap: onStudentFundCalculator ?? () {},
                    iconSize: iconSize,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad,
                    isWeb: isWeb,
                  ),

                  _tile(
                    context: context,
                    icon: Icons.manage_search_rounded,
                    label: 'Occupation Search',
                    gradient: const [Color(0xFF00838F), Color(0xFF80DEEA)],
                    onTap: onOccupationSearch ?? () {},
                    iconSize: iconSize,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad,
                    isWeb: isWeb,
                  ),

                  _tile(
                    context: context,
                    icon: Icons.location_on_rounded,
                    label: 'Post Code Checker',
                    gradient: const [Color(0xFF7B1FA2), Color(0xFFCE93D8)],
                    onTap: onPostCodeChecker ?? () {},
                    iconSize: iconSize,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad,
                    isWeb: isWeb,
                  ),

                  _tile(
                    context: context,
                    icon: Icons.link_rounded,
                    label: 'Important Links',
                    gradient: const [Color(0xFF1565C0), Color(0xFF90CAF9)],
                    onTap: onImportantLinks ?? () {},
                    iconSize: iconSize,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad,
                    isWeb: isWeb,
                  ),

                  _tile(
                    context: context,
                    icon: Icons.record_voice_over_rounded,
                    label: 'English Requirement',
                    gradient: const [Color(0xFFE64A19), Color(0xFFFFAB91)],
                    onTap: onEnglishRequirement ?? () {},
                    iconSize: iconSize,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad,
                    isWeb: isWeb,
                  ),

                  _tile(
                    context: context,
                    icon: Icons.travel_explore_rounded,
                    label: 'VAC Search',
                    gradient: const [Color(0xFF00695C), Color(0xFF80CBC4)],
                    onTap: onVACSearch ?? () {},
                    iconSize: iconSize,
                    fontSize: fontSize - 0.5,
                    padding: tilePadding - 2,
                    iconPad: iconPad,
                    isWeb: isWeb,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Vertical tile — icon top, label bottom (mobile big tiles)
  Widget _verticalTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
    required double padding,
  }) {
    return PressableScale(
      onTap: () => _handleTap(context, onTap),
      borderRadius: BorderRadius.circular(_radius),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: iconSize, color: Colors.white),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal tile — icon left, label right (web big tiles + mobile PR Calculator)
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
    return PressableScale(
      onTap: () => _handleTap(context, onTap),
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
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  color: Colors.white,
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
    required bool isWeb,
  }) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 2,
      mainAxisCellCount: isWeb ? 0.85 : 1.1,
      child: PressableScale(
        onTap: () => _handleTap(context, onTap),
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
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                    color: Colors.white,
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
}
