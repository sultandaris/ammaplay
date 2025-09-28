import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_background.dart';
import '../router/app_router.dart';
import '../providers/family_user_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      _checkAuthenticationAndNavigate();
    });
  }

  void _checkAuthenticationAndNavigate() async {
    print('🔍 Checking authentication status...');
    
    // Wait for the family user provider to finish loading
    final userState = ref.read(familyUserProvider);
    print('📱 User state: isLoading=${userState.isLoading}, isLoggedIn=${userState.isLoggedIn}, user=${userState.user?.namaPengguna}');
    
    // If still loading, wait a bit more
    if (userState.isLoading) {
      print('⏳ Still loading, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _checkAuthenticationAndNavigate();
        return;
      }
    }
    
    if (userState.isLoggedIn && userState.user != null) {
      // User is logged in, go to main menu
      print('✅ User is authenticated, navigating to main menu');
      context.go(AppRoutes.mainMenu);
    } else {
      // User is not logged in, go to auth screen
      print('❌ User is not authenticated, navigating to auth screen');
      context.go(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          Center(
            child: SvgPicture.asset(
              'assets/amma_play_logo.svg',
              width: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
