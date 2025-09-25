import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/family_user_provider.dart';
import 'aksi_surat.dart';
import 'models/family_models.dart';

class PilihSuratScreen extends ConsumerStatefulWidget {
  const PilihSuratScreen({super.key});

  @override
  ConsumerState<PilihSuratScreen> createState() => _PilihSuratScreenState();
}

class _PilihSuratScreenState extends ConsumerState<PilihSuratScreen> {
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

                          // Use Riverpod provider to get surahs with progress
                          Consumer(
                            builder: (context, ref, child) {
                              final currentUser = ref.watch(familyUserProvider);
                              final userId = currentUser.user?.idPengguna;

                              if (userId == null) {
                                return const Center(
                                  child: Text(
                                    'Please log in to view surahs.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              // UNIFIED PROGRESS: Direct access to unified state - NO AsyncValue needed!
                              final surahs = ref.watch(
                                enhancedSurahsWithProgressByUserProvider(
                                  userId,
                                ),
                              );
                              final isLoading = ref.watch(
                                progressLoadingProvider,
                              );
                              final error = ref.watch(progressErrorProvider);

                              // Simple conditional rendering - no .when() needed!
                              if (isLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(50.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }

                              if (error != null) {
                                return Center(
                                  child: Text(
                                    'Error: $error',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              if (surahs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Tidak ada surat ditemukan di database.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              return _SurahGrid(surahs: surahs);
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
  final List<SurahWithProgress> surahs;

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
        final surahWithProgress = surahs[index];
        return _SurahCard(surahWithProgress: surahWithProgress);
      },
    );
  }
}

class _SurahCard extends StatelessWidget {
  final SurahWithProgress surahWithProgress;

  const _SurahCard({required this.surahWithProgress});

  @override
  Widget build(BuildContext context) {
    final surah = surahWithProgress.surah;
    final isLocked = !surahWithProgress.isUnlocked;
    final totalStars = surahWithProgress.progres?.totalBintang ?? 0;

    // Debug print untuk melihat nilai progress
    print(
      'DEBUG: Surah ${surah.namaLatin} - Total Stars: $totalStars, Progress: ${surahWithProgress.progres}',
    );

    // Tampilan Kartu Terkunci (tidak bisa di-klik)
    if (isLocked) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF08363D).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF246C79), width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_rounded,
              color: Color(0xFFF9D463),
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              'Surat',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              surah.namaLatin,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            // Tampilkan bintang kosong untuk surat terkunci
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star_outline_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 14,
                );
              }),
            ),
          ],
        ),
      );
    }

    // Tampilan Kartu Terbuka (bisa di-klik)
    return Card(
      elevation: 4,
      color: Colors.transparent, // Buat Card transparan
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ), // Samakan radius untuk efek ripple
        onTap: () {
          // Aksi ketika kartu di-tap
          print('Surat ${surah.namaLatin} ditekan!');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SurahActionScreen(surahWithProgress: surahWithProgress),
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
                surah.namaLatin,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B4F1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Tampilkan bintang sesuai dengan progress yang sudah dicapai
              // Selalu tampilkan bintang untuk menunjukkan progress visual
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < totalStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: index < totalStars
                          ? const Color(0xFF6B4F1A)
                          : const Color(0xFF6B4F1A).withOpacity(0.3),
                      size: 16,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
