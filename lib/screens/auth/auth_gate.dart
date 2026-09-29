import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../main.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showWelcome = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoggedIn) {
          if (authProvider.isAdmin) {
            return const AdminDashboardScreen();
          }

          return const MainNavigationScreen();
        }

        if (_showWelcome) {
          return WelcomeScreen(
            onGetStarted: () {
              setState(() {
                _showWelcome = false;
              });
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}