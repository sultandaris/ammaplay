import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_background_no_clouds.dart';
import '../router/app_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/hafalan_surat.dart';
import 'kontrol_orang_tua_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

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
          const AppBackgroundNoClouds(),
          // Logo Amma Play - posisi tetap
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: SvgPicture.asset(
                  'assets/amma_play_logo.svg',
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              ),
            ),
          ),
          // Menu content
          if (!_isMenuOpen)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 120.0), // Space untuk logo
                child: _buildDefaultMenu(),
              ),
            ),

          if (!_isMenuOpen)
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.10), // Jarak sebagai persentase dari tinggi layar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                context.push(AppRoutes.settings);
              },
              child: _buildSmallButton('assets/settingakun.svg'),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KontrolOrangTuaScreen(),
                  ),
                );
              },
              child: _buildSmallButton('assets/settingortu.svg'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _toggleMenu,
          child: _buildLargeMenuButton("MENU"),
        ),
        const SizedBox(height: 20),
        // Kartu Hafalan
        _buildHafalanCard(),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return Padding(
      padding: const EdgeInsets.only(top: 100.0), // Space untuk logo
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background mainmenuelement.svg
            SvgPicture.asset(
              'assets/mainmenuelement.svg',
              width: MediaQuery.of(context).size.width * 0.85,
              fit: BoxFit.contain,
            ),
          // Posisi menu items sesuai dengan 4 menustair dalam mainmenuelement
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tulisan MENU
              Text(
                "MENU",
                style: const TextStyle(
                  fontFamily: 'Swiss721',
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(offset: Offset(-1.5, -1.5), color: Color(0xFFD58900)),
                    Shadow(offset: Offset(1.5, -1.5), color: Color(0xFFD58900)),
                    Shadow(offset: Offset(1.5, 1.5), color: Color(0xFFD58900)),
                    Shadow(offset: Offset(-1.5, 1.5), color: Color(0xFFD58900)),
                  ],
                ),
              ),
              const SizedBox(height: 25), // Space setelah tulisan MENU
              // Menu item 1 - Hafalan
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PilihSuratScreen()),
                  );
                },
                child: _buildMenuItemText("Hafalan"),
              ),
              const SizedBox(height: 18),
              // Menu item 2 - Bermain
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/bermain');
                },
                child: _buildMenuItemText("Bermain"),
              ),
              const SizedBox(height: 18),
              // Menu item 3 - Karakter
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/karakter');
                },
                child: _buildMenuItemText("Karakter"),
              ),
              const SizedBox(height: 18),
              // Menu item 4 - Kelas
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/kelas');
                },
                child: _buildMenuItemText("Kelas"),
              ),
              const SizedBox(height: 50),
            ],
          ),
          // Tombol Close di bawah
          Positioned(
            bottom: 0, // Dipindah ke posisi yang lebih aman
            child: GestureDetector(
              onTap: _toggleMenu,
              child: const CircleAvatar(
                radius: 25, // Diperbesar kembali agar lebih jelas
                backgroundColor: Color.fromARGB(255, 204, 86, 77),
                child: Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMenuItemText(String text) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background mainmenustair.svg
        SvgPicture.asset(
          'assets/mainmenustair.svg',
          width: 250, // Diperbesar untuk mengikuti proporsi gambar
          fit: BoxFit.contain,
        ),
        // Text di atas background
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Sunday Magic',
            fontSize: 34, // Sedikit dikecilkan agar proporsional
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [
              Shadow(offset: Offset(-1, -1), color: Color(0xFF387C87)),
              Shadow(offset: Offset(1, -1), color: Color(0xFF387C87)),
              Shadow(offset: Offset(1, 1), color: Color(0xFF387C87)),
              Shadow(offset: Offset(-1, 1), color: Color(0xFF387C87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallButton(String svgAsset) {
    return Container(
      width: 60,
      height: 60,
      child: SvgPicture.asset(
        svgAsset,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLargeMenuButton(String text) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Elemen besar (background)
        SvgPicture.asset(
          'assets/menuelement.svg',
          width: 300,
          fit: BoxFit.contain,
        ),
        // Elemen kecil dengan tulisan PLAY
        Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              'assets/menustair.svg',
              width: 200,
              fit: BoxFit.contain,
            ),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Swiss721',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                shadows: const [
                  Shadow(offset: Offset(-1.5, -1.5), color: Color(0xFFD58900)),
                  Shadow(offset: Offset(1.5, -1.5), color: Color(0xFFD58900)),
                  Shadow(offset: Offset(1.5, 1.5), color: Color(0xFFD58900)),
                  Shadow(offset: Offset(-1.5, 1.5), color: Color(0xFFD58900)),
                ],
              ),
            ),
          ],
        ),
      ],
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


}
