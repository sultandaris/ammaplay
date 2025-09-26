import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/pengaturan.dart';
import '../login_screen.dart' as login;
import '../signup_screen.dart' as signup;

// Route paths
class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const mainMenu = '/main-menu';
  static const settings = '/settings';
  static const login = '/login';
  static const signup = '/signup';
}

// Authentication guard function
bool _isUserLoggedIn() {
  // This will be called to check authentication status
  // In a real app, you might need to access the provider here
  // For now, we'll rely on the splash screen navigation
  return true; // Will be overridden by splash screen logic
}

// Router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // Splash Screen - Entry point
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth Screen - Login/Signup selection
    GoRoute(
      path: AppRoutes.auth,
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // Main Menu Screen
    GoRoute(
      path: AppRoutes.mainMenu,
      name: 'main-menu',
      builder: (context, state) => const MainMenuScreen(),
    ),

    // Settings Screen
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreenMinimalist(),
    ),

    // Login Screen
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) =>
          const login.LoginScreen(), // Your login screen
    ),

    // Signup Screen
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) =>
          const signup.SignUpScreen(), // Your signup screen
    ),
  ],

  // Error handling
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.splash),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
