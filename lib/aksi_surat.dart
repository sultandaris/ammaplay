import 'bermain.dart';
import 'menghafal_screen.dart';
import 'memaknai_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/family_models.dart';
import 'providers/family_user_provider.dart';

class SurahActionScreen extends ConsumerStatefulWidget {
  final SurahWithProgress surahWithProgress;

  const SurahActionScreen({super.key, required this.surahWithProgress});

  @override
  ConsumerState<SurahActionScreen> createState() => _SurahActionScreenState();
}

class _SurahActionScreenState extends ConsumerState<SurahActionScreen> {
  @override
  Widget build(BuildContext context) {
    final surah = widget.surahWithProgress.surah;
    final currentUser = ref.watch(familyUserProvider);

    // UNIFIED PROGRESS: Menggunakan direct access ke progress untuk surah ini
    final currentProgress = ref.watch(surahProgressProvider(surah.idSurat));
    final isLoading = ref.watch(progressLoadingProvider);
    final error = ref.watch(progressErrorProvider);

    final currentStars = currentProgress?.totalBintang ?? 0;

    // DEBUG: Print untuk debugging progress dan user
    print('=== DEBUG UNIFIED PROGRESS ===');
    print('Surah: ${surah.namaLatin}');
    print('Surah ID: ${surah.idSurat}');
    print('Current User: ${currentUser.user}');
    print('User ID: ${currentUser.user?.idPengguna}');
    print('Is Logged In: ${currentUser.isLoggedIn}');
    print('Progress object: $currentProgress');
    print('Current Stars: $currentStars');
    print('Is Loading: $isLoading');
    print('Error: $error');
    print('==============================');

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D4C56),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      print('Error with unified progress: $error');
    }

    return _buildScreenContent(context, surah, currentStars);
  }

  Widget _buildScreenContent(
    BuildContext context,
    EnhancedSurah surah,
    int currentProgress,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D4C56),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            const SizedBox(height: 40),
            Text(
              'Surat ${surah.namaLatin}',
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
            const SizedBox(height: 20),
            _buildProgressIndicator(currentProgress),
            const SizedBox(height: 30),
            _ActionCard(
              title: 'Membaca',
              icon: Icons.play_circle_fill_rounded,
              color: const Color(0xFFF9D463),
              isAvailable: true,
              isCompleted: currentProgress >= 1,
              onTap: () {
                _navigateToScreen(
                  context,
                  BermainScreen(surah: surah),
                  'membaca',
                );
              },
            ),
            _ActionCard(
              title: 'Menghafal',
              icon: Icons.psychology_rounded,
              color: const Color(0xFF58C2A8),
              isAvailable: currentProgress >= 1,
              isCompleted: currentProgress >= 2,
              onTap: () {
                if (currentProgress >= 1) {
                  _navigateToScreen(
                    context,
                    MenghafalScreen(surah: surah),
                    'menghafal',
                  );
                } else {
                  _showLockedMessage(
                    'Selesaikan tahap Membaca terlebih dahulu',
                  );
                }
              },
            ),
            _ActionCard(
              title: 'Memaknai',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF4C98A4),
              isAvailable: currentProgress >= 2,
              isCompleted: currentProgress >= 3,
              onTap: () {
                if (currentProgress >= 2) {
                  _navigateToScreen(
                    context,
                    MemaknaiScreen(surah: surah),
                    'memaknai',
                  );
                } else {
                  _showLockedMessage(
                    'Selesaikan tahap Menghafal terlebih dahulu',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentProgress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF9D463), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Progress Pembelajaran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: index < currentProgress
                      ? const Color(0xFFF9D463)
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(
            '$currentProgress / 3 Tahapan Selesai',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToScreen(
    BuildContext context,
    Widget screen,
    String stage,
  ) async {
    print('=== DEBUG NAVIGATING TO SCREEN ===');
    print('Stage: $stage');

    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => screen));

    print('=== DEBUG NAVIGATION RESULT ===');
    print('Result: $result');
    print('Result type: ${result.runtimeType}');

    if (result == true) {
      print('DEBUG: Calling _updateProgress for stage: $stage');
      await _updateProgress(stage);
    } else {
      print('DEBUG: Navigation result was not true, no progress update');
    }
  }

  Future<void> _updateProgress(String stage) async {
    final currentUser = ref.read(familyUserProvider);

    print('=== UNIFIED UPDATE PROGRESS ===');
    print('Stage: $stage');
    print('Current User: ${currentUser.user}');
    print('User ID: ${currentUser.user?.idPengguna}');

    if (currentUser.user?.idPengguna == null) {
      print('UPDATE GAGAL: User ID is null');
      return;
    }

    final surah = widget.surahWithProgress.surah;
    // Get current progress from unified system
    final currentProgress = ref.read(surahProgressProvider(surah.idSurat));
    final currentStars = currentProgress?.totalBintang ?? 0;

    print('Surah ID: ${surah.idSurat}');
    print('Current Stars: $currentStars');

    int newStars = currentStars;

    switch (stage) {
      case 'membaca':
        if (currentStars < 1) newStars = 1;
        break;
      case 'menghafal':
        if (currentStars < 2) newStars = 2;
        break;
      case 'memaknai':
        if (currentStars < 3) newStars = 3;
        break;
    }

    print('New Stars: $newStars');

    if (newStars > currentStars) {
      // UNIFIED PROGRESS: Use unified notifier - NO MANUAL INVALIDATION NEEDED!
      final unifiedNotifier = ref.read(unifiedProgressProvider.notifier);
      final updateSuccess = await unifiedNotifier.updateProgress(
        surah.idSurat,
        newStars,
      );

      print('Update berhasil: $updateSuccess');

      // NO MANUAL INVALIDATION - Unified system automatically notifies all listeners!
      print('UNIFIED SYSTEM: Auto-notification to all UI components');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updateSuccess
                  ? 'Selamat! Anda mendapat ${newStars - currentStars} bintang!'
                  : 'Gagal update progress!',
            ),
            backgroundColor: updateSuccess
                ? const Color(0xFF58C2A8)
                : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      print(
        'Tidak ada update: newStars ($newStars) <= currentStars ($currentStars)',
      );
    }
    print('===============================');
  }

  void _showLockedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Method untuk reset progress untuk testing - UNIFIED SYSTEM
  Future<void> _resetProgressForTesting() async {
    final currentUser = ref.read(familyUserProvider);

    print('=== UNIFIED RESET ===');
    print('Current User: ${currentUser.user}');
    print('User ID: ${currentUser.user?.idPengguna}');

    if (currentUser.user?.idPengguna == null) {
      print('RESET GAGAL: User ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RESET GAGAL: User tidak ditemukan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final surah = widget.surahWithProgress.surah;
    print('Surah ID untuk reset: ${surah.idSurat}');

    // UNIFIED SYSTEM: Use unified notifier - NO MANUAL DB ACCESS!
    final unifiedNotifier = ref.read(unifiedProgressProvider.notifier);
    final resetSuccess = await unifiedNotifier.resetProgress(surah.idSurat);

    print('Reset berhasil: $resetSuccess');

    // NO MANUAL INVALIDATION - Unified system handles it automatically!
    print('UNIFIED SYSTEM: Auto-refresh all UI components');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resetSuccess
                ? 'Progress direset ke 0 bintang untuk testing'
                : 'GAGAL mereset progress',
          ),
          backgroundColor: resetSuccess ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  // Method untuk clear semua progress di database - UNIFIED SYSTEM
  Future<void> _clearAllProgressForDebugging() async {
    try {
      // UNIFIED SYSTEM: Use unified notifier for all database operations
      final unifiedNotifier = ref.read(unifiedProgressProvider.notifier);
      final clearSuccess = await unifiedNotifier.clearAllProgress();

      print('=== UNIFIED CLEAR ALL ===');
      print('Clear success: $clearSuccess');
      print('AUTO-REFRESH: All UI components updated');
      print('==========================');

      // NO MANUAL INVALIDATION - Unified system handles everything!

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              clearSuccess
                  ? 'Cleared all progress from database'
                  : 'Failed to clear progress',
            ),
            backgroundColor: clearSuccess ? Colors.purple : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error clearing progress: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing progress: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method untuk debug - melihat semua record di database
  Future<void> _debugShowAllRecords() async {
    final databaseHelper = ref.read(databaseHelperV3Provider);
    try {
      final db = await databaseHelper.database;
      final allRecords = await db.query('progres_pengguna');

      print('=== ALL PROGRESS RECORDS IN DATABASE ===');
      print('Total records: ${allRecords.length}');
      for (final record in allRecords) {
        print('Record: $record');
      }
      print('========================================');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found ${allRecords.length} progress records in DB. Check console for details.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error reading database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          // DEBUG BUTTONS - Remove in production
          Row(
            children: [
              GestureDetector(
                onTap: _resetProgressForTesting,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'RESET',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _clearAllProgressForDebugging,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CLEAR ALL',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () async {
                  // UNIFIED SYSTEM: Force refresh from database
                  final unifiedNotifier = ref.read(
                    unifiedProgressProvider.notifier,
                  );
                  await unifiedNotifier.refreshFromDatabase();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unified system refreshed from database!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'REFRESH',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _debugShowAllRecords,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SHOW DB',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isAvailable,
    required this.isCompleted,
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
              color: isAvailable ? color : color.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isAvailable
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAvailable ? icon : Icons.lock_rounded,
                  color: isAvailable ? Colors.white : Colors.grey.shade300,
                  size: 40,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isAvailable
                              ? Colors.white
                              : Colors.grey.shade300,
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                    ],
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
