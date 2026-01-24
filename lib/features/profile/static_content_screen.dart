import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum StaticContentType { terms, privacy, about }

class StaticContentScreen extends StatelessWidget {
  final StaticContentType contentType;

  const StaticContentScreen({
    super.key,
    required this.contentType,
  });

  String get _title {
    switch (contentType) {
      case StaticContentType.terms:
        return 'Terms & Conditions';
      case StaticContentType.privacy:
        return 'Privacy Policy';
      case StaticContentType.about:
        return 'About';
    }
  }

  String get _body {
    switch (contentType) {
      case StaticContentType.terms:
        return 'Terms & Conditions are coming soon.';
      case StaticContentType.privacy:
        return 'Privacy Policy is coming soon.';
      case StaticContentType.about:
        return 'KashAndaz\n\nVersion v1.0.0\n\nMore details are coming soon.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _body,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
