import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'database_helper.dart';
import 'hafalan_surat.dart'; // Untuk mengakses SurahInfo
import 'package:just_audio/just_audio.dart'; // Untuk audio playback

class BermainScreen extends StatefulWidget {
  final SurahInfo surahInfo;

  const BermainScreen({super.key, required this.surahInfo});

  @override
  State<BermainScreen> createState() => _BermainScreenState();
}

class _BermainScreenState extends State<BermainScreen> {
  final dbHelper = DatabaseHelper.instance;
  final _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  bool _isChangingAyat = false;
  Map<String, dynamic>? _surahDetail;
  List<Map<String, dynamic>> _ayatList = [];
  int _currentAyatIndex = 0;

  @override
  void dispose() {
    _audioPlayer.dispose(); // Sangat penting untuk melepaskan resource
    super.dispose();
  }

  Future<void> _loadSurahData() async {
    final surahList = await dbHelper.querySemuaSurah();
    final surah = surahList.firstWhere(
      (s) => s['nama'] == widget.surahInfo.name,
      orElse: () => {},
    );

    if (surah.isNotEmpty) {
      final suratId = surah['surat_id'];
      final ayat = await dbHelper.queryAyatBySurah(suratId);
      setState(() {
        _surahDetail = surah;
        _ayatList = ayat;
        _isLoading = false;
      });
      // --- AUDIO LOGIC ---
      _loadAudioForCurrentAyat(); // Muat audio untuk ayat pertama
    } else {
      setState(() {
        _isLoading = false;
      });
      print("Error: Surat ${widget.surahInfo.name} tidak ditemukan di DB.");
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
          child: Icon(Icons.cloud, size: 400, color: Colors.white.withOpacity(0.15)),
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
                    style: const TextStyle(fontSize: 32, fontFamily: 'LPMQ', height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ayat['teks_latin'] ?? 'Teks Latin tidak tersedia',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[600]),
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

        if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        return Row(
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
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
            onTap: (_isChangingAyat || _currentAyatIndex == 0) ? () {} : _goToPreviousAyat, 
            isNext: false,
            isDisabled: _isChangingAyat || _currentAyatIndex == 0,
          ),
          Text(
            'AYAT ${(ayat['nomor'] ?? 0).toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          _PaginationButton(
            label: 'Ayat\nSelanjutnya', 
            onTap: (_isChangingAyat || _currentAyatIndex >= _ayatList.length - 1) ? () {} : _goToNextAyat, 
            isNext: true,
            isDisabled: _isChangingAyat || _currentAyatIndex >= _ayatList.length - 1,
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
  const _ControlButton({required this.icon, required this.onTap, this.isLarge = false});

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
        child: Icon(icon, color: const Color(0xFF6B4F1A), size: isLarge ? 36 : 28),
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
          color: isDisabled ? const Color(0xFFF9D463).withOpacity(0.5) : const Color(0xFFF9D463),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4A23F), width: 4),
        ),
        child: Row(
          children: [
            if (!isNext) Icon(
              Icons.arrow_left_rounded, 
              color: isDisabled ? const Color(0xFF6B4F1A).withOpacity(0.5) : const Color(0xFF6B4F1A), 
              size: 30
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDisabled ? const Color(0xFF6B4F1A).withOpacity(0.5) : const Color(0xFF6B4F1A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (isNext) Icon(
              Icons.arrow_right_rounded, 
              color: isDisabled ? const Color(0xFF6B4F1A).withOpacity(0.5) : const Color(0xFF6B4F1A), 
              size: 30
            ),
          ],
        ),
      ),
    );
  }
}