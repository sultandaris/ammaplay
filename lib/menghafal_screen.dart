import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'database_helper_v3.dart';
import 'models/family_models.dart';

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
  bool _isPlayingRecording = false;
  bool _isPlayingReference = false;
  bool _hasRecording = false;

  Map<String, dynamic>? _surahDetail;
  List<Map<String, dynamic>> _ayatList = [];
  int _currentAyatIndex = 0;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // Score and feedback - Enhanced for text comparison
  int _pronunciationScore = 0;
  String _feedbackMessage = '';
  bool _showResult = false;
  String _expectedLatin = '';
  List<TextComparison> _wordComparisons = [];

  // Completion tracking
  Set<int> _correctAyats = {}; // Track which ayats have been correctly recited
  bool _hasCompletedMemorization = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRecorder();
    _initializeSpeech();
    _loadSurahData();
    _requestPermissions();
  }

  Future<void> _initializeRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
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
    }

    // Initialize recorder after permissions are granted
    if (_audioRecorder != null &&
        permissionStatus == PermissionStatus.granted) {
      try {
        await _audioRecorder!.openRecorder();
        print('Audio recorder initialized successfully');
      } catch (e) {
        print('Error initializing recorder: $e');
      }
    }
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
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${directory.path}/$fileName';

      // Start audio recording
      await _audioRecorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
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
        _recordingPath = filePath;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal memulai perekaman')));
    }
  }

  Future<void> _stopRecording() async {
    if (_audioRecorder == null) return;

    try {
      // Stop audio recording
      final path = await _audioRecorder!.stopRecorder();

      // Stop speech recognition
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }

      _recordingTimer?.cancel();
      _waveAnimationController.stop();

      setState(() {
        _isRecording = false;
        _isListening = false;
        _recordingPath = path;
        _hasRecording = path != null;
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
      setState(() {
        _isRecording = false;
        _isListening = false;
      });
    }
  }

  void _analyzePronunciation() {
    // Simulate AI pronunciation scoring (in real app, this would call AI service)
    Future.delayed(const Duration(seconds: 2), () {
      final random = DateTime.now().millisecond;
      final score = 60 + (random % 40); // Random score between 60-99

      String message;
      if (score >= 90) {
        message = 'Luar biasa! Pelafalan Anda sangat baik!';
      } else if (score >= 80) {
        message = 'Bagus! Sedikit lagi untuk sempurna.';
      } else if (score >= 70) {
        message = 'Cukup baik. Latihan terus ya!';
      } else {
        message = 'Butuh latihan lebih. Dengarkan contoh lagi.';
      }

      setState(() {
        _pronunciationScore = score;
        _feedbackMessage = message;
        _showResult = true;
      });

      _pulseAnimationController.forward().then((_) {
        _pulseAnimationController.reverse();
      });
    });
  }

  void _compareText(String recognized, String expected) {
    final recognizedWords = recognized.toLowerCase().split(' ');
    final expectedWords = expected.toLowerCase().split(' ');

    List<TextComparison> comparisons = [];
    int maxLength = recognizedWords.length > expectedWords.length
        ? recognizedWords.length
        : expectedWords.length;

    for (int i = 0; i < maxLength; i++) {
      String recognizedWord = i < recognizedWords.length
          ? recognizedWords[i]
          : '';
      String expectedWord = i < expectedWords.length ? expectedWords[i] : '';

      double similarity = 0.0;
      if (recognizedWord.isNotEmpty && expectedWord.isNotEmpty) {
        similarity = StringSimilarity.compareTwoStrings(
          recognizedWord,
          expectedWord,
        );
      }

      comparisons.add(
        TextComparison(
          target: expectedWord,
          recognized: recognizedWord,
          similarity: similarity,
        ),
      );
    }

    setState(() {
      _wordComparisons = comparisons;
      // Calculate overall accuracy
      double totalSimilarity = comparisons.fold(
        0.0,
        (sum, comp) => sum + comp.similarity,
      );
      double averageSimilarity = comparisons.isNotEmpty
          ? totalSimilarity / comparisons.length
          : 0.0;
      _pronunciationScore = (averageSimilarity * 100).round();

      String message;
      if (_pronunciationScore >= 90) {
        message = 'Luar biasa! Pelafalan Anda sangat akurat!';
        _markAyatAsCorrect(
          _currentAyatIndex,
        ); // Mark as correct if score >= 90%
      } else if (_pronunciationScore >= 80) {
        message = 'Bagus! Hampir sempurna.';
        _markAyatAsCorrect(
          _currentAyatIndex,
        ); // Mark as correct if score >= 80%
      } else if (_pronunciationScore >= 70) {
        message = 'Cukup baik. Ada beberapa kata yang perlu diperbaiki.';
      } else {
        message = 'Butuh latihan lebih. Perhatikan pelafalan setiap kata.';
      }

      _feedbackMessage = message;
      _showResult = true;
    });

    _pulseAnimationController.forward().then((_) {
      _pulseAnimationController.reverse();
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null && File(_recordingPath!).existsSync()) {
      try {
        setState(() => _isPlayingRecording = true);

        await _audioPlayer.setFilePath(_recordingPath!);
        await _audioPlayer.play();

        // Listen for playback completion
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() => _isPlayingRecording = false);
          }
        });
      } catch (e) {
        print('Error playing recording: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memutar rekaman')));
        setState(() => _isPlayingRecording = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File rekaman tidak ditemukan')),
      );
    }
  }

  Future<void> _playReference() async {
    if (_ayatList.isNotEmpty) {
      final audioUrl = _ayatList[_currentAyatIndex]['audio_url'];
      if (audioUrl != null) {
        try {
          setState(() => _isPlayingReference = true);
          await _audioPlayer.setUrl(audioUrl);
          await _audioPlayer.play();

          _audioPlayer.playerStateStream.listen((state) {
            if (state.processingState == ProcessingState.completed) {
              setState(() => _isPlayingReference = false);
            }
          });
        } catch (e) {
          print('Error playing reference audio: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memutar audio contoh')),
          );
          setState(() => _isPlayingReference = false);
        }
      }
    }
  }

  void _nextAyat() {
    if (_currentAyatIndex < _ayatList.length - 1) {
      _audioPlayer.stop(); // Stop any playing audio
      setState(() {
        _currentAyatIndex++;
        _hasRecording = false;
        _showResult = false;
        _recordingPath = null;
        _pronunciationScore = 0;
        _isPlayingRecording = false;
        _isPlayingReference = false;
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
        _recordingPath = null;
        _pronunciationScore = 0;
        _isPlayingRecording = false;
        _isPlayingReference = false;
      });
    }
  }

  // Mark ayat as correctly recited
  void _markAyatAsCorrect(int ayatIndex) {
    if (!_correctAyats.contains(ayatIndex)) {
      setState(() {
        _correctAyats.add(ayatIndex);
      });

      print(
        'DEBUG: Ayat ${ayatIndex + 1} marked as correct. Total correct: ${_correctAyats.length}/${_ayatList.length}',
      );

      // Check if all ayats have been correctly recited
      if (_correctAyats.length >= _ayatList.length &&
          !_hasCompletedMemorization) {
        _completeMemorizationTask();
      }
    }
  }

  // Complete memorization task
  void _completeMemorizationTask() {
    setState(() {
      _hasCompletedMemorization = true;
    });

    print('DEBUG: Memorization task completed! All ayats correctly recited.');

    // Show completion message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Selamat! Anda telah menghafal semua ayat dengan benar. Tugas menghafal selesai!',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Return to previous screen with success result after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(
              context,
            ).pop(true); // Return true to indicate completion
          }
        });
      }
    });
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 16),
            _buildSurahHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAyatCard(currentAyat),
                    const SizedBox(height: 20),
                    _buildRecordingSection(),
                    const SizedBox(height: 20),
                    if (_showResult) _buildResultSection(),
                    const SizedBox(height: 20),
                    _buildControls(),
                  ],
                ),
              ),
            ),
            _buildNavigation(currentAyat),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Text(
          'Mode Menghafal',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SvgPicture.asset('assets/amma_play_logo.svg', height: 35),
      ],
    );
  }

  Widget _buildSurahHeader() {
    return Column(
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
  }

  Widget _buildAyatCard(Map<String, dynamic> ayat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF08363D), width: 3),
      ),
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B6B73),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B9DA8), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Rekam Pelafalan Anda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _pronunciationScore >= 80
                      ? const Color(0xFF4CAF50)
                      : _pronunciationScore >= 70
                      ? const Color(0xFFF57C00)
                      : const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      _pronunciationScore >= 80
                          ? Icons.star_rounded
                          : _pronunciationScore >= 70
                          ? Icons.thumb_up_rounded
                          : Icons.refresh_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Skor: $_pronunciationScore%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feedbackMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (_recognizedText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Yang Didengar:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$_recognizedText"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              // Word-by-word analysis section
              if (_wordComparisons.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analisis Per Kata:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_wordComparisons
                          .map((comparison) => _buildWordComparison(comparison))
                          .toList()),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordComparison(TextComparison comparison) {
    Color backgroundColor;
    IconData icon;

    if (comparison.similarity >= 0.8) {
      backgroundColor = Colors.green.shade50;
      icon = Icons.check_circle;
    } else if (comparison.similarity >= 0.6) {
      backgroundColor = Colors.orange.shade50;
      icon = Icons.warning_rounded;
    } else {
      backgroundColor = Colors.red.shade50;
      icon = Icons.close_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: comparison.similarity >= 0.8
              ? Colors.green.shade200
              : comparison.similarity >= 0.6
              ? Colors.orange.shade200
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: comparison.similarity >= 0.8
                ? Colors.green.shade600
                : comparison.similarity >= 0.6
                ? Colors.orange.shade600
                : Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Target: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      comparison.target.isEmpty
                          ? '(kosong)'
                          : comparison.target,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Didengar: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      comparison.recognized.isEmpty
                          ? '(kosong)'
                          : comparison.recognized,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${(comparison.similarity * 100).round()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: comparison.similarity >= 0.8
                  ? Colors.green.shade600
                  : comparison.similarity >= 0.6
                  ? Colors.orange.shade600
                  : Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: Icons.volume_up_rounded,
          label: 'Dengar Contoh',
          isActive: _isPlayingReference,
          onTap: () {
            if (_isPlayingReference) {
              _audioPlayer.stop();
              setState(() => _isPlayingReference = false);
            } else {
              _playReference();
            }
          },
        ),
        if (_hasRecording)
          _ControlButton(
            icon: Icons.play_arrow_rounded,
            label: 'Putar Rekaman',
            isActive: _isPlayingRecording,
            onTap: () {
              if (_isPlayingRecording) {
                _audioPlayer.stop();
                setState(() => _isPlayingRecording = false);
              } else {
                _playRecording();
              }
            },
          ),
      ],
    );
  }

  Widget _buildNavigation(Map<String, dynamic> ayat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavigationButton(
          label: 'Ayat\nSebelumnya',
          onTap: _currentAyatIndex > 0 ? _previousAyat : () {},
          isEnabled: _currentAyatIndex > 0,
          isNext: false,
        ),
        Text(
          'AYAT ${(ayat['nomor'] ?? 0).toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        _NavigationButton(
          label: 'Ayat\nSelanjutnya',
          onTap: _currentAyatIndex < _ayatList.length - 1 ? _nextAyat : () {},
          isEnabled: _currentAyatIndex < _ayatList.length - 1,
          isNext: true,
        ),
      ],
    );
  }
}

// Custom Widgets
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
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
        horizontal: isLarge ? 32 : 16,
        vertical: isLarge ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9D463),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFD4A23F), width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF6B4F1A),
          fontWeight: FontWeight.bold,
          fontSize: isLarge ? 18 : 14,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2B9DA8) : const Color(0xFFF9D463),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4A23F), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.pause : icon,
              color: isActive ? Colors.white : const Color(0xFF6B4F1A),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF6B4F1A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool isNext;

  const _NavigationButton({
    required this.label,
    required this.onTap,
    required this.isEnabled,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFFF9D463)
              : const Color(0xFFF9D463).withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD4A23F), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNext)
              Icon(
                Icons.arrow_left_rounded,
                color: isEnabled
                    ? const Color(0xFF6B4F1A)
                    : const Color(0xFF6B4F1A).withOpacity(0.5),
                size: 24,
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isEnabled
                    ? const Color(0xFF6B4F1A)
                    : const Color(0xFF6B4F1A).withOpacity(0.5),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (isNext)
              Icon(
                Icons.arrow_right_rounded,
                color: isEnabled
                    ? const Color(0xFF6B4F1A)
                    : const Color(0xFF6B4F1A).withOpacity(0.5),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
