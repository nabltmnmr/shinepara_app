import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class GuidedCaptureScreen extends ConsumerStatefulWidget {
  const GuidedCaptureScreen({super.key});

  @override
  ConsumerState<GuidedCaptureScreen> createState() => _GuidedCaptureScreenState();
}

class _GuidedCaptureScreenState extends ConsumerState<GuidedCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  
  bool _faceAligned = false;
  bool _lightingGood = false;
  bool _distanceGood = false;
  int _stableFrames = 0;
  static const int _autoCapturThreshold = 30;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('لا توجد كاميرا متاحة');
        return;
      }

      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        _startQualityChecks();
      }
    } catch (e) {
      _showError('حدث خطأ في تشغيل الكاميرا');
    }
  }

  void _startQualityChecks() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _isCapturing) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _faceAligned = true;
        _lightingGood = true;
        _distanceGood = true;
      });

      if (_faceAligned && _lightingGood && _distanceGood) {
        _stableFrames++;
        if (_stableFrames >= _autoCapturThreshold && !_isCapturing) {
          timer.cancel();
          _captureImage();
        }
      } else {
        _stableFrames = 0;
      }
    });
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      
      if (mounted) {
        context.push('/skin-scan/processing', extra: File(image.path));
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      _showError('حدث خطأ أثناء التقاط الصورة');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('التقاط صورة الوجه', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller: _controller!),
                _buildFaceOverlay(),
                _buildGuidanceIndicators(),
                _buildBottomControls(),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildFaceOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 380,
        decoration: BoxDecoration(
          border: Border.all(
            color: _faceAligned && _lightingGood && _distanceGood
                ? AppColors.success
                : Colors.white.withValues(alpha: 0.6),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(140),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(140),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildGuidanceIndicators() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Column(
        children: [
          _buildIndicator('محاذاة الوجه', _faceAligned, Icons.face),
          const SizedBox(height: 8),
          _buildIndicator('الإضاءة', _lightingGood, Icons.lightbulb_outline),
          const SizedBox(height: 8),
          _buildIndicator('المسافة', _distanceGood, Icons.straighten),
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, bool isGood, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isGood 
            ? AppColors.success.withValues(alpha: 0.8)
            : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check_circle : icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final allGood = _faceAligned && _lightingGood && _distanceGood;
    
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          if (allGood && !_isCapturing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'ابقِ ثابتاً... التقاط تلقائي',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
              ),
            ),
          if (_isCapturing)
            const CircularProgressIndicator(color: AppColors.primary)
          else
            GestureDetector(
              onTap: allGood ? _captureImage : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allGood ? Colors.white : Colors.grey,
                  border: Border.all(
                    color: allGood ? AppColors.primary : Colors.grey,
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: allGood ? AppColors.primary : Colors.grey[600],
                  size: 36,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'ضع وجهك داخل الإطار البيضاوي',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class CameraPreview extends StatelessWidget {
  final CameraController controller;

  const CameraPreview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.0,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1 / controller.value.aspectRatio,
          child: CameraPreview2(controller: controller),
        ),
      ),
    );
  }
}

class CameraPreview2 extends StatelessWidget {
  final CameraController controller;

  const CameraPreview2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return controller.buildPreview();
  }
}
