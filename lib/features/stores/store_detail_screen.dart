import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../core/api/providers.dart';
import '../../core/storage/secure_storage.dart';
import '../auth/screens/login_screen.dart';
import '../../core/utils/constants.dart';
import '../home/models/home_models.dart';
import '../activate_cashback/models/activate_models.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final Store store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  bool _isActivating = false;

  Future<void> _activateCashback() async {
    final canProceed = await _ensureAuthenticated();
    if (!canProceed) {
      return;
    }

    if (!widget.store.isActive) {
      _showError('This store is currently inactive');
      return;
    }

    setState(() => _isActivating = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final response = await apiClient.post(
        ApiConstants.activateCashback,
        data: {
          'store_id': widget.store.id,
        },
      );

      final activateResponse = ActivateCashbackResponse.fromJson(response.data);
      
      // Try to launch deep link
      final deepLink = Uri.parse(activateResponse.deepLink);
      final canLaunch = await canLaunchUrl(deepLink);
      
      if (canLaunch) {
        await launchUrl(
          deepLink,
          mode: LaunchMode.externalApplication,
        );
        
        if (mounted) {
          _showTrackingActivatedScreen(activateResponse);
        }
      } else {
        _showError('Could not open ${widget.store.name}. Please install the app.');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isActivating = false);
      }
    }
  }

  void _showTrackingActivatedScreen(ActivateCashbackResponse response) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingActivatedScreen(response: response),
      ),
    );
  }

  Future<bool> _ensureAuthenticated() async {
    final storage = ref.read(secureStorageProvider);
    final isAuth = await storage.isAuthenticated();
    if (isAuth) {
      return true;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login required'),
        content: const Text('Please login or sign up to activate cashback.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Login'),
          ),
        ],
      ),
    );

    if (proceed != true) {
      return false;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(popOnSuccess: true),
      ),
    );

    if (result == true) {
      return await storage.isAuthenticated();
    }
    return false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.store.name),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store header
            Container(
              padding: const EdgeInsets.all(Spacing.screenPadding),
              color: AppColors.surface,
              child: Column(
                children: [
                  Container(
                    width: Spacing.logoLarge,
                    height: Spacing.logoLarge,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(Spacing.cardRadius),
                    ),
                    child: Icon(
                      Icons.store,
                      color: AppColors.primary,
                      size: Spacing.iconXL,
                    ),
                  ),
                  const SizedBox(height: Spacing.medium),
                  Text(
                    widget.store.name,
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.small),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.medium,
                      vertical: Spacing.small,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Cashback: ${widget.store.cashbackRate}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: Spacing.large),
            
            // How it works
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to Earn Cashback', style: AppTypography.h3),
                  const SizedBox(height: Spacing.medium),
                  _buildStep(
                    1,
                    'Activate Cashback',
                    'Click the button below to activate tracking',
                  ),
                  _buildStep(
                    2,
                    'Shop on ${widget.store.name}',
                    'You will be redirected to the store app/website',
                  ),
                  _buildStep(
                    3,
                    'Earn Cashback',
                    'Complete your purchase and get ${widget.store.cashbackRate} cashback',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: Spacing.large),
            
            // Important notes
            Container(
              margin: const EdgeInsets.symmetric(horizontal: Spacing.screenPadding),
              padding: const EdgeInsets.all(Spacing.medium),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(Spacing.cardRadius),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: Spacing.iconMedium,
                      ),
                      const SizedBox(width: Spacing.small),
                      Text(
                        'Important',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.small),
                  Text(
                    '• Activate cashback before shopping\n'
                    '• Complete purchase in same session\n'
                    '• Cashback appears within 72 hours\n'
                    '• Available for withdrawal after confirmation',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: Spacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.screenPadding),
          child: SizedBox(
            height: Spacing.buttonHeight,
            child: ElevatedButton(
              onPressed: _isActivating ? null : _activateCashback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Spacing.buttonRadius),
                ),
              ),
              child: _isActivating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Activate Cashback & Shop',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h4),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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

/// Tracking activated confirmation screen
class TrackingActivatedScreen extends StatelessWidget {
  final ActivateCashbackResponse response;

  const TrackingActivatedScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cashback Activated'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: Spacing.large),
              Text(
                'Cashback Tracking Activated!',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.medium),
              Text(
                response.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.small),
              Text(
                'Store: ${response.storeName}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Container(
                padding: const EdgeInsets.all(Spacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(Spacing.cardRadius),
                ),
                child: Column(
                  children: [
                    Text(
                      'Click ID: ${response.clickId}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your purchase to earn cashback',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                height: Spacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
