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

mixin _SmartCaptureLogic<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, TickerProvider {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  List<CameraDescription>? _cameras;
  InputImageRotation _lastImageRotation = InputImageRotation.rotation0deg;

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCapturing = false;

  bool _flashOn = false;

  CaptureStatus _status = CaptureStatus.noFace;

  Face? _detectedFace;
  double _brightnessLevel = 0.5;
  // Assume stable until we have enough accelerometer samples to judge stability.
  // This avoids blocking auto-capture on emulators/devices where sensors are unavailable.
  bool _isStable = true;
  double _stabilityScore = 0.0; // 0..1 derived from accelerometer variance
  double _alignmentScore = 0.0; // 0..1 derived from face centering distance

  int _countdownValue = 3;
  Timer? _countdownTimer;
  int _countdownBadFrames = 0;

  late AnimationController _ringAnimationController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  StreamSubscription? _accelerometerSubscription;
  final List<double> _accelerometerHistory = [];
  static const int _stabilityHistorySize = 10;
  static const double _stabilityThreshold = 0.5;

  int? get hydrationPercent {
    if (!_isInitialized) return null;
    return (_brightnessLevel * 100).round().clamp(0, 100);
  }

  int? get elasticityPercent {
    if (!_isInitialized) return null;
    if (_accelerometerHistory.length < _stabilityHistorySize) return null;
    return (_stabilityScore * 100).round().clamp(0, 100);
  }

  int? get texturePercent {
    if (!_isInitialized) return null;
    if (_detectedFace == null) return null;
    // Kept nullable by design; if not reliable yet, UI shows “Scanning…”.
    final v = (_alignmentScore * 100).round().clamp(0, 100);
    return v == 0 ? null : v;
  }

  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  bool get flashOn => _flashOn;
  CaptureStatus get status => _status;
  int get countdownValue => _countdownValue;
  double get alignmentScore => _alignmentScore;
  AnimationController get pulseController => _pulseController;
  Animation<double> get pulseAnimation => _pulseAnimation;
  AnimationController get scanLineController => _scanLineController;
  Animation<double> get scanLineAnimation => _scanLineAnimation;

  void initSmartCapture({required bool startCamera}) {
    _initAnimations();
    _initFaceDetector();
    _startAccelerometerMonitoring();
    if (startCamera) {
      unawaited(ensureCameraRunning());
    }
  }

  Future<void> ensureCameraRunning() async {
    if (!mounted) return;
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      if (_cameraController!.value.isPreviewPaused) {
        try {
          await _cameraController!.resumePreview();
        } catch (_) {}
      }
      if (!_cameraController!.value.isStreamingImages && !_isCapturing) {
        try {
          await _cameraController!.startImageStream(_processCameraImage);
        } catch (_) {}
      }
      return;
    }

    await _initCamera();
  }

  Future<void> pauseCamera() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    try {
      if (!controller.value.isPreviewPaused) {
        await controller.pausePreview();
      }
    } catch (_) {}
  }

  void disposeSmartCapture() {
    _countdownTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _cameraController?.dispose();
    _faceDetector?.close();
    _ringAnimationController.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
  }

  Widget buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Transform.scale(
      scale: 1.0,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1 / controller.value.aspectRatio,
          child: controller.buildPreview(),
        ),
      ),
    );
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

    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);
    _scanLineAnimation = CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
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
        imageFormatGroup:
            Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
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

      final magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _accelerometerHistory.add(magnitude);

      if (_accelerometerHistory.length > _stabilityHistorySize) {
        _accelerometerHistory.removeAt(0);
      }

      if (_accelerometerHistory.length >= _stabilityHistorySize) {
        final avg = _accelerometerHistory.reduce((a, b) => a + b) /
            _accelerometerHistory.length;
        final variance = _accelerometerHistory
                .map((v) => (v - avg) * (v - avg))
                .reduce((a, b) => a + b) /
            _accelerometerHistory.length;
        final stable = variance < _stabilityThreshold;
        // Map variance into a 0..1 stability score for UI (lower variance -> higher score).
        final score = (1.0 - (variance / (_stabilityThreshold * 2.0)))
            .clamp(0.0, 1.0);

        // Avoid rebuilding too frequently.
        final shouldRebuild =
            stable != _isStable || (score - _stabilityScore).abs() > 0.03;
        _isStable = stable;
        _stabilityScore = score;
        if (shouldRebuild && mounted) setState(() {});
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

      // MLKit bounding boxes are reported in the *upright* image coordinate space,
      // so when we pass a rotation we must also normalize against the rotated size.
      double effectiveWidth = image.width.toDouble();
      double effectiveHeight = image.height.toDouble();
      if (_lastImageRotation == InputImageRotation.rotation90deg ||
          _lastImageRotation == InputImageRotation.rotation270deg) {
        effectiveWidth = image.height.toDouble();
        effectiveHeight = image.width.toDouble();
      }

      _updateStatus(faces, effectiveWidth, effectiveHeight);
    } catch (e) {
      debugPrint('Face detection error: $e');
    }

    _isProcessing = false;
  }

  void _analyzeBrightness(CameraImage image) {
    if (image.planes.isEmpty) return;

    final bytes = image.planes[0].bytes;
    if (bytes.isEmpty) return;

    // Android NV21: plane[0] contains luminance (Y) bytes -> OK to sample directly.
    if (Platform.isAndroid) {
      int sum = 0;
      final sampleSize = min(bytes.length, 10000);
      final step = max(1, bytes.length ~/ sampleSize);
      int count = 0;

      for (int i = 0; i < bytes.length; i += step) {
        sum += bytes[i];
        count++;
      }
      if (count == 0) return;
      _brightnessLevel = sum / (count * 255);
      return;
    }

    // iOS BGRA8888: bytes are BGRA pixels. Estimate brightness via luma.
    // Sample every Nth pixel to keep it fast.
    if (Platform.isIOS) {
      const int stride = 4; // BGRA
      final pixelCount = bytes.length ~/ stride;
      if (pixelCount <= 0) return;

      final stepPixels = max(1, pixelCount ~/ 2500); // ~2500 samples max
      double sumLuma = 0;
      int count = 0;

      for (int p = 0; p < pixelCount; p += stepPixels) {
        final i = p * stride;
        if (i + 2 >= bytes.length) break;
        final b = bytes[i].toDouble();
        final g = bytes[i + 1].toDouble();
        final r = bytes[i + 2].toDouble();
        // Rec. 709 luma approximation.
        final luma = (0.2126 * r + 0.7152 * g + 0.0722 * b);
        sumLuma += luma;
        count++;
      }
      if (count == 0) return;
      _brightnessLevel = (sumLuma / count) / 255.0;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;

      // Derive rotation from the sensor orientation; using device orientation here
      // would be more precise, but this keeps things stable and cross-platform.
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
      _lastImageRotation = rotation;

      final format =
          Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

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

      final isFrontCamera =
          _cameraController?.description.lensDirection == CameraLensDirection.front;
      if (isFrontCamera) {
        faceCenterX = 1.0 - faceCenterX;
      }

      final isCentered = (faceCenterX - 0.5).abs() < 0.15 &&
          (faceCenterY - 0.5).abs() < 0.15;
      final isTooClose = faceWidth > 0.7 || faceHeight > 0.8;
      final isTooFar = faceWidth < 0.25 || faceHeight < 0.3;
      final hasGoodLighting = _brightnessLevel > 0.2 && _brightnessLevel < 0.85;
      final stableOk = _accelerometerHistory.length < _stabilityHistorySize || _isStable;

      conditionsGood =
          isCentered && !isTooClose && !isTooFar && hasGoodLighting && stableOk;
    }

    if (_status == CaptureStatus.countdown) {
      setState(() {
        _detectedFace = face;
      });

      if (!conditionsGood) {
        // Give a little grace during countdown to avoid jitter cancelling instantly.
        _countdownBadFrames++;
        if (_countdownBadFrames >= 6) {
          _cancelCountdown();
          _updateStatusFromConditions(faces, imageWidth, imageHeight, face);
        }
      } else {
        _countdownBadFrames = 0;
      }
      return;
    }

    _updateStatusFromConditions(faces, imageWidth, imageHeight, face);
  }

  void _updateStatusFromConditions(
      List<Face> faces, double imageWidth, double imageHeight, Face? face) {
    CaptureStatus newStatus;
    double alignmentScore = 0.0;

    if (faces.isEmpty || face == null) {
      newStatus = CaptureStatus.noFace;
    } else {
      final boundingBox = face.boundingBox;

      double faceCenterX = boundingBox.center.dx / imageWidth;
      final faceCenterY = boundingBox.center.dy / imageHeight;
      final faceWidth = boundingBox.width / imageWidth;
      final faceHeight = boundingBox.height / imageHeight;

      final isFrontCamera =
          _cameraController?.description.lensDirection == CameraLensDirection.front;
      if (isFrontCamera) {
        faceCenterX = 1.0 - faceCenterX;
      }

      final isCentered = (faceCenterX - 0.5).abs() < 0.15 &&
          (faceCenterY - 0.5).abs() < 0.15;
      final isTooClose = faceWidth > 0.7 || faceHeight > 0.8;
      final isTooFar = faceWidth < 0.25 || faceHeight < 0.3;
      final hasGoodLighting = _brightnessLevel > 0.2 && _brightnessLevel < 0.85;
      final stableOk = _accelerometerHistory.length < _stabilityHistorySize || _isStable;

      // 0..1 score for how close the face center is to the oval center target.
      final dx = (faceCenterX - 0.5).abs();
      final dy = (faceCenterY - 0.5).abs();
      final dist = sqrt(dx * dx + dy * dy);
      alignmentScore = (1.0 - (dist / 0.35)).clamp(0.0, 1.0);

      if (!isCentered) {
        newStatus = CaptureStatus.faceNotCentered;
      } else if (isTooClose) {
        newStatus = CaptureStatus.tooClose;
      } else if (isTooFar) {
        newStatus = CaptureStatus.tooFar;
      } else if (!hasGoodLighting) {
        newStatus = CaptureStatus.badLighting;
      } else if (!stableOk) {
        newStatus = CaptureStatus.unstable;
      } else {
        newStatus = CaptureStatus.ready;
      }
    }

    setState(() {
      _status = newStatus;
      _detectedFace = face;
      _alignmentScore = alignmentScore;
    });

    final canStartTest = ref.read(scanCreditsProvider).when(
          data: (credits) => credits.credits > 0,
          loading: () => false,
          error: (_, __) => false,
        );

    if (canStartTest &&
        newStatus == CaptureStatus.ready &&
        _countdownTimer == null &&
        !_isCapturing) {
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
    _countdownBadFrames = 0;

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
    _countdownBadFrames = 0;
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

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

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

  void manualCapture() {
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

  Future<void> toggleFlash() async {
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
}

class _SmartCaptureScreenState extends ConsumerState<SmartCaptureScreen>
    with TickerProviderStateMixin, _SmartCaptureLogic<SmartCaptureScreen> {
  @override
  void initState() {
    super.initState();
    initSmartCapture(startCamera: true);
  }

  @override
  void dispose() {
    disposeSmartCapture();
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
        body: isInitialized
            ? AnimatedBuilder(
                animation: Listenable.merge([pulseController, scanLineController]),
                builder: (context, _) {
                  final isReady =
                      status == CaptureStatus.ready || status == CaptureStatus.countdown;
                  final pulseScale = isReady ? pulseAnimation.value : 1.0;

                  return SkinAnalysisView(
                    cameraPreview: buildCameraPreview(),
                    flashOn: flashOn,
                    onClose: () => context.pop(),
                    onToggleFlash: toggleFlash,
                    ovalStrokeColor: AppColors.textOffWhite.withValues(alpha: 0.35),
                    scanColor: AppColors.primary,
                    scanLineT: scanLineAnimation.value,
                    pulseScale: pulseScale,
                    showCountdown: status == CaptureStatus.countdown,
                    countdownValue: countdownValue,
                    hydrationPercent: hydrationPercent,
                    elasticityPercent: elasticityPercent,
                    texturePercent: texturePercent,
                    textureProgress: alignmentScore == 0.0 ? null : alignmentScore,
                    canStartTest: canStartTest,
                    isLoading: isCapturing,
                    onCtaPressed: (!canStartTest || isCapturing) ? null : manualCapture,
                    showResultCard: false,
                  );
                },
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
}

class EmbeddedSmartCaptureSection extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const EmbeddedSmartCaptureSection({super.key, this.onClose});

  @override
  ConsumerState<EmbeddedSmartCaptureSection> createState() =>
      EmbeddedSmartCaptureSectionState();
}

class EmbeddedSmartCaptureSectionState extends ConsumerState<EmbeddedSmartCaptureSection>
    with TickerProviderStateMixin, _SmartCaptureLogic<EmbeddedSmartCaptureSection> {
  @override
  void initState() {
    super.initState();
    // Camera will be started when this section becomes visible.
    initSmartCapture(startCamera: false);
    // Pause animations until visible to reduce work off-screen.
    pulseController.stop();
    scanLineController.stop();
  }

  Future<void> startIfNeeded() async {
    if (!pulseController.isAnimating) {
      pulseController.repeat(reverse: true);
    }
    if (!scanLineController.isAnimating) {
      scanLineController.repeat(reverse: true);
    }
    await ensureCameraRunning();
  }

  Future<void> pauseIfNeeded() async {
    await pauseCamera();
    if (pulseController.isAnimating) pulseController.stop();
    if (scanLineController.isAnimating) scanLineController.stop();
  }

  @override
  void dispose() {
    disposeSmartCapture();
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

    return RepaintBoundary(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: Listenable.merge([pulseController, scanLineController]),
          builder: (context, _) {
            final isReady =
                status == CaptureStatus.ready || status == CaptureStatus.countdown;
            final pulseScale = isReady ? pulseAnimation.value : 1.0;

            final preview =
                isInitialized ? buildCameraPreview() : const ColoredBox(color: Colors.black);

            return SkinAnalysisView(
              cameraPreview: preview,
              flashOn: flashOn,
              onClose: widget.onClose ?? () {},
              onToggleFlash: toggleFlash,
              ovalStrokeColor: AppColors.textOffWhite.withValues(alpha: 0.35),
              scanColor: AppColors.primary,
              scanLineT: scanLineAnimation.value,
              pulseScale: pulseScale,
              showCountdown: status == CaptureStatus.countdown,
              countdownValue: countdownValue,
              hydrationPercent: hydrationPercent,
              elasticityPercent: elasticityPercent,
              texturePercent: texturePercent,
              textureProgress: alignmentScore == 0.0 ? null : alignmentScore,
              canStartTest: canStartTest,
              isLoading: isCapturing,
              onCtaPressed: (!isInitialized || !canStartTest || isCapturing)
                  ? null
                  : manualCapture,
              showResultCard: false,
            );
          },
        ),
      ),
    );
  }
}

class SkinAnalysisView extends StatelessWidget {
  final Widget cameraPreview;
  final bool flashOn;
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;
  final Color ovalStrokeColor;
  final Color scanColor;
  final double scanLineT; // 0..1
  final double pulseScale;
  final bool showCountdown;
  final int countdownValue;
  final int? hydrationPercent;
  final int? elasticityPercent;
  final int? texturePercent;
  final double? textureProgress; // 0..1 (nullable -> fallback)
  final bool canStartTest;
  final bool isLoading;
  final VoidCallback? onCtaPressed;
  final bool showResultCard;

  const SkinAnalysisView({
    super.key,
    required this.cameraPreview,
    required this.flashOn,
    required this.onClose,
    required this.onToggleFlash,
    required this.ovalStrokeColor,
    required this.scanColor,
    required this.scanLineT,
    required this.pulseScale,
    required this.showCountdown,
    required this.countdownValue,
    required this.hydrationPercent,
    required this.elasticityPercent,
    required this.texturePercent,
    required this.textureProgress,
    required this.canStartTest,
    required this.isLoading,
    required this.onCtaPressed,
    this.showResultCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final h = media.size.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Camera preview fills screen
        cameraPreview,

        // 2) Dark vignette overlay
        const _WarmVignetteOverlay(),

        // 3) Top header
        Directionality(
          textDirection: TextDirection.ltr,
          child: _SkinScanHeader(
            flashOn: flashOn,
            onClose: onClose,
            onToggleFlash: onToggleFlash,
          ),
        ),

        // 4) Oval frame overlay + orange scan line (animated) + subtle pulse
        Positioned.fill(
          child: IgnorePointer(
            child: Transform.scale(
              scale: pulseScale,
              child: CustomPaint(
                painter: _FaceFramePainter(
                  strokeColor: ovalStrokeColor,
                  scanColor: scanColor,
                  scanLineT: scanLineT,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),

        // Countdown overlay (only when needed; kept from existing logic)
        if (showCountdown)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
                  ),
                  child: Text(
                    '$countdownValue',
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textOffWhite,
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 5) Center instruction text
        Positioned(
          left: 0,
          right: 0,
          top: h * 0.56,
          child: IgnorePointer(
            child: Column(
              children: [
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
              ],
            ),
          ),
        ),

        // Manual capture controls (capture mode)
        if (!showResultCard)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!canStartTest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Preview only — add scan credits to start.',
                          textDirection: TextDirection.ltr,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textOffWhite.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _ShutterButton(
                      onPressed: isLoading ? null : onCtaPressed,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (showResultCard)
          // 6) Bottom glass panel + privacy note at bottom (show only after results)
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GlassPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              Expanded(
                                child: _MetricColumn(
                                  icon: Icons.water_drop_outlined,
                                  label: 'Hydration',
                                  progress: ((hydrationPercent ?? 0) / 100)
                                      .clamp(0.0, 1.0),
                                  valueText: hydrationPercent == null
                                      ? 'Scanning…'
                                      : '${hydrationPercent!.clamp(0, 100)}%',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _MetricColumn(
                                  icon: Icons.autorenew_rounded,
                                  label: 'Elasticity',
                                  progress: ((elasticityPercent ?? 0) / 100)
                                      .clamp(0.0, 1.0),
                                  valueText: elasticityPercent == null
                                      ? 'Scanning…'
                                      : '${elasticityPercent!.clamp(0, 100)}%',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _MetricColumn(
                                  icon: Icons.grain_rounded,
                                  label: 'Texture',
                                  progress: (textureProgress ?? 0.55).clamp(0.0, 1.0),
                                  valueText: texturePercent == null
                                      ? 'Scanning…'
                                      : '${texturePercent!.clamp(0, 100)}%',
                                  isScanning: texturePercent == null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const _AssistantAvatar(
                                imageAsset: 'assets/images/placeholder.png'),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: _StatusPill(
                                text: 'Analyzing skin barrier…',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _PrimaryCtaButton(
                          label: 'Generate Routine',
                          onPressed: onCtaPressed,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _PrivacyNote(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          )
        else
          // During live scanning: only show the privacy note at the bottom.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: SafeArea(top: false, child: _PrivacyNote()),
          ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ShutterButton({required this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1.0 : 0.55,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                ),
        ),
      ),
    );
  }
}

class _SkinScanHeader extends StatelessWidget {
  final bool flashOn;
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;

  const _SkinScanHeader({
    required this.flashOn,
    required this.onClose,
    required this.onToggleFlash,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.close,
              onPressed: onClose,
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
              icon: flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              onPressed: onToggleFlash,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded,
            size: 16, color: AppColors.textOffWhite.withValues(alpha: 0.40)),
        const SizedBox(width: 8),
        Text(
          'Images are processed locally and never stored.',
          textDirection: TextDirection.ltr,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOffWhite.withValues(alpha: 0.40),
          ),
        ),
      ],
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
  final double scanLineT; // 0..1

  _FaceFramePainter({
    required this.strokeColor,
    required this.scanColor,
    required this.scanLineT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Required sizing relative to the screen.
    final ovalW = size.width * 0.78;
    final ovalH = size.height * 0.62;
    final ovalCenter = Offset(size.width / 2, size.height * 0.42); // slightly above center
    final rect = Rect.fromCenter(center: ovalCenter, width: ovalW, height: ovalH);

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawOval(rect, stroke);

    // Orange scan line (near top of oval) with subtle animated movement.
    final yTop = rect.top + (rect.height * 0.16);
    final yBottom = rect.top + (rect.height * 0.24);
    final y = ui.lerpDouble(yTop, yBottom, scanLineT.clamp(0.0, 1.0))!;
    final linePaint = Paint()
      ..color = scanColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = scanColor.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final left = rect.left + (rect.width * 0.06);
    final right = rect.right - (rect.width * 0.06);
    canvas.drawLine(Offset(left, y), Offset(right, y), glowPaint);
    canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
  }

  @override
  bool shouldRepaint(covariant _FaceFramePainter oldDelegate) {
    return strokeColor != oldDelegate.strokeColor ||
        scanColor != oldDelegate.scanColor ||
        scanLineT != oldDelegate.scanLineT;
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
