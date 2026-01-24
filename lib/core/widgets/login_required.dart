import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../features/auth/screens/login_screen.dart';
import '../utils/page_transitions.dart';

class LoginRequiredView extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;

  const LoginRequiredView({
    super.key,
    this.title = 'Login required',
    this.message = 'Please login to continue.',
    this.actionLabel = 'Login',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push<bool>(
                    context,
                    SlidePageRoute<bool>(page: const LoginScreen(popOnSuccess: true)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
