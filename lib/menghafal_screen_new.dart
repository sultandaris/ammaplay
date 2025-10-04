import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';
import 'database_helper_v3.dart';
import 'models/family_models.dart';

class MenghafalScreen extends StatefulWidget {
  final EnhancedSurah surah;

  const MenghafalScreen({super.key, required this.surah});

  @override
  State<MenghafalScreen> createState() => _MenghafalScreenState();
}

class _MenghafalScreenState extends State<MenghafalScreen> {
  final dbHelper = DatabaseHelperV3.instance;
  // Speech to Text instance
  late stt.SpeechToText _speech;

  // State variables
  bool _isListening = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _statusMessage = 'Tekan mikrofon untuk mulai';
  double _confidence = 0.0;
  List<String> _speechHistory = [];

  // Loading state
  bool _isLoading = true;

  // Surah and Ayat data
  Map<String, dynamic>? _surahDetail;
  List<Map<String, dynamic>> _ayatList = [];
  int _currentAyatIndex = 0;
  String _expectedLatin = '';

  // Memorization progress
  Set<int> _correctAyats = {};
  Set<int> _revealedAyats = {};
  bool _showResult = false;
  int _pronunciationScore = 0;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _loadSurahData();
  }

  Future<void> _initializeSpeech() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        setState(() {
          _statusMessage = 'Izin mikrofon diperlukan!';
        });
        return;
      }

      // Initialize speech recognition
      _speech = stt.SpeechToText();
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          print('Speech Status: $status');
          setState(() {
            if (status == 'listening') {
              _statusMessage = 'Sedang mendengarkan...';
            } else if (status == 'notListening') {
              _statusMessage = 'Berhenti mendengarkan';
              _isListening = false;
            } else if (status == 'done') {
              _statusMessage = 'Speech recognition selesai';
              _isListening = false;
            }
          });
        },
        onError: (error) {
          print('Speech Error: $error');
          setState(() {
            _statusMessage = 'Error: ${error.errorMsg}';
            _isListening = false;
          });
        },
      );

      if (_speechEnabled) {
        setState(() {
          _statusMessage = 'Speech recognition siap!';
        });
        
        // Check available locales
        var locales = await _speech.locales();
        var indonesianLocale = locales.firstWhere(
          (locale) => locale.localeId.startsWith('in'),
          orElse: () => locales.first,
        );
        print('Using locale: ${indonesianLocale.localeId}');
      } else {
        setState(() {
          _statusMessage = 'Speech recognition tidak tersedia';
        });
      }
    } catch (e) {
      print('Error initializing speech: $e');
      setState(() {
        _statusMessage = 'Error menginisialisasi: $e';
      });
    }
  }

  Future<void> _loadSurahData() async {
    try {
      // Load ayat list
      final ayatData = await dbHelper.queryAyatBySurah(widget.surah.idSurat);
      
      setState(() {
        _surahDetail = {
          'nama': widget.surah.namaLatin,
          'arti': widget.surah.artiNama,
          'jumlah_ayat': widget.surah.jumlahAyat,
        };
        _ayatList = ayatData;
        _isLoading = false;
        
        if (_ayatList.isNotEmpty) {
          _updateExpectedText();
        }
      });
    } catch (e) {
      print('Error loading surah data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateExpectedText() {
    if (_ayatList.isNotEmpty && _currentAyatIndex < _ayatList.length) {
      final currentAyat = _ayatList[_currentAyatIndex];
      _expectedLatin = currentAyat['teks_latin'] ?? '';
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) return;

    try {
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _confidence = 0.0;
        _showResult = false;
        _statusMessage = 'Mulai mendengarkan...';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            _confidence = result.confidence;
            
            if (result.hasConfidenceRating && result.confidence > 0) {
              _statusMessage = 'Mendengarkan... (${(_confidence * 100).toInt()}%)';
              
              // Add to history
              if (_recognizedText.isNotEmpty && !_speechHistory.contains(_recognizedText)) {
                _speechHistory.insert(0, _recognizedText);
                if (_speechHistory.length > 10) {
                  _speechHistory.removeLast();
                }
              }

              // Auto-compare when we have confidence > 80%
              if (_confidence > 0.8 && _recognizedText.isNotEmpty) {
                _compareText(_recognizedText, _expectedLatin);
              }
            } else {
              _statusMessage = 'Mendengarkan... (${(_confidence * 100).toInt()}%)';
            }
          });
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: 'in_ID', // Indonesian locale
        cancelOnError: false,
        onSoundLevelChange: (level) {
          // Optional: You can use this to show sound level indicator
          // print('Sound level: $level');
        },
      );
    } catch (e) {
      print('Error starting listening: $e');
      setState(() {
        _statusMessage = 'Error: $e';
        _isListening = false;
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _statusMessage = 'Berhenti mendengarkan';
      });
    } catch (e) {
      print('Error stopping listening: $e');
    }
  }

  void _compareText(String recognized, String expected) {
    print('DEBUG: Comparing recognized: "$recognized" with expected: "$expected"');
    
    // Clean and normalize both texts for comparison
    String cleanRecognized = recognized.toLowerCase().trim();
    String cleanExpected = expected.toLowerCase().trim();
    
    // Calculate similarity
    double similarity = 0.0;
    bool isCorrect = false;
    
    if (cleanRecognized.isNotEmpty && cleanExpected.isNotEmpty) {
      similarity = StringSimilarity.compareTwoStrings(cleanRecognized, cleanExpected);
      
      // Consider it correct if similarity is above 60% (more lenient)
      isCorrect = similarity >= 0.6;
      
      print('DEBUG: Similarity score: ${(similarity * 100).toStringAsFixed(1)}%');
      print('DEBUG: Result: ${isCorrect ? "CORRECT" : "INCORRECT"}');
    } else {
      print('DEBUG: One of the texts is empty, marking as incorrect');
    }
    
    setState(() {
      _pronunciationScore = isCorrect ? 85 : 45;
      _showResult = true;
      
      if (isCorrect) {
        _markAyatAsCorrect(_currentAyatIndex);
        print('DEBUG: Ayat marked as correct due to good similarity');
      } else {
        print('DEBUG: Ayat not marked as correct due to low similarity');
      }
    });
  }

  void _markAyatAsCorrect(int index) {
    setState(() {
      _correctAyats.add(index);
      _revealedAyats.add(index);
      
      // Check if all ayats are completed
      if (_correctAyats.length == _ayatList.length) {
        _showSnackBar('🎉 Selamat! Anda telah menghafal semua ayat!');
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _speechHistory.clear();
      _recognizedText = '';
      _confidence = 0.0;
      _showResult = false;
    });
  }

  void _nextAyat() {
    if (_currentAyatIndex < _ayatList.length - 1) {
      setState(() {
        _currentAyatIndex++;
        _updateExpectedText();
        _recognizedText = '';
        _showResult = false;
        _confidence = 0.0;
      });
    }
  }

  void _previousAyat() {
    if (_currentAyatIndex > 0) {
      setState(() {
        _currentAyatIndex--;
        _updateExpectedText();
        _recognizedText = '';
        _showResult = false;
        _confidence = 0.0;
      });
    }
  }

  void _completeAllAyatsInstantly() {
    setState(() {
      for (int i = 0; i < _ayatList.length; i++) {
        _correctAyats.add(i);
        _revealedAyats.add(i);
      }
    });
    _showSnackBar('🎉 Semua ayat berhasil diselesaikan!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menghafal: ${_surahDetail?['nama'] ?? 'Loading...'}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Test Perfect Match Button
          IconButton(
            onPressed: () {
              setState(() {
                _recognizedText = _expectedLatin;
              });
              if (_expectedLatin.isNotEmpty) {
                _compareText(_recognizedText, _expectedLatin);
              }
            },
            icon: const Icon(Icons.check_circle),
            tooltip: 'Test Perfect Match',
          ),
          // Complete All Button
          IconButton(
            onPressed: _completeAllAyatsInstantly,
            icon: const Icon(Icons.fast_forward),
            tooltip: 'Complete All (Dev)',
          ),
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Bersihkan Riwayat',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Ayat Navigation
                  _buildAyatNavigation(),
                  const SizedBox(height: 16),
                  
                  // Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  
                  // Current Recognition Result
                  _buildRecognitionCard(),
                  const SizedBox(height: 20),

                  // Expected Text Card
                  _buildExpectedTextCard(),
                  const SizedBox(height: 20),

                  // History Section
                  Expanded(child: _buildHistorySection()),
                ],
              ),
            ),
          ),
      
      // Floating Action Button for Recording
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _speechEnabled
          ? (_isListening ? _stopListening : _startListening)
          : null,
        backgroundColor: _isListening ? Colors.red : Colors.blue,
        icon: Icon(
          _isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
        label: Text(
          _isListening ? 'STOP' : 'MULAI',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAyatNavigation() {
    if (_ayatList.isEmpty) return const SizedBox();
    
    final currentAyat = _ayatList[_currentAyatIndex];
    final isCurrentAyatCorrect = _correctAyats.contains(_currentAyatIndex);
    final canGoNext = isCurrentAyatCorrect && _currentAyatIndex < _ayatList.length - 1;
    final canGoPrev = _currentAyatIndex > 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: canGoPrev ? _previousAyat : null,
              icon: Icon(
                Icons.arrow_back,
                color: canGoPrev ? Colors.blue : Colors.grey,
              ),
            ),
            Column(
              children: [
                Text(
                  'AYAT ${(currentAyat['nomor'] ?? 0).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentAyatIndex + 1} dari ${_ayatList.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                // Status indicator
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCurrentAyatCorrect ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isCurrentAyatCorrect ? 'BENAR' : 'BELUM',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: canGoNext ? _nextAyat : null,
              icon: Icon(
                Icons.arrow_forward,
                color: canGoNext ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _speechEnabled ? Icons.mic : Icons.mic_off,
                  color: _speechEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: $_statusMessage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _speechEnabled ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (_confidence > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (_showResult) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _pronunciationScore >= 70 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _pronunciationScore >= 70 
                    ? 'BENAR! Score: $_pronunciationScore%' 
                    : 'COBA LAGI! Score: $_pronunciationScore%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecognitionCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hearing, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Yang Anda Ucapkan:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _recognizedText.isEmpty 
                  ? 'Tekan mikrofon dan mulai berbicara...' 
                  : _recognizedText,
                style: TextStyle(
                  fontSize: 16,
                  color: _recognizedText.isEmpty 
                    ? Colors.grey.shade500 
                    : Colors.black87,
                  fontStyle: _recognizedText.isEmpty 
                    ? FontStyle.italic 
                    : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedTextCard() {
    if (_ayatList.isEmpty) return const SizedBox();
    
    final currentAyat = _ayatList[_currentAyatIndex];
    final isRevealed = _revealedAyats.contains(_currentAyatIndex);
    
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Ayat yang Diharapkan:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isRevealed) ...[
              // Show actual ayat text if revealed
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAyat['teks_arab'] ?? 'Teks Arab tidak tersedia',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'LPMQ',
                        height: 1.6,
                        color: Color(0xFF2C5530),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentAyat['teks_latin'] ?? 'Teks Latin tidak tersedia',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentAyat['nomor'] ?? '0'}. ${currentAyat['teks_indonesia'] ?? 'Terjemahan tidak tersedia'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF2C5530)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Show placeholder when not revealed
              Container(
                width: double.infinity,
                height: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, color: Colors.orange, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Hafalkan dan ucapkan dengan benar untuk melihat teks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Riwayat Percobaan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_speechHistory.length} item',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _speechHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat\nMulai berbicara untuk melihat hasilnya',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _speechHistory.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      title: Text(
                        _speechHistory[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          _showSnackBar('Teks disalin: ${_speechHistory[index]}');
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
