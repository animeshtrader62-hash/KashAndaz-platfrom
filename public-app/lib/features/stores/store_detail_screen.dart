import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/providers.dart';
import '../auth/screens/login_screen.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/utils/constants.dart';
import '../home/models/home_models.dart';
import '../activate_cashback/models/activate_models.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/store_logo.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final Store store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  bool _isActivating = false;
  bool _termsExpanded = false;

  Future<void> _activateCashback() async {
    debugPrint('[ActivateCashback] Clicked');
    debugPrint('[ActivateCashback] store_id=${widget.store.id} store=${widget.store.name}');
    final canProceed = await _ensureAuthenticated();
    if (!mounted) {
      return;
    }
    if (!canProceed) {
      debugPrint('[ActivateCashback] Cancelled (not authenticated)');
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
      debugPrint('[ActivateCashback] click_id=${activateResponse.clickId}');
      debugPrint('[ActivateCashback] redirect_url=${activateResponse.deepLink}');

      final redirectUrl = activateResponse.deepLink.trim();
      if (redirectUrl.isEmpty) {
        if (mounted) {
          _showError('Redirect URL is missing for ${widget.store.name}.');
        }
        return;
      }

      final uri = Uri.tryParse(redirectUrl);
      if (uri == null) {
        if (mounted) {
          _showError('Invalid redirect URL for ${widget.store.name}.');
        }
        return;
      }

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) {
        return;
      }
      if (!ok) {
        _showError('Could not open ${widget.store.name}.');
      }
    } catch (e) {
      debugPrint('[ActivateCashback] error=$e');
      if (mounted) {
        _showError('Unable to activate cashback. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isActivating = false);
      }
    }
  }

  Future<bool> _ensureAuthenticated() async {
    final storage = ref.read(secureStorageProvider);
    final isAuth = await storage.isAuthenticated();
    if (!mounted) {
      return false;
    }
    if (isAuth) {
      return true;
    }

    final result = await Navigator.push<bool>(
      context,
      SlidePageRoute<bool>(page: const LoginScreen(popOnSuccess: true)),
    );

    if (!mounted) {
      return false;
    }

    if (result == true) {
      return await storage.isAuthenticated();
    }
    return false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.store.description?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.store.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: null,
            icon: const Icon(Icons.notifications_none_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _card(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _StoreLogo(logoUrl: widget.store.logoUrl, storeName: widget.store.name),
                    const SizedBox(height: 12),
                    Text(
                      widget.store.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212121),
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF616161),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Earn up to ${widget.store.cashbackRate} Cashback',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1FA463),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isActivating ? null : _activateCashback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isActivating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Activate Cashback & Shop',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('How Cashback Works'),
                    const SizedBox(height: 12),
                    _InfoStep(
                      icon: Icons.touch_app_outlined,
                      title: 'Activate Cashback',
                      description: 'Click the Activate Cashback button above.',
                    ),
                    const SizedBox(height: 10),
                    const _InfoStep(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Shop Normally',
                      description: 'Complete your purchase on the store website.',
                    ),
                    const SizedBox(height: 10),
                    const _InfoStep(
                      icon: Icons.check_circle_outline,
                      title: 'Cashback Tracked',
                      description: 'Your cashback is tracked automatically.',
                    ),
                    const SizedBox(height: 10),
                    const _InfoStep(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Withdraw',
                      description: 'Withdraw once cashback is confirmed.',
                    ),
                  ],
                ),
              ),
              _card(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Important Information'),
                    SizedBox(height: 12),
                    _KeyValueRow(label: 'Tracking Time', value: 'Typically within 24–72 hours'),
                    SizedBox(height: 10),
                    _KeyValueRow(label: 'Confirmation Time', value: 'Typically 30–90 days'),
                    SizedBox(height: 10),
                    _KeyValueRow(
                      label: 'Missing Cashback',
                      value: 'Can be raised after confirmation time',
                    ),
                  ],
                ),
              ),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _termsExpanded = !_termsExpanded),
                      child: Row(
                        children: [
                          const Expanded(child: _SectionTitle('Terms & Conditions')),
                          Icon(
                            _termsExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    if (_termsExpanded) ...[
                      const SizedBox(height: 12),
                      const _Bullet('Cashback applies only on eligible orders.'),
                      const _Bullet('Complete checkout in the same session after activation.'),
                      const _Bullet('Cancellations/returns may void cashback.'),
                      const _Bullet('Final cashback depends on store tracking and confirmation.'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  final String logoUrl;
  final String storeName;
  const _StoreLogo({required this.logoUrl, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StoreLogo(url: logoUrl, storeName: storeName, size: 72),
    );
  }
}

class _InfoStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
