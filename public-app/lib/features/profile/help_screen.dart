import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Help & FAQ is coming soon.\n\nFor now, please contact support from the app store listing or check back after the next update.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
