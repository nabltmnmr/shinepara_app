import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';

enum CaptureStatus {
  noFace,
  faceNotCentered,
  tooClose,
  tooFar,
  badLighting,
  unstable,
  ready,
  countdown,
  capturing,
}

class SmartCaptureScreen extends ConsumerStatefulWidget {
  const SmartCaptureScreen({super.key});

  @override
  ConsumerState<SmartCaptureScreen> createState() => _SmartCaptureScreenState();
}

class _SmartCaptureScreenState extends ConsumerState<SmartCaptureScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  List<CameraDescription>? _cameras;
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCapturing = false;

  bool _flashOn = false;
  
  CaptureStatus _status = CaptureStatus.noFace;
  
  Face? _detectedFace;
  double _brightnessLevel = 0.5;
  bool _isStable = false;
  
  int _countdownValue = 3;
  Timer? _countdownTimer;
  
  late AnimationController _ringAnimationController;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription? _accelerometerSubscription;
  final List<double> _accelerometerHistory = [];
  static const int _stabilityHistorySize = 10;
  static const double _stabilityThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initFaceDetector();
    _initCamera();
    _startAccelerometerMonitoring();
  }

  void _initAnimations() {
    _ringAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
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

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      await _cameraController!.startImageStream(_processCameraImage);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('حدث خطأ في تشغيل الكاميرا: $e');
    }
  }

  void _startAccelerometerMonitoring() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _accelerometerHistory.add(magnitude);
      
      if (_accelerometerHistory.length > _stabilityHistorySize) {
        _accelerometerHistory.removeAt(0);
      }
      
      if (_accelerometerHistory.length >= _stabilityHistorySize) {
        final avg = _accelerometerHistory.reduce((a, b) => a + b) / _accelerometerHistory.length;
        final variance = _accelerometerHistory.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) / _accelerometerHistory.length;
        _isStable = variance < _stabilityThreshold;
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isCapturing || !mounted) return;
    _isProcessing = true;

    try {
      _analyzeBrightness(image);
      
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);
      
      if (!mounted) {
        _isProcessing = false;
        return;
      }

      _updateStatus(faces, image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      debugPrint('Face detection error: $e');
    }

    _isProcessing = false;
  }

  void _analyzeBrightness(CameraImage image) {
    if (image.planes.isEmpty) return;
    
    final bytes = image.planes[0].bytes;
    int sum = 0;
    final sampleSize = min(bytes.length, 10000);
    final step = bytes.length ~/ sampleSize;
    
    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
    }
    
    _brightnessLevel = sum / (sampleSize * 255);
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;
      
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      }
      
      rotation ??= InputImageRotation.rotation0deg;

      final format = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final plane = image.planes.first;
      
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  void _updateStatus(List<Face> faces, double imageWidth, double imageHeight) {
    if (!mounted) return;
    
    if (_status == CaptureStatus.capturing) {
      return;
    }
    
    Face? face;
    bool conditionsGood = false;

    if (faces.isEmpty) {
      face = null;
      conditionsGood = false;
    } else {
      face = faces.first;
      final boundingBox = face.boundingBox;
      
      double faceCenterX = boundingBox.center.dx / imageWidth;
      final faceCenterY = boundingBox.center.dy / imageHeight;
      final faceWidth = boundingBox.width / imageWidth;
      final faceHeight = boundingBox.height / imageHeight;
      
      final isFrontCamera = _cameraController?.description.lensDirection == CameraLensDirection.front;
      if (isFrontCamera) {
        faceCenterX = 1.0 - faceCenterX;
      }
      
      final isCentered = (faceCenterX - 0.5).abs() < 0.15 && (faceCenterY - 0.5).abs() < 0.15;
      final isTooClose = faceWidth > 0.7 || faceHeight > 0.8;
      final isTooFar = faceWidth < 0.25 || faceHeight < 0.3;
      final hasGoodLighting = _brightnessLevel > 0.2 && _brightnessLevel < 0.85;
      
      conditionsGood = isCentered && !isTooClose && !isTooFar && hasGoodLighting && _isStable;
    }

    if (_status == CaptureStatus.countdown) {
      setState(() {
        _detectedFace = face;
      });
      
      if (!conditionsGood) {
        _cancelCountdown();
        _updateStatusFromConditions(faces, imageWidth, imageHeight, face);
      }
      return;
    }

    _updateStatusFromConditions(faces, imageWidth, imageHeight, face);
  }

  void _updateStatusFromConditions(List<Face> faces, double imageWidth, double imageHeight, Face? face) {
    CaptureStatus newStatus;

    if (faces.isEmpty || face == null) {
      newStatus = CaptureStatus.noFace;
    } else {
      final boundingBox = face.boundingBox;
      
      double faceCenterX = boundingBox.center.dx / imageWidth;
      final faceCenterY = boundingBox.center.dy / imageHeight;
      final faceWidth = boundingBox.width / imageWidth;
      final faceHeight = boundingBox.height / imageHeight;
      
      final isFrontCamera = _cameraController?.description.lensDirection == CameraLensDirection.front;
      if (isFrontCamera) {
        faceCenterX = 1.0 - faceCenterX;
      }
      
      final isCentered = (faceCenterX - 0.5).abs() < 0.15 && (faceCenterY - 0.5).abs() < 0.15;
      final isTooClose = faceWidth > 0.7 || faceHeight > 0.8;
      final isTooFar = faceWidth < 0.25 || faceHeight < 0.3;
      final hasGoodLighting = _brightnessLevel > 0.2 && _brightnessLevel < 0.85;
      
      if (!isCentered) {
        newStatus = CaptureStatus.faceNotCentered;
      } else if (isTooClose) {
        newStatus = CaptureStatus.tooClose;
      } else if (isTooFar) {
        newStatus = CaptureStatus.tooFar;
      } else if (!hasGoodLighting) {
        newStatus = CaptureStatus.badLighting;
      } else if (!_isStable) {
        newStatus = CaptureStatus.unstable;
      } else {
        newStatus = CaptureStatus.ready;
      }
    }

    setState(() {
      _status = newStatus;
      _detectedFace = face;
    });

    final canStartTest = ref.read(scanCreditsProvider).when(
          data: (credits) => credits.credits > 0,
          loading: () => false,
          error: (_, __) => false,
        );

    if (canStartTest && newStatus == CaptureStatus.ready && _countdownTimer == null && !_isCapturing) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() {
      _status = CaptureStatus.countdown;
      _countdownValue = 3;
    });
    
    _ringAnimationController.forward();
    HapticFeedback.lightImpact();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdownValue--;
      });
      
      HapticFeedback.lightImpact();
      
      if (_countdownValue <= 0) {
        timer.cancel();
        _countdownTimer = null;
        _captureImage();
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _ringAnimationController.reset();
    if (_status == CaptureStatus.countdown) {
      setState(() {
        _countdownValue = 3;
      });
    }
  }

  Future<void> _captureImage() async {
    final canStartTest = ref.read(scanCreditsProvider).when(
          data: (credits) => credits.credits > 0,
          loading: () => false,
          error: (_, __) => false,
        );
    if (!canStartTest) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _status = CaptureStatus.capturing;
    });

    try {
      await _cameraController!.stopImageStream();
      
      final image = await _cameraController!.takePicture();
      
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        context.push('/skin-scan/processing', extra: File(image.path));
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _status = CaptureStatus.noFace;
      });
      _showError('حدث خطأ أثناء التقاط الصورة');
      await _cameraController!.startImageStream(_processCameraImage);
    }
  }

  void _manualCapture() {
    final canStartTest = ref.read(scanCreditsProvider).when(
          data: (credits) => credits.credits > 0,
          loading: () => false,
          error: (_, __) => false,
        );
    if (!canStartTest) {
      _showError('لا يوجد رصيد كافٍ لبدء الفحص');
      return;
    }

    if (_status == CaptureStatus.ready || 
        _status == CaptureStatus.countdown ||
        _detectedFace != null) {
      _cancelCountdown();
      _captureImage();
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _flashOn = !_flashOn);
    try {
      await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    } catch (_) {
      // Some devices/front cameras don't support torch; revert UI state silently.
      if (mounted) setState(() => _flashOn = false);
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
    _countdownTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    _ringAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(scanCreditsProvider);
    final canStartTest = creditsAsync.when(
      data: (credits) => credits.credits > 0,
      loading: () => false,
      error: (_, __) => false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: _isInitialized
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(),
                  const _WarmVignetteOverlay(),
                  _buildHeader(),
                  _buildFaceFrameOverlay(),
                  _buildBottomGlassArea(canStartTest: canStartTest),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'جاري تشغيل الكاميرا...',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null) return const SizedBox.shrink();
    
    return Transform.scale(
      scale: 1.0,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1 / _cameraController!.value.aspectRatio,
          child: _cameraController!.buildPreview(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.close,
              onPressed: () => context.pop(),
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SHINE AI',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textOffWhite.withValues(alpha: 0.62),
                    letterSpacing: 3.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Skin Analysis',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textOffWhite,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _CircleIconButton(
              icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              onPressed: _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceFrameOverlay() {
    final isReady = _status == CaptureStatus.ready || _status == CaptureStatus.countdown;
    final showCountdown = _status == CaptureStatus.countdown;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isReady ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth * 0.78).clamp(280.0, 420.0);
            final h = (c.maxHeight * 0.62).clamp(420.0, 590.0);
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(w, h),
                  painter: _FaceFramePainter(
                    strokeColor: AppColors.textOffWhite.withValues(alpha: 0.35),
                    scanColor: AppColors.primary,
                  ),
                ),
                if (showCountdown)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
                    ),
                    child: Text(
                      '$_countdownValue',
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.textOffWhite,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomGlassArea({required bool canStartTest}) {
    // If you later wire real metrics, replace these placeholders.
    final hydration = 0.45;
    final elasticity = 0.72;
    final textureIsScanning = _status != CaptureStatus.capturing;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              'Align face within frame',
              textDirection: TextDirection.ltr,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textOffWhite,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Hold still for optimal scanning',
              textDirection: TextDirection.ltr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOffWhite.withValues(alpha: 0.60),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _GlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          icon: Icons.water_drop_outlined,
                          label: 'Hydration',
                          progress: hydration,
                          valueText: '${(hydration * 100).round()}%',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MetricColumn(
                          icon: Icons.autorenew_rounded,
                          label: 'Elasticity',
                          progress: elasticity,
                          valueText: '${(elasticity * 100).round()}%',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MetricColumn(
                          icon: Icons.grain_rounded,
                          label: 'Texture',
                          progress: 0.55,
                          valueText: textureIsScanning ? 'Scanning…' : '55%',
                          isScanning: textureIsScanning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _AssistantAvatar(
                        imageAsset: 'assets/images/placeholder.png',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatusPill(
                          text: 'Analyzing skin barrier…',
                        ),
                      ),
                    ],
                  ),
                  if (!canStartTest) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, size: 16, color: AppColors.textOffWhite),
                          const SizedBox(width: 10),
                          Text(
                            'Preview only — add credits to start',
                            textDirection: TextDirection.ltr,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textOffWhite.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PrimaryCtaButton(
                    label: 'Generate Routine',
                    onPressed: (!canStartTest || _isCapturing) ? null : _manualCapture,
                    isLoading: _isCapturing,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 16, color: AppColors.textOffWhite.withValues(alpha: 0.40)),
                const SizedBox(width: 8),
                Text(
                  'Images are processed locally and never stored.',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOffWhite.withValues(alpha: 0.40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _WarmVignetteOverlay extends StatelessWidget {
  const _WarmVignetteOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.15),
              radius: 1.1,
              colors: [
                const Color(0xFF2A1B16).withValues(alpha: 0.22),
                const Color(0xFF120B09).withValues(alpha: 0.78),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF120B09).withValues(alpha: 0.35),
                  const Color(0xFF120B09).withValues(alpha: 0.10),
                  const Color(0xFF120B09).withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.30),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: AppColors.textOffWhite, size: 24),
      ),
    );
  }
}

class _FaceFramePainter extends CustomPainter {
  final Color strokeColor;
  final Color scanColor;

  _FaceFramePainter({
    required this.strokeColor,
    required this.scanColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawOval(rect.deflate(6), stroke);

    // Orange scan line (near top of oval).
    final y = rect.top + (rect.height * 0.19);
    final linePaint = Paint()
      ..color = scanColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = scanColor.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final left = rect.left + 24;
    final right = rect.right - 24;
    canvas.drawLine(Offset(left, y), Offset(right, y), glowPaint);
    canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
  }

  @override
  bool shouldRepaint(covariant _FaceFramePainter oldDelegate) {
    return strokeColor != oldDelegate.strokeColor || scanColor != oldDelegate.scanColor;
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1F1A).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final double progress;
  final String valueText;
  final bool isScanning;

  const _MetricColumn({
    required this.icon,
    required this.label,
    required this.progress,
    required this.valueText,
    this.isScanning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.16),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textDirection: TextDirection.ltr,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOffWhite.withValues(alpha: 0.70),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          valueText,
          textDirection: TextDirection.ltr,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textOffWhite,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  final String imageAsset;
  const _AssistantAvatar({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.black.withValues(alpha: 0.25),
            child: const Icon(Icons.smart_toy_outlined, color: AppColors.textOffWhite),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOffWhite.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryCtaButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      width: double.infinity,
      child: Opacity(
        opacity: onPressed == null ? 0.55 : 1,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFF35A2A),
                  Color(0xFFFF7A3D),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF35A2A).withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
