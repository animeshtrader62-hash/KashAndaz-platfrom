import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final bool popOnSuccess;

  const SignupScreen({super.key, this.popOnSuccess = false});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signup(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phone: _phoneController.text.trim(),
          );
      
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Account created successfully. You are now logged in.'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
        if (widget.popOnSuccess) {
          Navigator.pop(context, true);
          return;
        }
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              return;
            }
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
        title: const Text('Sign Up'),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: Spacing.large),
                  
                  // Title
                  Text(
                    'Create Account',
                    style: AppTypography.display1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.small),
                  
                  Text(
                    'Sign up to start earning cashback',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.xl),
                  
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    validator: Validators.name,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: const Icon(Icons.person_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Spacing.buttonRadius),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: Spacing.medium),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'your.email@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Spacing.buttonRadius),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: Spacing.medium),
                  
                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '9876543210',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Spacing.buttonRadius),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: Spacing.medium),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    validator: Validators.password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Spacing.buttonRadius),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  
                  // Signup button
                  SizedBox(
                    height: Spacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Sign Up',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: Spacing.large),
                  
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.popOnSuccess) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(popOnSuccess: true),
                              ),
                            );
                            return;
                          }
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          'Login',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
