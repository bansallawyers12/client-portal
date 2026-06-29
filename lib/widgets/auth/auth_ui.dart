import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme_config.dart';
import '../../utils/app_loader.dart';

class AuthColors {
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const hint = Color(0xFF94A3B8);
  static const body = Color(0xFF475569);
}

class AuthRadius {
  static const double corner = 14;
  static BorderRadius get borderRadius => BorderRadius.circular(corner);
}

void authNavigateBack(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    navigator.pushReplacementNamed('/home');
  }
}

InputDecoration authInputDecoration({
  required String label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    labelStyle: const TextStyle(
      color: AuthColors.hint,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: const TextStyle(color: AuthColors.hint, fontSize: 14),
    filled: true,
    fillColor: AuthColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: AuthRadius.borderRadius,
      borderSide: const BorderSide(color: AuthColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AuthRadius.borderRadius,
      borderSide: const BorderSide(color: AuthColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AuthRadius.borderRadius,
      borderSide: const BorderSide(color: ThemeConfig.goldenYellow, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AuthRadius.borderRadius,
      borderSide: const BorderSide(color: ThemeConfig.errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AuthRadius.borderRadius,
      borderSide: const BorderSide(color: ThemeConfig.errorColor, width: 1.5),
    ),
  );
}

class AuthScreenShell extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showBackButton;

  const AuthScreenShell({
    super.key,
    required this.child,
    required this.title,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: Navigator.of(context).canPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) authNavigateBack(context);
        },
        child: Scaffold(
          backgroundColor: AuthColors.background,
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leading:
                showBackButton
                    ? IconButton(
                      onPressed: () => authNavigateBack(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Back',
                    )
                    : null,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFCA28), ThemeConfig.goldenYellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AuthRadius.corner),
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(AuthRadius.corner),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeConfig.goldenYellow.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeConfig.navyBlue.withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: child,
                  ),
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

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: AuthRadius.borderRadius,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFCA28), ThemeConfig.goldenYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: ThemeConfig.goldenYellow.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 34, color: ThemeConfig.navyBlue),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ThemeConfig.navyBlue,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AuthColors.body,
          ),
        ),
      ],
    );
  }
}

class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: AuthColors.surface,
        borderRadius: AuthRadius.borderRadius,
        border: Border.all(color: AuthColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConfig.goldenYellow,
          foregroundColor: ThemeConfig.navyBlue,
          disabledBackgroundColor:
              ThemeConfig.goldenYellow.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AuthRadius.borderRadius),
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: AppLoader(size: 22),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ThemeConfig.navyBlue,
                  ),
                ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prompt,
          style: const TextStyle(color: AuthColors.body, fontSize: 14),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: ThemeConfig.goldenYellow,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
