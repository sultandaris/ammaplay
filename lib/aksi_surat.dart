import 'bermain.dart'; // Import layar Bermain
import 'menghafal_screen.dart'; // Import layar Menghafal
import 'memaknai_screen.dart'; // Import layar Memaknai
import 'package:flutter/material.dart';
import 'hafalan_surat.dart'; // Import SurahInfo

class SurahActionScreen extends StatelessWidget {
  final SurahInfo surah;

  const SurahActionScreen({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D4C56), // Warna background yang sama
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            const SizedBox(height: 40),
            // Menampilkan nama surat yang dipilih
            Text(
              'Surat ${surah.name}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black26,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            // Tiga Opsi Aksi
            _ActionCard(
              title: 'Membaca',
              icon: Icons.play_circle_fill_rounded,
              color: const Color(0xFFF9D463),
              onTap: () {
                print('Opsi BERMAIN untuk surat ${surah.name} dipilih.');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BermainScreen(surahInfo: surah),
                  ),
                );
              },
            ),
            _ActionCard(
              title: 'Menghafal',
              icon: Icons.psychology_rounded, // Ikon otak untuk menghafal
              color: const Color(0xFF58C2A8),
              onTap: () {
                print('Opsi MENGHAFAL untuk surat ${surah.name} dipilih.');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MenghafalScreen(surahInfo: surah),
                  ),
                );
              },
            ),
            _ActionCard(
              title: 'Memaknai',
              icon: Icons.menu_book_rounded, // Ikon buku untuk makna
              color: const Color(0xFF4C98A4),
              onTap: () {
                print('Opsi MEMAKNAI untuk surat ${surah.name} dipilih.');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MemaknaiScreen(surahInfo: surah),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // AppBar kustom yang mirip dengan layar sebelumnya
  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9D463),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          // Placeholder agar tombol kembali tidak di tengah
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// Widget kustom untuk kartu opsi yang bisa digunakan ulang
class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Card(
        elevation: 5,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
