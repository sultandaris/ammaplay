import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechTestScreen extends StatefulWidget {
  const SpeechTestScreen({super.key});

  @override
  State<SpeechTestScreen> createState() => _SpeechTestScreenState();
}

class _SpeechTestScreenState extends State<SpeechTestScreen> {
  // Speech to Text instance
  late stt.SpeechToText _speech;
  
  // State variables
  bool _isListening = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _statusMessage = 'Tekan mikrofon untuk mulai';
  double _confidence = 0.0;
  List<String> _speechHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
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
              _statusMessage = 'Selesai';
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
        debugLogging: true,
      );

      if (_speechEnabled) {
        // Get available locales
        var locales = await _speech.locales();
        print('Available Locales:');
        for (var locale in locales) {
          print('${locale.localeId}: ${locale.name}');
        }
        
        setState(() {
          _statusMessage = 'Speech recognition siap!';
        });
      } else {
        setState(() {
          _statusMessage = 'Speech recognition tidak tersedia';
        });
      }
    } catch (e) {
      print('Error initializing speech: $e');
      setState(() {
        _statusMessage = 'Gagal menginisialisasi: $e';
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      _showSnackBar('Speech recognition tidak tersedia');
      return;
    }

    try {
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _confidence = 0.0;
        _statusMessage = 'Mulai berbicara...';
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            _confidence = result.confidence;
            
            if (result.finalResult) {
              _statusMessage = 'Hasil final diterima';
              // Add to history
              if (_recognizedText.isNotEmpty) {
                _speechHistory.insert(0, _recognizedText);
                // Keep only last 10 results
                if (_speechHistory.length > 10) {
                  _speechHistory.removeLast();
                }
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

  void _clearHistory() {
    setState(() {
      _speechHistory.clear();
      _recognizedText = '';
      _confidence = 0.0;
      _statusMessage = 'Riwayat dibersihkan';
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Speech to Text'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Bersihkan Riwayat',
          ),
        ],
      ),
      body: Container(
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
              // Status Card
              Card(
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
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Current Recognition Result
              Card(
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
                            'Hasil Pengenalan:',
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
                            ? 'Teks yang dikenali akan muncul di sini...' 
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
              ),

              const SizedBox(height: 20),

              // History Section
              Expanded(
                child: Card(
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
                              'Riwayat Pengenalan',
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
                                      // Copy to clipboard logic here if needed
                                      _showSnackBar('Teks disalin: ${_speechHistory[index]}');
                                    },
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
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
}
