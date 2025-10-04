import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'database_helper_v3.dart';
import 'models/family_models.dart';
import 'widgets/app_background_pattern.dart';
import 'widgets/reward_screen.dart';

// Data class for text comparison results
class TextComparison {
  final String target;
  final String recognized;
  final double similarity;

  TextComparison({
    required this.target,
    required this.recognized,
    required this.similarity,
  });
}

class MenghafalScreen extends StatefulWidget {
  final EnhancedSurah surah;

  const MenghafalScreen({super.key, required this.surah});

  @override
  State<MenghafalScreen> createState() => _MenghafalScreenState();
}

class _MenghafalScreenState extends State<MenghafalScreen>
    with TickerProviderStateMixin {
  final dbHelper = DatabaseHelperV3.instance;
  FlutterSoundRecorder? _audioRecorder;
  final _audioPlayer = AudioPlayer();

  // Speech to Text
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  String _recognizedText = '';
  bool _isListening = false;

  // Animation controllers
  late AnimationController _waveAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;

  // State variables
  bool _isLoading = true;
  bool _isRecording = false;

  bool _hasRecording = false;

  Map<String, dynamic>? _surahDetail;
  List<Map<String, dynamic>> _ayatList = [];
  int _currentAyatIndex = 0;

  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // Score and feedback - Simplified for correct/incorrect display
  int _pronunciationScore = 0;
  bool _showResult = false;
  String _expectedLatin = '';

  // Completion tracking
  Set<int> _correctAyats = {}; // Track which ayats have been correctly recited
  bool _hasCompletedMemorization = false;

  // Track which ayats have been revealed (after correct recording)
  Set<int> _revealedAyats = {};

  // Reward screen
  bool _showReward = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeech();
    _loadSurahData();
    _requestPermissions();
  }

  Future<void> _initializeRecorder() async {
    try {
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();
      print('Audio recorder initialized successfully');
    } catch (e) {
      print('Error initializing recorder: $e');
      _audioRecorder = null;
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech status: $status');
        },
        onError: (error) {
          print('Speech error: $error');
        },
      );
      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
    }
  }

  void _initializeAnimations() {
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final permissionStatus = await Permission.microphone.request();
    if (permissionStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Izin mikrofon diperlukan untuk merekam')),
      );
      return;
    }

    // Initialize recorder after permissions are granted
    await _initializeRecorder();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading surah data: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_audioRecorder == null) {
      print('Recorder not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perekam audio belum siap. Coba lagi dalam beberapa detik.',
          ),
        ),
      );
      return;
    }

    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition tidak tersedia')),
      );
      return;
    }

    try {
      // Get app documents directory for saving recording
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording.aac';
      final filePath = '${directory.path}/$fileName';

      // Start audio recording with system default settings (most compatible)
      await _audioRecorder!.startRecorder(
        toFile: filePath,
        // Let flutter_sound choose the best codec for this platform
      );

      // Start speech recognition simultaneously
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'id_ID', // Indonesian locale for better recognition
        cancelOnError: false,
      );

      // Set current ayat's latin text as expected
      if (_ayatList.isNotEmpty) {
        _expectedLatin = _ayatList[_currentAyatIndex]['teks_latin'] ?? '';
      }

      setState(() {
        _isRecording = true;
        _isListening = true;
        _recordingDuration = Duration.zero;
        _showResult = false;

        _recognizedText = '';
      });

      _waveAnimationController.repeat();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });

        // Auto stop after 30 seconds
        if (timer.tick >= 30) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai perekaman: ${e.toString()}')),
      );

      // Reset states in case of error
      setState(() {
        _isRecording = false;
        _isListening = false;
      });
      _waveAnimationController.stop();
    }
  }

  Future<void> _stopRecording() async {
    if (_audioRecorder == null) {
      print('Recorder is null, cannot stop recording');
      return;
    }

    try {
      // Stop audio recording
      String? path;
      if (_audioRecorder!.isRecording) {
        path = await _audioRecorder!.stopRecorder();
      }

      // Stop speech recognition
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }

      _recordingTimer?.cancel();
      _waveAnimationController.stop();

      setState(() {
        _isRecording = false;
        _isListening = false;
        _hasRecording = path != null && path.isNotEmpty;
      });

      if (path != null) {
        print('Recording saved to: $path');

        // Process pronunciation comparison
        if (_recognizedText.isNotEmpty && _expectedLatin.isNotEmpty) {
          _compareText(_recognizedText, _expectedLatin);
        } else {
          // Fallback to simulated analysis if speech recognition failed
          _analyzePronunciation();
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghentikan perekaman: ${e.toString()}'),
        ),
      );
      setState(() {
        _isRecording = false;
        _isListening = false;
      });
      _recordingTimer?.cancel();
      _waveAnimationController.stop();
    }
  }

  void _analyzePronunciation() {
    // For testing purposes, always return a high score (90-95%)
    Future.delayed(const Duration(seconds: 1), () {
      final testScore =
          90 + (DateTime.now().millisecond % 6); // Random between 90-95%

      setState(() {
        _pronunciationScore = testScore;
        _showResult = true;
        // Always mark as correct since we're in testing mode
        _markAyatAsCorrect(_currentAyatIndex);
      });

      _pulseAnimationController.forward().then((_) {
        _pulseAnimationController.reverse();
      });
    });
  }

  void _compareText(String recognized, String expected) {
    // For testing purposes, always return a high score (90-95%)
    final testScore =
        90 + (DateTime.now().millisecond % 6); // Random between 90-95%

    setState(() {
      _pronunciationScore = testScore;
      _showResult = true;
      // Always mark as correct since we're in testing mode
      _markAyatAsCorrect(_currentAyatIndex);
    });

    _pulseAnimationController.forward().then((_) {
      _pulseAnimationController.reverse();
    });
  }

  void _nextAyat() {
    // Check if current ayat has been correctly recited
    if (!_correctAyats.contains(_currentAyatIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hafalan ayat ini harus benar terlebih dahulu sebelum melanjutkan!',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentAyatIndex < _ayatList.length - 1) {
      _audioPlayer.stop(); // Stop any playing audio
      setState(() {
        _currentAyatIndex++;
        _hasRecording = false;
        _showResult = false;
        _pronunciationScore = 0;
      });
    }
  }

  void _previousAyat() {
    if (_currentAyatIndex > 0) {
      _audioPlayer.stop(); // Stop any playing audio
      setState(() {
        _currentAyatIndex--;
        _hasRecording = false;
        _showResult = false;
        _pronunciationScore = 0;
      });
    }
  }

  // Mark ayat as correctly recited
  void _markAyatAsCorrect(int ayatIndex) {
    if (!_correctAyats.contains(ayatIndex)) {
      setState(() {
        _correctAyats.add(ayatIndex);
        _revealedAyats.add(
          ayatIndex,
        ); // Reveal the ayat text after correct recording
      });

      print(
        'DEBUG: Ayat ${ayatIndex + 1} marked as correct and revealed. Total correct: ${_correctAyats.length}/${_ayatList.length}',
      );

      // Check if all ayats have been correctly recited
      if (_correctAyats.length >= _ayatList.length &&
          !_hasCompletedMemorization) {
        _completeMemorizationTask();
      }
    }
  }

  // Complete all ayats instantly (Developer feature)
  void _completeAllAyatsInstantly() {
    setState(() {
      // Mark all ayats as correct and revealed
      _correctAyats.clear();
      _revealedAyats.clear();
      for (int i = 0; i < _ayatList.length; i++) {
        _correctAyats.add(i);
        _revealedAyats.add(i);
      }
      _hasCompletedMemorization = true;
    });

    print('DEBUG: All ayats completed instantly! Developer mode activated.');

    // Show instant completion message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚡ Mode Developer: Semua ayat telah diselesaikan secara instan!',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    // Return to previous screen with success result after short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate completion
      }
    });
  }

  // Complete memorization task
  void _completeMemorizationTask() {
    setState(() {
      _hasCompletedMemorization = true;
      _showReward = true; // Show reward screen
    });

    print('DEBUG: Memorization task completed! All ayats correctly recited.');

    // Return to previous screen with success result when reward screen is dismissed
    // The return will be handled by the RewardScreen onComplete callback
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _pulseAnimationController.dispose();
    _audioRecorder?.closeRecorder();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        const AppBackgroundPattern(),
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
                _buildRecordingSection(),
                const SizedBox(height: 20),
                if (_showResult) _buildResultSection(),
                const Spacer(),
                _buildNavigation(currentAyat),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Reward screen overlay
        if (_showReward)
          RewardScreen(
            title: '🎉 Selamat!',
            subtitle:
                'Anda telah menghafal semua ayat dengan benar.\nTugas menghafal selesai!',
            onComplete: () {
              setState(() {
                _showReward = false;
              });

              // Return to previous screen with success result
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pop(true); // Return true to indicate completion
                }
              });
            },
          ),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SvgPicture.asset('assets/exitsegmen.svg', height: 35),
          ),

          Row(
            children: [
              // Developer button to complete memorization instantly
              GestureDetector(
                onTap: _completeAllAyatsInstantly,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Selesai Instan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset('assets/amma_play_logo.svg', height: 35),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeader() {
    return Column(
      children: [
        // Main surah name with SVG background
        Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset('assets/suratbar.svg', height: 60),
            Text(
              _surahDetail!['nama'] ?? 'Nama Surat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(-1.0, -1.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                  Shadow(
                    offset: Offset(1.0, -1.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                  Shadow(
                    offset: Offset(-1.0, 1.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                  Shadow(
                    offset: Offset(-2.0, 0.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                  Shadow(
                    offset: Offset(2.0, 0.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                  Shadow(
                    offset: Offset(0.0, -2.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                  Shadow(
                    offset: Offset(0.0, 2.0),
                    blurRadius: 0.0,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sub info with SVG background
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset('assets/subsuratbar.svg', height: 35),
                Text(
                  _surahDetail!['arti'] ?? 'Arti',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.0, -1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(1.0, -1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(-1.0, 1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(-2.0, 0.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(2.0, 0.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(0.0, -2.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(0.0, 2.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset('assets/subsuratbar.svg', height: 35),
                Text(
                  '${_surahDetail!['jumlah_ayat'] ?? 0} Ayat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.0, -1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(1.0, -1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(-1.0, 1.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(-2.0, 0.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(2.0, 0.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(0.0, -2.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                      Shadow(
                        offset: Offset(0.0, 2.0),
                        blurRadius: 0.0,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAyahCard(Map<String, dynamic> ayat) {
    final isRevealed = _revealedAyats.contains(_currentAyatIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF08363D), width: 3),
      ),
      child: Column(
        children: [
          if (isRevealed) ...[
            // Show actual ayat text if revealed
            Text(
              ayat['teks_arab'] ?? 'Teks Arab tidak tersedia',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'LPMQ',
                height: 1.8,
                color: Color(0xFF2C5530),
              ),
            ),
            const SizedBox(height: 12),
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
              style: const TextStyle(fontSize: 14, color: Color(0xFF2C5530)),
            ),
          ] else ...[
            // Show placeholder when not revealed
            Container(
              height: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_rounded, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Mulai hafalan dengan merekam ayat ini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ayat ${ayat['nomor'] ?? '0'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    final isRevealed = _revealedAyats.contains(_currentAyatIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B6B73),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B9DA8), width: 2),
      ),
      child: Column(
        children: [
          Text(
            isRevealed ? 'Rekam Pelafalan Anda' : 'Hafal Ayat Ini',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isRevealed) ...[
            const SizedBox(height: 8),
            Text(
              'Hafalkan ayat ini terlebih dahulu, lalu rekam untuk melihat teksnya',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          // Progress indicator for memorization
          if (_correctAyats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFF9D463), width: 1),
                ),
                child: Text(
                  '${_correctAyats.length} dari ${_ayatList.length} ayat sudah benar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF9D463),
                  boxShadow: _isRecording
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF9D463).withOpacity(0.6),
                            blurRadius: 20 * _waveAnimation.value,
                            spreadRadius: 10 * _waveAnimation.value,
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 48,
                    color: const Color(0xFF6B4F1A),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording
                ? _isListening
                      ? 'Merekam & Mendengarkan... ${_recordingDuration.inSeconds}s'
                      : 'Sedang merekam... ${_recordingDuration.inSeconds}s'
                : _hasRecording
                ? 'Rekaman tersimpan'
                : 'Tekan untuk mulai merekam',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    final isCorrect = _pronunciationScore >= 80;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isCorrect
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.close_rounded,
                  size: 28,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'BENAR' : 'SALAH',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigation(Map<String, dynamic> ayat) {
    final isCurrentAyatCorrect = _correctAyats.contains(_currentAyatIndex);
    final canGoNext =
        isCurrentAyatCorrect && _currentAyatIndex < _ayatList.length - 1;
    final canGoPrev = _currentAyatIndex > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: canGoPrev ? _previousAyat : null,
            child: Opacity(
              opacity: canGoPrev ? 1.0 : 0.5,
              child: SvgPicture.asset('assets/prevayat.svg', height: 55),
            ),
          ),
          Column(
            children: [
              Text(
                'AYAT ${(ayat['nomor'] ?? 0).toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(-1.0, -1.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                    Shadow(
                      offset: Offset(1.0, -1.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                    Shadow(
                      offset: Offset(-1.0, 1.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                    Shadow(
                      offset: Offset(-2.0, 0.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                    Shadow(
                      offset: Offset(2.0, 0.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                    Shadow(
                      offset: Offset(0.0, -2.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                    Shadow(
                      offset: Offset(0.0, 2.0),
                      blurRadius: 0.0,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              // Status indicator
              if (isCurrentAyatCorrect)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '✓ Benar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Hafal dulu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: canGoNext ? _nextAyat : null,
            child: Opacity(
              opacity: canGoNext ? 1.0 : 0.5,
              child: SvgPicture.asset('assets/nexyatat.svg', height: 55),
            ),
          ),
        ],
      ),
    );
  }
}
