import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Star animation controller
  late AnimationController _starAnimationController;
  late Animation<double> _starScaleAnimation;
  late Animation<double> _starOpacityAnimation;

  // Completion tracking
  bool _hasWatchedToEnd = false;
  bool _hasCompletedMeaning = false;
  
  // Reward screen
  bool _showReward = false;
  bool _showStarAnimation = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
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
      CurvedAnimation(parent: _starAnimationController, curve: Curves.elasticOut),
    );
    _starOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _starAnimationController, 
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/videos/an_naas.mov',
      );
      await _videoController!.initialize();

      _videoController!.addListener(_videoListener);

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _isPlaying = _videoController!.value.isPlaying;
      });

      // Check if video has reached the end (100% completion)
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;

      if (duration.inMilliseconds > 0 &&
          position.inMilliseconds >= duration.inMilliseconds) {
        // Video completed 100%
        _markVideoAsWatched();
      }
    }
  }

  // Mark video as watched to completion
  void _markVideoAsWatched() {
    if (!_hasWatchedToEnd) {
      setState(() {
        _hasWatchedToEnd = true;
        _showStarAnimation = true; // Show star animation immediately
      });

      // Start star animation
      _starAnimationController.forward();

      print('DEBUG: Video watched to end. Starting star animation, then completing meaning task.');
      
      // Complete meaning task after star animation
      Future.delayed(const Duration(seconds: 2), () {
        _completeMeaningTask();
      });
    }
  }

  // Complete meaning task
  void _completeMeaningTask() {
    if (!_hasCompletedMeaning) {
      setState(() {
        _hasCompletedMeaning = true;
        _showStarAnimation = false; // Hide star animation
      });

      print('DEBUG: Meaning task completed! Video watched to end.');

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

  void _togglePlayPause() {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _fadeController.dispose();
    _starAnimationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _buildFullscreenVideo();
    }

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
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: _buildVideoPlayer(),
                      ),
                    ),
                  ),
                  _buildVideoDescription(),
                ],
              ),
            ),
          ),
          // Star animation overlay
          if (_showStarAnimation)
            _buildStarAnimation(),
          // Reward screen overlay
          if (_showReward)
            RewardScreen(
              title: '🎉 Selamat!',
              subtitle: 'Anda telah menonton video sampai selesai.\nTugas memaknai selesai!',
              onComplete: () {
                setState(() {
                  _showReward = false;
                });
                
                // Return to previous screen with success result
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.of(context).pop(true); // Return true to indicate completion
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFullscreenVideo() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControlsVisibility,
        child: Stack(
          children: [
            Center(child: _buildVideoPlayerCore()),
            if (_showControls) _buildFullscreenControls(),
          ],
        ),
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
              // Debug button to complete video instantly
              GestureDetector(
                onTap: () {
                  print('DEBUG: Force complete video');
                  _markVideoAsWatched();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selesai',
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
                  Shadow(
                    offset: Offset(0.0, -2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(2.0, 0.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(0.0, 2.0),
                    color: Colors.orange,
                    blurRadius: 1.0,
                  ),
                  Shadow(
                    offset: Offset(-2.0, 0.0),
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
            // Video info dengan subsuratbar.svg
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
                      Shadow(
                        offset: Offset(0.0, -1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(1.5, 0.0),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(0.0, 1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(-1.5, 0.0),
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
                      Shadow(
                        offset: Offset(0.0, -1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(1.5, 0.0),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(0.0, 1.5),
                        color: Colors.orange,
                        blurRadius: 0.8,
                      ),
                      Shadow(
                        offset: Offset(-1.5, 0.0),
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

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControlsVisibility,
      child: Stack(
        children: [
          _buildVideoPlayerCore(),
          if (_showControls) _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerCore() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF9D463)),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat video...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildVideoControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildControlButton(Icons.fullscreen, _toggleFullscreen),
                ],
              ),
            ),
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProgressBar(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        Icons.replay_10,
                        () => _seekRelative(-10),
                      ),
                      _buildControlButton(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        _togglePlayPause,
                        size: 48,
                      ),
                      _buildControlButton(
                        Icons.forward_10,
                        () => _seekRelative(10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top controls
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildControlButton(Icons.arrow_back, _toggleFullscreen),
                    Text(
                      'Surat ${widget.surah.namaLatin}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildControlButton(
                      Icons.fullscreen_exit,
                      _toggleFullscreen,
                    ),
                  ],
                ),
              ),
            ),
            // Bottom controls
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProgressBar(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          Icons.replay_10,
                          () => _seekRelative(-10),
                        ),
                        _buildControlButton(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          _togglePlayPause,
                          size: 56,
                        ),
                        _buildControlButton(
                          Icons.forward_10,
                          () => _seekRelative(10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (_videoController == null) return const SizedBox.shrink();

    return Column(
      children: [
        VideoProgressIndicator(
          _videoController!,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          colors: const VideoProgressColors(
            playedColor: Color(0xFFF9D463),
            bufferedColor: Colors.white30,
            backgroundColor: Colors.white12,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_videoController!.value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(_videoController!.value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed, {
    double size = 40,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size * 0.6),
        onPressed: onPressed,
        iconSize: size * 0.6,
      ),
    );
  }

  void _seekRelative(int seconds) {
    if (_videoController != null) {
      final position = _videoController!.value.position;
      final newPosition = position + Duration(seconds: seconds);
      _videoController!.seekTo(newPosition);
    }
  }

  Widget _buildVideoDescription() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color.fromARGB(255, 228, 142, 20), width: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D4C56),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tentang Video',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D4C56),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Video pembelajaran Surat ${widget.surah.namaLatin} ini akan membantu Anda memahami makna dan hikmah dari setiap ayat. Gunakan kontrol video untuk memutar, menjeda, atau menonton dalam mode layar penuh.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF666666),
            ),
          ),
          // Progress indicator for video completion
          if (_hasWatchedToEnd)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Video telah ditonton sampai selesai!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFeatureChip('Layar Penuh', Icons.fullscreen),
              const SizedBox(width: 8),
              _buildFeatureChip('HD Quality', Icons.hd),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9D463).withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF9D463).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0D4C56)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0D4C56),
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
}
