import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'models/family_models.dart';
import 'widgets/app_background_pattern.dart';
import 'widgets/reward_screen.dart';

class MemaknaiScreen extends StatefulWidget {
  final EnhancedSurah surah;

  const MemaknaiScreen({super.key, required this.surah});

  @override
  State<MemaknaiScreen> createState() => _MemaknaiScreenState();
}

class _MemaknaiScreenState extends State<MemaknaiScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Star animation controller
  late AnimationController _starAnimationController;
  late Animation<double> _starScaleAnimation;
  late Animation<double> _starOpacityAnimation;

  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoCompleted = false;

  // Learning flow
  bool _showVideo = true;

  // Quiz state
  int _currentQuestionIndex = 0;
  List<int> _selectedAnswers = [];
  bool _isQuizCompleted = false;
  int _correctAnswers = 0;

  // Completion tracking
  bool _hasCompletedMeaning = false;

  // Reward screen
  bool _showReward = false;
  bool _showStarAnimation = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
    _initializeQuiz();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Initialize star animation
    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _starScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _starAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _starOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _starAnimationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _initializeQuiz() {
    _selectedAnswers = List.filled(3, -1); // 3 questions
  }

  void _initializeVideo() {
    // Initialize video player dengan video asset lokal
    _videoController = VideoPlayerController.asset('assets/videos/an_naas.mov');

    _videoController!.initialize().then((_) {
      setState(() {
        _isVideoInitialized = true;
      });

      // Listen untuk video completion
      _videoController!.addListener(_videoListener);
    });
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_videoController!.value.position >=
          _videoController!.value.duration) {
        setState(() {
          _isVideoCompleted = true;
        });
      }
    }
  }

  void _proceedToQuiz() {
    setState(() {
      _showVideo = false;
    });
  }

  void _enterFullScreen() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              _FullScreenVideoPlayer(controller: _videoController!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _starAnimationController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackgroundPattern(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildCustomAppBar(),
                  _buildSurahHeader(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color.fromARGB(255, 228, 142, 20),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: _showVideo
                            ? _buildVideoInterface()
                            : _buildQuizInterface(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Star animation overlay
          if (_showStarAnimation) _buildStarAnimation(),
          // Reward screen overlay
          if (_showReward)
            RewardScreen(
              title: '🎉 Selamat!',
              subtitle: _isQuizCompleted
                  ? 'Anda telah menyelesaikan kuis dengan skor $_correctAnswers/3!\nTugas memaknai selesai!'
                  : 'Tugas memaknai selesai!',
              onComplete: () {
                setState(() {
                  _showReward = false;
                });

                // Return to previous screen with success result
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SvgPicture.asset(
              'assets/exitsegmen.svg',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              SvgPicture.asset('assets/amma_play_logo.svg', height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeader() {
    return Column(
      children: [
        // Nama surat dengan suratbar.svg
        Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              'assets/suratbar.svg',
              width: MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.contain,
            ),
            Text(
              widget.surah.namaLatin,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [
                  Shadow(
                    offset: Offset(-2.0, -2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(2.0, -2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(-2.0, 2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Arti nama dengan subsuratbar.svg
            Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/subsuratbar.svg',
                  width: 120,
                  fit: BoxFit.contain,
                ),
                Text(
                  widget.surah.artiNama ?? 'Arti',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.5, -1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(1.5, -1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(-1.5, 1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Mode Memaknai dengan subsuratbar.svg
            Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/subsuratbar.svg',
                  width: 120,
                  fit: BoxFit.contain,
                ),
                Text(
                  'Memaknai',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.5, -1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(1.5, -1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(-1.5, 1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
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

  Widget _buildVideoInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video section header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D4C56),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Video Pembelajaran Surat An-Nas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Video player with better proportions
          Expanded(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 250, maxHeight: 350),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF0D4C56), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _isVideoInitialized
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final videoAspectRatio =
                              _videoController!.value.aspectRatio;
                          final containerAspectRatio =
                              constraints.maxWidth / constraints.maxHeight;

                          return Center(
                            child: AspectRatio(
                              aspectRatio: videoAspectRatio,
                              child: Container(
                                width: videoAspectRatio > containerAspectRatio
                                    ? constraints.maxWidth
                                    : null,
                                height: videoAspectRatio <= containerAspectRatio
                                    ? constraints.maxHeight
                                    : null,
                                child: Stack(
                                  children: [
                                    VideoPlayer(_videoController!),
                                    // Video controls overlay
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Play/Pause button center
                                            Center(
                                              child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (_videoController!
                                                        .value
                                                        .isPlaying) {
                                                      _videoController!.pause();
                                                    } else {
                                                      _videoController!.play();
                                                    }
                                                  });
                                                },
                                                icon: Icon(
                                                  _videoController!
                                                          .value
                                                          .isPlaying
                                                      ? Icons
                                                            .pause_circle_filled
                                                      : Icons
                                                            .play_circle_filled,
                                                  size: 64,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            // Fullscreen button bottom right
                                            Positioned(
                                              bottom: 16,
                                              right: 16,
                                              child: IconButton(
                                                onPressed: _enterFullScreen,
                                                icon: const Icon(
                                                  Icons.fullscreen,
                                                  size: 32,
                                                  color: Colors.white,
                                                ),
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
                          );
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0D4C56),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress to quiz button
          ElevatedButton.icon(
            onPressed: _isVideoCompleted ? _proceedToQuiz : null,
            icon: const Icon(Icons.quiz, size: 20),
            label: Text(
              _isVideoCompleted
                  ? 'Lanjut ke Kuis'
                  : 'Selesaikan video untuk melanjutkan',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isVideoCompleted
                  ? const Color(0xFF0D4C56)
                  : const Color(0xFFCCCCCC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInterface() {
    // Quiz questions data (reduced to 3 questions)
    final List<Map<String, dynamic>> quizQuestions = [
      {
        'question': 'Mengapa Aira merasa takut di dalam cerita?',
        'options': [
          'Karena mendengar suara aneh',
          'Karena kamar mandi gelap dan sepi',
          'Karena dimarahi kakaknya',
          'Karena melihat hantu',
        ],
        'correctAnswer': 1,
        'explanation':
            'Pelajaran yang didapat adalah pentingnya berlindung kepada Allah dari segala kejahatan.',
      },
      {
        'question': 'Siapakah yang menenangkan Aira dan memberinya nasihat?',
        'options': ['Kak Raka', 'Ibu', 'Ayah', 'Nenek'],
        'correctAnswer': 3,
        'explanation':
            'Nenek menenangkan Aira dan memberinya nasihat untuk selalu berdoa.',
      },
      {
        'question':
            ' Apa nasihat yang diberikan untuk mengatasi rasa takut Aira?',
        'options': [
          'Menyalakan lampu',
          'Tidur kembali',
          'Membaca surat An-Naas',
          'Menunggu orang tua pulang',
        ],
        'correctAnswer': 2,
        'explanation':
            'Tema utama Surat An-Nas adalah tentang berlindung kepada Allah dari kejahatan jin dan manusia.',
      },
    ];

    if (!_isQuizCompleted) {
      return _buildQuizQuestion(quizQuestions);
    } else {
      return _buildQuizResults(quizQuestions);
    }
  }

  Widget _buildQuizQuestion(List<Map<String, dynamic>> quizQuestions) {
    final currentQuestion = quizQuestions[_currentQuestionIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D4C56),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pertanyaan ${_currentQuestionIndex + 1} dari ${quizQuestions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D463),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${((_currentQuestionIndex + 1) / quizQuestions.length * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF0D4C56),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0D4C56), width: 2),
            ),
            child: Text(
              currentQuestion['question'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D4C56),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion['options'].length,
              itemBuilder: (context, index) {
                final isSelected =
                    _selectedAnswers[_currentQuestionIndex] == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectAnswer(_currentQuestionIndex, index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0D4C56)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0D4C56)
                                : const Color(0xFFE0E0E0),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF9D463)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF9D463)
                                      : const Color(0xFFCCCCCC),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Color(0xFF0D4C56),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                currentQuestion['options'][index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF0D4C56),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              _currentQuestionIndex > 0
                  ? ElevatedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Sebelumnya'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        foregroundColor: const Color(0xFF0D4C56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),

              // Next/Finish button
              ElevatedButton.icon(
                onPressed: _selectedAnswers[_currentQuestionIndex] != -1
                    ? _nextQuestion
                    : null,
                icon: Icon(
                  _currentQuestionIndex == quizQuestions.length - 1
                      ? Icons.check
                      : Icons.arrow_forward,
                  size: 18,
                ),
                label: Text(
                  _currentQuestionIndex == quizQuestions.length - 1
                      ? 'Selesai'
                      : 'Selanjutnya',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedAnswers[_currentQuestionIndex] != -1
                      ? const Color(0xFF0D4C56)
                      : const Color(0xFFCCCCCC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResults(List<Map<String, dynamic>> quizQuestions) {
    final percentage = (_correctAnswers / quizQuestions.length * 100).round();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Score header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: percentage >= 80
                    ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                    : percentage >= 60
                    ? [const Color(0xFFF57C00), const Color(0xFFE65100)]
                    : [const Color(0xFFE53935), const Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  percentage >= 80
                      ? Icons.star_rounded
                      : percentage >= 60
                      ? Icons.thumb_up_rounded
                      : Icons.refresh_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Skor Anda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_correctAnswers/${quizQuestions.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Results breakdown
          Expanded(
            child: ListView.builder(
              itemCount: quizQuestions.length,
              itemBuilder: (context, index) {
                final question = quizQuestions[index];
                final userAnswer = _selectedAnswers[index];
                final correctAnswer = question['correctAnswer'];
                final isCorrect = userAnswer == correctAnswer;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pertanyaan ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question['question'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isCorrect) ...[
                        Text(
                          'Jawaban Anda: ${question['options'][userAnswer]}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Jawaban Benar: ${question['options'][correctAnswer]}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question['explanation'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarAnimation() {
    return AnimatedBuilder(
      animation: _starAnimationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Opacity(
              opacity: _starOpacityAnimation.value,
              child: Transform.scale(
                scale: _starScaleAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D463),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9D463).withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectAnswer(int questionIndex, int answerIndex) {
    setState(() {
      _selectedAnswers[questionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < 2) {
      // 3 questions (0-2)
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _finishQuiz() {
    // Calculate score based on 3 questions
    _correctAnswers = 0;
    final quizQuestions = [
      {'correctAnswer': 1}, // Kamar mandi gelap dan sepi
      {'correctAnswer': 3}, // Nenek
      {'correctAnswer': 2}, // Membaca surat An-Naas
    ];
    for (int i = 0; i < quizQuestions.length; i++) {
      if (_selectedAnswers[i] == quizQuestions[i]['correctAnswer']) {
        _correctAnswers++;
      }
    }

    setState(() {
      _isQuizCompleted = true;
      _showStarAnimation = true;
    });

    // Start star animation
    _starAnimationController.forward();

    print('DEBUG: Quiz completed. Score: $_correctAnswers/3');

    // Complete meaning task after star animation
    Future.delayed(const Duration(seconds: 2), () {
      _completeMeaningTask();
    });
  }

  // Complete meaning task
  void _completeMeaningTask() {
    if (!_hasCompletedMeaning) {
      setState(() {
        _hasCompletedMeaning = true;
        _showStarAnimation = false; // Hide star animation
      });

      print(
        'DEBUG: Meaning task completed! Quiz finished with score: $_correctAnswers/3',
      );

      // Give a short delay before showing reward screen for better UX
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showReward = true; // Show reward screen after delay
          });
        }
      });
    }
  }
}

// Full screen video player class
class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullScreenVideoPlayer({required this.controller});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Hide controls after 3 seconds
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(widget.controller),
                if (_showControls)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Close button top left
                        Positioned(
                          top: 40,
                          left: 16,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Play/Pause button center
                        Center(
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                if (widget.controller.value.isPlaying) {
                                  widget.controller.pause();
                                } else {
                                  widget.controller.play();
                                }
                              });
                            },
                            icon: Icon(
                              widget.controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Progress bar bottom
                        Positioned(
                          bottom: 50,
                          left: 16,
                          right: 16,
                          child: VideoProgressIndicator(
                            widget.controller,
                            allowScrubbing: true,
                            padding: const EdgeInsets.all(8),
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFF9D463),
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.white24,
                            ),
                          ),
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
