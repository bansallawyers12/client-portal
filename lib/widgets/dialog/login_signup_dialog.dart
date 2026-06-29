import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class LoginSignupDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onCancel;
  final BuildContext parentContext;

  const LoginSignupDialog({
    super.key,
    this.title = "Login Required",
    this.message = "Please login or sign up to continue.",
    this.onCancel,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with circular background
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeConfig.goldenYellow.withValues(alpha:0.2),
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(Icons.lock_outline, size: 36, color: ThemeConfig.goldenYellow),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.navyBlue,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: ThemeConfig.navyBlue.withValues(alpha:0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Login and Sign Up buttons (primary row)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.goldenYellow,
                      foregroundColor: ThemeConfig.navyBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(parentContext).pop();
                      Navigator.pushNamed(parentContext, '/login');
                    },
                    child: const Text("Login"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.navyBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(parentContext).pop();
                      Navigator.pushNamed(parentContext, '/register');
                    },
                    child: const Text("Sign Up"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cancel button (secondary row)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ThemeConfig.navyBlue.withValues(alpha:0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(parentContext).pop();
                  onCancel?.call();
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(color: ThemeConfig.navyBlue.withValues(alpha:0.7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}