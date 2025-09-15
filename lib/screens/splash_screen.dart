import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_background.dart';
import '../router/app_router.dart';
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
      // User provider will automatically check login status
      // and update the state accordingly
      context.go(AppRoutes.mainMenu);
    });
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
