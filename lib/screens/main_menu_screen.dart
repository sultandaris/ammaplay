import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_background.dart';
import '../router/app_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/hafalan_surat.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: SvgPicture.asset(
                    'assets/amma_play_logo.svg',
                    width: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                const SizedBox(height: 20),
                if (!_isMenuOpen) _buildDefaultMenu(),
              ],
            ),
          ),

          Positioned(
            bottom: 60,
            left: 20,
            child: SvgPicture.asset('assets/character.svg', width: 150),
          ),

          if (_isMenuOpen) _buildPopupMenu(),
        ],
      ),
    );
  }

  Widget _buildDefaultMenu() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                context.push(AppRoutes.settings);
              },
              child: _buildSmallButton(Icons.settings),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/info');
              },
              child: _buildSmallButton(Icons.info_outline),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _toggleMenu,
          child: _buildLargeMenuButton("PLAY"),
        ),
        const SizedBox(height: 20),
        // Kartu Hafalan
        _buildHafalanCard(),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFF9D577),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white, width: 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "AMMA PLAY",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 15),
            _buildMenuOptionButton("Hafalan", const Color(0xFF5AB6A8), () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PilihSuratScreen()),
              );
            }),
            const SizedBox(height: 10),
            _buildMenuOptionButton("Bermain", const Color(0xFF5AB6A8), () {
              Navigator.pushNamed(context, '/bermain');
            }),
            const SizedBox(height: 10),
            _buildMenuOptionButton("Karakter", const Color(0xFF5AB6A8), () {
              Navigator.pushNamed(context, '/karakter');
            }),
            const SizedBox(height: 10),
            _buildMenuOptionButton("Kelas", const Color(0xFF5AB6A8), () {
              Navigator.pushNamed(context, '/kelas');
            }),
            const SizedBox(height: 20),
            // Tombol Close
            GestureDetector(
              onTap: _toggleMenu, // Panggil fungsi untuk menutup menu
              child: const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF9D577),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildLargeMenuButton(String text) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9D577),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildHafalanCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text("Hafalan", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          SvgPicture.asset(
            'assets/badge.svg',
            width: 50,
          ), // Ganti dengan gambar badge
          const SizedBox(height: 5),
          const Text(
            "#1 PEMULA",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 5),
          const Text(
            "Surat: An-Nas\n1 / 38",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Menggunakan parameter onTap yang diberikan
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
