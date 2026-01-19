import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/login_required.dart';
import '../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: AppTheme.scaffoldBg,
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
            ),
            body: const LoginRequiredView(
              message: 'Please login to view your profile.',
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile header - WHITE BACKGROUND with orange accent
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    children: [
                      // Avatar with orange ring
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryOrange,
                            width: 3,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryOrangeLight,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      const Text(
                        'John Doe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      const Text(
                        'john.doe@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      const Text(
                        '+91 98765 43210',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMedium),

                // Account section
                _buildSection(
                  context,
                  'Account',
                  [
                    _buildListTile(
                      context,
                      Icons.person_outline,
                      'Edit Profile',
                      () {},
                    ),
                    _buildListTile(
                      context,
                      Icons.lock_outline,
                      'Change Password',
                      () {},
                    ),
                    _buildListTile(
                      context,
                      Icons.payment,
                      'Payment Methods',
                      () {},
                    ),
                  ],
                ),

                const Divider(height: 1),

                // App section
                _buildSection(
                  context,
                  'App Settings',
                  [
                    _buildListTile(
                      context,
                      Icons.notifications_outlined,
                      'Notifications',
                      () {},
                    ),
                    _buildListTile(
                      context,
                      Icons.language,
                      'Language',
                      () {},
                      trailing: const Text('English'),
                    ),
                    _buildListTile(
                      context,
                      Icons.dark_mode_outlined,
                      'Dark Mode',
                      null,
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {},
                        activeColor: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 1),

                // Support section
                _buildSection(
                  context,
                  'Support',
                  [
                    _buildListTile(
                      context,
                      Icons.help_outline,
                      'Help & FAQ',
                      () {},
                    ),
                    _buildListTile(
                      context,
                      Icons.description_outlined,
                      'Terms & Conditions',
                      () {},
                    ),
                    _buildListTile(
                      context,
                      Icons.privacy_tip_outlined,
                      'Privacy Policy',
                      () {},
                    ),
                    _buildListTile(
                      context,
                      Icons.info_outline,
                      'About',
                      () {},
                      trailing: const Text('v1.0.0'),
                    ),
                  ],
                ),

                const Divider(height: 1),

                // Logout button
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showLogoutDialog(context, ref);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLarge),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: const LoginRequiredView(
          message: 'Please login to view your profile.',
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMedium,
            AppTheme.spacingLarge,
            AppTheme.spacingMedium,
            AppTheme.spacingSmall,
          ),
          child: Text(
            title,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback? onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: TextStyle(),
      ),
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: AppTheme.textLight)
              : null),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Logout', style: TextStyle()),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

