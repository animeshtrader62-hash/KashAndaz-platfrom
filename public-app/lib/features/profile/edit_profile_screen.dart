import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final String initialName;
  final String initialEmail;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: null,
              child: Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.divider),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Editing is available, saving will be enabled soon.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
