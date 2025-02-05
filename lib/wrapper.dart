import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // We'll create this next
import 'providers/auth_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper rebuilding');
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isAuthenticated = authProvider.isAuthenticated;
        final userEmail = authProvider.user?.email;
        
        debugPrint('AuthWrapper Consumer rebuild');
        debugPrint('isAuthenticated: $isAuthenticated');
        debugPrint('userEmail: $userEmail');

        // Add a small delay to ensure the UI updates
        if (isAuthenticated && userEmail != null) {
          debugPrint('Scheduling navigation to HomeScreen');
          Future.microtask(() {
            debugPrint('Navigating to HomeScreen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          });
        }
        
        debugPrint('Returning current screen');
        return isAuthenticated ? const HomeScreen() : const LoginScreen();
      },
    );
  }
} 