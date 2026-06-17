import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Themed snack-bar helper. Use instead of raw [SnackBar] calls.
class AppSnackBar {
  static void success(BuildContext context, String message) {
    _show(context, message, AppTheme.successGreen, Icons.check_circle_outline_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppTheme.errorRed, Icons.error_outline_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppTheme.primaryBlue, Icons.info_outline_rounded);
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }
}
