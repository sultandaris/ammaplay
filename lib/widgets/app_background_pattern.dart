import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBackgroundPattern extends StatelessWidget {
  const AppBackgroundPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Warna dasar latar belakang (harus di bawah/pertama)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF387C87), // Warna biru langit di atas
                Color(0xFF0D4C56), // Warna biru tua di bawah
              ],
            ),
          ),
        ),
        // Background pattern menggunakan pattern.svg
        Positioned.fill(
          child: Opacity(
            opacity: 0.1,
            child: SvgPicture.asset(
              'assets/pattern.svg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        
      ],
    );
  }
}


