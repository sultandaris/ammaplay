import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'hafalan_surat.dart'; // Import SurahInfo

class MemaknaiScreen extends StatefulWidget {
  final SurahInfo surahInfo;

  const MemaknaiScreen({super.key, required this.surahInfo});

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
      backgroundColor: const Color(0xFF0D4C56),
      body: SafeArea(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Memaknai',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9D463),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Surat ${widget.surahInfo.name}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
                      'Surat ${widget.surahInfo.name}',
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
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          const Text(
            'Video pembelajaran Surat An-Naas ini akan membantu Anda memahami makna dan hikmah dari setiap ayat. Gunakan kontrol video untuk memutar, menjeda, atau menonton dalam mode layar penuh.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF666666),
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
}
