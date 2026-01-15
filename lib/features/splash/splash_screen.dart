import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/splash_video.mp4');
    
    try {
      await _controller.initialize();
      setState(() {
        _initialized = true;
      });
      
      _controller.setLooping(false);
      _controller.play();
      
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration && 
            _controller.value.duration.inMilliseconds > 0) {
          _navigateToHome();
        }
      });
      
      Future.delayed(Duration(milliseconds: _controller.value.duration.inMilliseconds + 500), () {
        if (mounted) {
          _navigateToHome();
        }
      });
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToHome();
        }
      });
    }
  }

  void _navigateToHome() {
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
