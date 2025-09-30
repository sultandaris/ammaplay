import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RewardScreen extends StatelessWidget {
  final VoidCallback? onComplete;
  final String title;
  final String subtitle;

  const RewardScreen({
    super.key,
    this.onComplete,
    this.title = '🎉 Selamat!',
    this.subtitle = 'Anda telah menyelesaikan tugas!',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reward badge SVG
            SvgPicture.asset(
              'assets/badge.svg',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            
            // Title text
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(-2.0, -2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(2.0, -2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(-2.0, 2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(0.0, -2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(2.0, 0.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(0.0, 2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(-2.0, 0.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Subtitle text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      offset: Offset(-1.0, -1.0),
                      color: Colors.orange,
                      blurRadius: 0.5,
                    ),
                    Shadow(
                      offset: Offset(1.0, -1.0),
                      color: Colors.orange,
                      blurRadius: 0.5,
                    ),
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      color: Colors.orange,
                      blurRadius: 0.5,
                    ),
                    Shadow(
                      offset: Offset(-1.0, 1.0),
                      color: Colors.orange,
                      blurRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Continue button
            GestureDetector(
              onTap: () {
                if (onComplete != null) {
                  onComplete!();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9D463),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFD4A23F),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Lanjutkan',
                  style: TextStyle(
                    color: Color(0xFF6B4F1A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
