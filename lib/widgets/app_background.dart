import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Warna dasar latar belakang
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF33747A),
          child: CustomPaint(painter: BackgroundPatternPainter()),
        ),
        // Awan di Atas
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 150),
            painter: TopCloudPainter(),
          ),
        ),
        // Awan di Bawah
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 150),
            painter: BottomCloudPainter(),
          ),
        ),
      ],
    );
  }
}

// --- CustomPainter (sama seperti sebelumnya) ---
// (Anda bisa salin kelas BackgroundPatternPainter, TopCloudPainter, BottomCloudPainter dari kode splash screen sebelumnya ke sini)
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    final double spacing = 60;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TopCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFF0EFEA) // Warna awan sedikit krem
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 50);
    path.quadraticBezierTo(size.width * 0.1, 0, size.width * 0.25, 30);
    path.quadraticBezierTo(size.width * 0.4, -20, size.width * 0.55, 30);
    path.quadraticBezierTo(size.width * 0.7, 0, size.width * 0.85, 30);
    path.quadraticBezierTo(size.width * 0.95, 0, size.width, 50);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFF0EFEA) // Warna awan sedikit krem
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height,
      size.width * 0.25,
      size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height + 20,
      size.width * 0.55,
      size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height,
      size.width * 0.85,
      size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.95,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
