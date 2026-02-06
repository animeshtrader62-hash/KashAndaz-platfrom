import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String message;
  final String backButtonLabel;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.message,
    this.backButtonLabel = 'Go Back',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: Text(backButtonLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
