import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'core/navigation/main_scaffold.dart';

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
        // Bottom-tab destinations map to MainScaffold to keep the bottom nav persistent.
        '/home': (context) => const MainScaffold(initialIndex: 0),
        '/stores': (context) => const MainScaffold(initialIndex: 1),
        '/wallet': (context) => const MainScaffold(initialIndex: 2),
        '/missing_cashback': (context) => const MainScaffold(initialIndex: 3),
        '/profile': (context) => const MainScaffold(initialIndex: 4),
        '/transactions': (context) => const TransactionsScreen(),
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
      data: (_) => const MainScaffold(),
      loading: () => const MainScaffold(),
      error: (err, stack) => const MainScaffold(),
    );
  }
}


