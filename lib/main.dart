import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/transaksi_provider.dart';
import 'screens/kasir_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/member_dashboard.dart';
import 'screens/operator_dashboard.dart';
import 'screens/owner_dashboard.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),
        ChangeNotifierProvider(create: (_) => TransaksiProvider()),
      ],
      child: MaterialApp(
        title: 'CAR WASH',
        theme: AppTheme.light,
        home: const _AppHome(),
      ),
    );
  }
}

class _AppHome extends StatelessWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          return LoginScreen(initialError: auth.errorMessage);
        }

        return switch (auth.role) {
          'kasir' => const KasirDashboard(),
          'operator' => const OperatorDashboard(),
          'owner' => const OwnerDashboard(),
          'member' => const MemberDashboard(),
          _ => const Scaffold(
            body: Center(child: Text('Role akun tidak dikenali.')),
          ),
        };
      },
    );
  }
}
