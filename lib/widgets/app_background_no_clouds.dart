import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBackgroundNoClouds extends StatelessWidget {
  const AppBackgroundNoClouds({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Warna dasar latar belakang (harus di bawah/pertama)
        Container(
          decoration: const BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
              Color(0xFF387C87), // Warna biru langit di atas
              Color(0xFF010566B), // Warna putih di bawah
              ],
            ),
            ),
          ),
    // Background pattern menggunakan bgWave.svg (di atas background color)
        Positioned.fill(
          child: Opacity(
            opacity: 0.08, // Meningkatkan opacity karena SVG asli hanya 0.1
            child: SvgPicture.asset(
              'assets/pattern.svg',
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.flip(
            flipY: true,
            child: SvgPicture.asset(
              'assets/cloud.svg',
              width: MediaQuery.of(context).size.width,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}


