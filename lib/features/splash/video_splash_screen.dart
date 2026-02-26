import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({
    super.key,
    required this.onDone,
    this.allowSkip = true,
  });

  final VoidCallback onDone;
  final bool allowSkip;

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late final VideoPlayerController _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/splash_video.mp4')
      ..setLooping(false)
      ..setVolume(1.0)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            _controller.play();
          })
          .catchError((_) {
            _finish();
          });

    _controller.addListener(_maybeFinish);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  void _maybeFinish() {
    if (!mounted || _done) return;
    final value = _controller.value;
    if (!value.isInitialized) return;
    if (value.position >= value.duration && !value.isPlaying) {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_maybeFinish);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF2D1714),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!widget.allowSkip) return;
          _finish();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isReady)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

