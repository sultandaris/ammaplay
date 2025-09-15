import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'database_helper.dart'; // <-- 1. IMPOR DATABASE HELPER
import 'aksi_surat.dart'; // <-- 2. IMPOR SURAH ACTION SCREEN

class SurahInfo {
  final String name;
  final bool isLocked;
  final bool isCompleted;

  SurahInfo({
    required this.name,
    this.isLocked = true,
    this.isCompleted = false,
  });
}

// Data statis ini tidak akan kita gunakan lagi, dihapus atau dikomentari
// final List<SurahInfo> level1Surahs = [ ... ];

class PilihSuratScreen extends StatefulWidget {
  const PilihSuratScreen({super.key});

  @override
  _PilihSuratScreenState createState() => _PilihSuratScreenState();
}

class _PilihSuratScreenState extends State<PilihSuratScreen> {
  // --- 2. PERUBAHAN UTAMA DIMULAI DI SINI ---
  late Future<List<SurahInfo>> _surahsFuture;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk memuat data dari DB saat screen diinisialisasi
    _surahsFuture = _loadSurahsFromDB();
  }

  // Fungsi untuk mengambil data dari database dan mengubahnya menjadi List<SurahInfo>
  Future<List<SurahInfo>> _loadSurahsFromDB() async {
    // Panggil query dari database helper
    final List<Map<String, dynamic>> surahMaps = await dbHelper.querySemuaSurah();

    // Jika tidak ada data di DB, kembalikan list kosong
    if (surahMaps.isEmpty) {
      return [];
    }

    // Ubah (map) setiap item dari database menjadi objek SurahInfo
    return surahMaps.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> surahData = entry.value;
      
      // Logika sementara untuk status terkunci dan selesai
      // Dalam aplikasi nyata, status ini harus disimpan di database (misal: di tabel user_progress)
      bool isLocked = index != 0; // Hanya surat pertama (An-Naas) yang terbuka
      bool isCompleted = index == 0; // Anggap surat pertama sudah selesai

      return SurahInfo(
        name: surahData['nama'], // Ambil 'nama' dari database
        isLocked: isLocked,
        isCompleted: isCompleted,
      );
    }).toList();
  }
  // --- AKHIR DARI PERUBAHAN LOGIKA DATA ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D4C56), // Warna background utama
      body: Stack(
        children: [
          // Awan di bagian bawah
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Icon(
              Icons.cloud,
              size: 400,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _LevelBanner(level: 1, isSpecial: true),
                          const SizedBox(height: 16),
                          
                          // --- 3. GUNAKAN FUTUREBUILDER UNTUK MENAMPILKAN GRID ---
                          FutureBuilder<List<SurahInfo>>(
                            future: _surahsFuture,
                            builder: (context, snapshot) {
                              // Tampilkan loading indicator saat data sedang dimuat
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(50.0),
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                );
                              }
                              // Tampilkan pesan error jika terjadi kesalahan
                              else if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                              }
                              // Jika data berhasil dimuat dan tidak kosong
                              else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                final surahs = snapshot.data!;
                                return _SurahGrid(surahs: surahs);
                              }
                              // Jika data kosong atau tidak ada
                              else {
                                return const Center(child: Text('Tidak ada surat ditemukan di database.', style: TextStyle(color: Colors.white)));
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget _buildCustomAppBar tidak berubah
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
          const Text(
            'Pilih Surat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 26,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black26,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            'assets/amma_play_logo.svg',
            height: 40,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// Widget _LevelBanner dan _SurahGrid tidak perlu diubah sama sekali
class _LevelBanner extends StatelessWidget {
  // ... (kode sama seperti sebelumnya) ...
  final int level;
  final bool isSpecial;

  const _LevelBanner({required this.level, this.isSpecial = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSpecial
                ? const Color(0xFF58C2A8)
                : const Color(0xFF4C98A4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF9D463), width: 3),
          ),
          child: Text(
            '#$level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9D463),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFFD4A23F), width: 4),
            ),
            child: Center(
              child: Text(
                'Level ${level.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Color(0xFF6B4F1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurahGrid extends StatelessWidget {
  // ... (kode sama seperti sebelumnya) ...
  final List<SurahInfo> surahs;

  const _SurahGrid({required this.surahs});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return _SurahCard(surah: surah);
      },
    );
  }
}
class _SurahCard extends StatelessWidget {
  final SurahInfo surah;

  const _SurahCard({required this.surah});

  @override
  Widget build(BuildContext context) {
    // Tampilan Kartu Terkunci (tidak bisa di-klik)
    if (surah.isLocked) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF08363D).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF246C79), width: 3),
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: Color(0xFFF9D463),
          size: 48,
        ),
      );
    }

    // Tampilan Kartu Terbuka (bisa di-klik)
    return Card(
      elevation: 4,
      color: Colors.transparent, // Buat Card transparan
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20), // Samakan radius untuk efek ripple
        onTap: () {
          // Aksi ketika kartu di-tap
          print('Surat ${surah.name} ditekan!');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahActionScreen(surah: surah),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFF9D463), // Warna dasar kartu terbuka
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4A23F), width: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Surat',
                style: TextStyle(
                  color: const Color(0xFF6B4F1A).withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              Text(
                surah.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B4F1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (surah.isCompleted)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, color: Color(0xFF6B4F1A), size: 18),
                      Icon(Icons.star_rounded, color: Color(0xFF6B4F1A), size: 18),
                      Icon(Icons.star_rounded, color: Color(0xFF6B4F1A), size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}