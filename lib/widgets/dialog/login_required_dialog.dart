import 'package:flutter/material.dart';

import '../../config/theme_config.dart';

class LoginRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onCancel;
  final BuildContext parentContext;

  const LoginRequiredDialog({
    super.key,
    this.title = 'Sign in to continue',
    this.message =
        'Create a free account or sign in to access your client portal, '
        'manage your immigration matter, and stay connected with Bansal Immigration.',
    this.onCancel,
    required this.parentContext,
  });

  static const _benefits = <_BenefitItem>[
    _BenefitItem(Icons.folder_open_rounded, 'View and upload your documents'),
    _BenefitItem(Icons.event_available_rounded, 'Book and manage appointments'),
    _BenefitItem(Icons.track_changes_rounded, 'Track your application progress'),
    _BenefitItem(
      Icons.chat_bubble_outline_rounded,
      'Message your migration consultant',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header band
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConfig.goldenYellow.withValues(alpha: 0.15),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            ThemeConfig.goldenYellow,
                            ThemeConfig.goldenYellow.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConfig.goldenYellow.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: ThemeConfig.navyBlue,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: ThemeConfig.navyBlue.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),

              // Benefits list
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  children: [
                    Text(
                      'With your account you can',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: ThemeConfig.navyBlue.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._benefits.map(
                      (benefit) => _BenefitRow(
                        icon: benefit.icon,
                        label: benefit.label,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, indent: 20, endIndent: 20),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConfig.goldenYellow,
                          foregroundColor: ThemeConfig.navyBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(parentContext).pop();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.login_rounded, size: 20),
                        label: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: ThemeConfig.navyBlue.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(parentContext).pop();
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'Create free account',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: ThemeConfig.navyBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(parentContext).pop();
                        onCancel?.call();
                      },
                      child: Text(
                        'Maybe later',
                        style: TextStyle(
                          color: ThemeConfig.navyBlue.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
}

class _BenefitItem {
  final IconData icon;
  final String label;

  const _BenefitItem(this.icon, this.label);
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: ThemeConfig.goldenYellow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: ThemeConfig.navyBlue.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
