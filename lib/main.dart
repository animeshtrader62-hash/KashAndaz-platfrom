import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/home/home_screen.dart';
import 'core/utils/constants.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/missing_cashback/missing_cashback_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'KashAndaz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/missing_cashback': (context) => const MissingCashbackScreen(),
      },
      home: const AuthGate(),
    );
  }
}

/// Auth gate that decides initial route based on auth state
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (AppConfig.bypassAuth) {
          return const HomeScreen();
        }
        if (user != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
      loading: () => AppConfig.bypassAuth
          ? const HomeScreen()
          : const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
      error: (err, stack) => AppConfig.bypassAuth
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}


