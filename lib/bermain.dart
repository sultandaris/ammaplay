import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'database_helper_v3.dart';
import 'models/family_models.dart';
import 'package:just_audio/just_audio.dart'; // Untuk audio playback

class BermainScreen extends StatefulWidget {
  final EnhancedSurah surah;

  const BermainScreen({super.key, required this.surah});

  @override
  State<BermainScreen> createState() => _BermainScreenState();
}

class _BermainScreenState extends State<BermainScreen> {
  final dbHelper = DatabaseHelperV3.instance;
  final _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  bool _isChangingAyat = false;
  Map<String, dynamic>? _surahDetail;
  List<Map<String, dynamic>> _ayatList = [];
  int _currentAyatIndex = 0;

  // Tracking completion
  Set<int> _playedAyats = {}; // Track which ayats have been played
  bool _hasCompletedReading = false;

  @override
  void dispose() {
    _audioPlayer.dispose(); // Sangat penting untuk melepaskan resource
    super.dispose();
  }

  // Track ayat yang sudah diplay
  void _markAyatAsPlayed(int ayatIndex) {
    if (!_playedAyats.contains(ayatIndex)) {
      setState(() {
        _playedAyats.add(ayatIndex);
      });

      print(
        'DEBUG: Ayat ${ayatIndex + 1} marked as played. Total played: ${_playedAyats.length}/${_ayatList.length}',
      );

      // Check if all ayats have been played
      if (_playedAyats.length >= _ayatList.length && !_hasCompletedReading) {
        print('DEBUG: All ayats completed! Calling _completeReadingTask');
        _completeReadingTask();
      }
    } else {
      print('DEBUG: Ayat ${ayatIndex + 1} already marked as played');
    }
  }

  // Complete reading task and return with result
  void _completeReadingTask() {
    setState(() {
      _hasCompletedReading = true;
    });

    print('DEBUG: Reading task completed! All ayats played.');

    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '🎉 Selamat! Anda telah mendengarkan semua ayat. Tugas membaca selesai!',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Return to previous screen with success result after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate completion
      }
    });
  }

  void _setupAudioListener() {
    // Set up persistent audio player listener
    _audioPlayer.playerStateStream.listen((playerState) {
      print(
        'DEBUG: Audio player state changed: ${playerState.processingState}',
      );
      if (playerState.processingState == ProcessingState.completed) {
        print('DEBUG: Audio completed for ayat ${_currentAyatIndex + 1}');
        _markAyatAsPlayed(_currentAyatIndex);
      }
    });
  }

  Future<void> _loadSurahData() async {
    try {
      final ayat = await dbHelper.queryAyatBySurah(widget.surah.idSurat);
      setState(() {
        _surahDetail = {
          'nama': widget.surah.namaLatin,
          'arti': widget.surah.artiNama,
          'jumlah_ayat': widget.surah.jumlahAyat,
        };
        _ayatList = ayat;
        _isLoading = false;
      });
      // --- AUDIO LOGIC ---
      _loadAudioForCurrentAyat(); // Muat audio untuk ayat pertama
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error memuat data surat: $e");
    }
  }

  Future<void> _loadAudioForCurrentAyat() async {
    if (_ayatList.isEmpty) return;
    final audioUrl = _ayatList[_currentAyatIndex]['audio_url'];
    if (audioUrl != null) {
      try {
        await _audioPlayer.setUrl(audioUrl);
      } catch (e) {
        print("Error loading audio source: $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAudioListener();
    _loadSurahData();
  }

  Future<void> _goToNextAyat() async {
    if (_currentAyatIndex < _ayatList.length - 1 && !_isChangingAyat) {
      final newIndex = _currentAyatIndex + 1;
      final audioUrl = _ayatList[newIndex]['audio_url'];

      // Update state sekali saja - ayat dan loading bersamaan
      setState(() {
        _isChangingAyat = true;
        _currentAyatIndex = newIndex;
      });

      // Load audio setelah UI terupdate
      if (audioUrl != null) {
        try {
          await _audioPlayer.setUrl(audioUrl);
        } catch (e) {
          print("Error loading audio: $e");
        }
      }

      // Selesai loading
      if (mounted) {
        setState(() {
          _isChangingAyat = false;
        });
      }
    }
  }

  Future<void> _goToPreviousAyat() async {
    if (_currentAyatIndex > 0 && !_isChangingAyat) {
      final newIndex = _currentAyatIndex - 1;
      final audioUrl = _ayatList[newIndex]['audio_url'];

      // Update state sekali saja - ayat dan loading bersamaan
      setState(() {
        _isChangingAyat = true;
        _currentAyatIndex = newIndex;
      });

      // Load audio setelah UI terupdate
      if (audioUrl != null) {
        try {
          await _audioPlayer.setUrl(audioUrl);
        } catch (e) {
          print("Error loading audio: $e");
        }
      }

      // Selesai loading
      if (mounted) {
        setState(() {
          _isChangingAyat = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D4C56),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_ayatList.isEmpty || _surahDetail == null) {
      return const Center(
        child: Text(
          'Data surat tidak ditemukan.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    final currentAyat = _ayatList[_currentAyatIndex];

    return Stack(
      children: [
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildCustomAppBar(),
                const SizedBox(height: 10),
                _buildSurahHeader(),
                const SizedBox(height: 20),
                _buildAyahCard(currentAyat),
                const SizedBox(height: 20),
                _buildAudioControls(),
                const Spacer(),
                _buildPagination(currentAyat),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _RoundButton(icon: Icons.close, onTap: () => Navigator.of(context).pop()),
      SvgPicture.asset('assets/amma_play_logo.svg', height: 40),
    ],
  );

  Widget _buildSurahHeader() => Column(
    children: [
      _InfoPill(text: _surahDetail!['nama'] ?? 'Nama Surat', isLarge: true),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _InfoPill(text: _surahDetail!['arti'] ?? 'Arti'),
          const SizedBox(width: 8),
          _InfoPill(text: '${_surahDetail!['jumlah_ayat'] ?? 0} Ayat'),
        ],
      ),
    ],
  );

  Widget _buildAyahCard(Map<String, dynamic> ayat) => Container(
    padding: const EdgeInsets.all(24),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF08363D), width: 10),
    ),
    child: _isChangingAyat
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat ayat...', style: TextStyle(fontSize: 16)),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ayat['teks_arab'] ?? 'Teks Arab tidak tersedia',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 32,
                  fontFamily: 'LPMQ',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ayat['teks_latin'] ?? 'Teks Latin tidak tersedia',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${ayat['nomor'] ?? '0'}. ${ayat['teks_indonesia'] ?? 'Terjemahan tidak tersedia'}',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
            ],
          ),
  );

  Widget _buildAudioControls() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final isPlaying = playerState?.playing ?? false;

        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return Column(
          children: [
            // Progress indicator for completion
            if (_playedAyats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF9D463),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Progress Mendengarkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_playedAyats.length} dari ${_ayatList.length} ayat telah didengar',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    _audioPlayer.seek(Duration.zero);
                    _audioPlayer.play();
                  },
                ),
                _ControlButton(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: () {
                    if (isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      // Jika sudah selesai, putar dari awal
                      if (processingState == ProcessingState.completed) {
                        _audioPlayer.seek(Duration.zero);
                      }
                      _audioPlayer.play();
                    }
                  },
                  isLarge: true,
                ),
                _ControlButton(
                  icon: Icons.stop_rounded,
                  onTap: () {
                    _audioPlayer.stop();
                    _loadAudioForCurrentAyat(); // Siapkan lagi untuk play berikutnya
                  },
                ),
                _ControlButton(icon: Icons.volume_up_rounded, onTap: () {}),
                // DEBUG: Manual completion button for testing
                _ControlButton(
                  icon: Icons.check_circle,
                  onTap: () {
                    print('DEBUG: Manual completion button pressed');
                    // Mark current ayat as played for testing
                    _markAyatAsPlayed(_currentAyatIndex);
                  },
                ),
                // DEBUG: Complete all ayats button for testing
                _ControlButton(
                  icon: Icons.done_all,
                  onTap: () {
                    print('DEBUG: Complete all button pressed');
                    // Mark all ayats as played for testing
                    for (int i = 0; i < _ayatList.length; i++) {
                      _markAyatAsPlayed(i);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPagination(Map<String, dynamic> ayat) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _PaginationButton(
        label: 'Ayat\nSebelumnya',
        onTap: (_isChangingAyat || _currentAyatIndex == 0)
            ? () {}
            : _goToPreviousAyat,
        isNext: false,
        isDisabled: _isChangingAyat || _currentAyatIndex == 0,
      ),
      Text(
        'AYAT ${(ayat['nomor'] ?? 0).toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      _PaginationButton(
        label: 'Ayat\nSelanjutnya',
        onTap: (_isChangingAyat || _currentAyatIndex >= _ayatList.length - 1)
            ? () {}
            : _goToNextAyat,
        isNext: true,
        isDisabled:
            _isChangingAyat || _currentAyatIndex >= _ayatList.length - 1,
      ),
    ],
  );
}

// --- Widget-widget kecil di bawah ini ---

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9D463),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 3),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final bool isLarge;
  const _InfoPill({required this.text, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 40 : 20,
        vertical: isLarge ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9D463),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFD4A23F), width: 4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF6B4F1A),
          fontWeight: FontWeight.bold,
          fontSize: isLarge ? 24 : 16,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLarge;
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 18 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9D463),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD4A23F), width: 4),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6B4F1A),
          size: isLarge ? 36 : 28,
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isNext;
  final bool isDisabled;

  const _PaginationButton({
    required this.label,
    required this.onTap,
    required this.isNext,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFF9D463).withOpacity(0.5)
              : const Color(0xFFF9D463),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4A23F), width: 4),
        ),
        child: Row(
          children: [
            if (!isNext)
              Icon(
                Icons.arrow_left_rounded,
                color: isDisabled
                    ? const Color(0xFF6B4F1A).withOpacity(0.5)
                    : const Color(0xFF6B4F1A),
                size: 30,
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDisabled
                    ? const Color(0xFF6B4F1A).withOpacity(0.5)
                    : const Color(0xFF6B4F1A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isNext)
              Icon(
                Icons.arrow_right_rounded,
                color: isDisabled
                    ? const Color(0xFF6B4F1A).withOpacity(0.5)
                    : const Color(0xFF6B4F1A),
                size: 30,
              ),
          ],
        ),
      ),
    );
  }
}
