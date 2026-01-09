import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

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
  
  CaptureStatus _status = CaptureStatus.noFace;
  String _guidanceText = 'جاري تشغيل الكاميرا...';
  
  Face? _detectedFace;
  double _brightnessLevel = 0.5;
  bool _isStable = false;
  
  int _countdownValue = 3;
  Timer? _countdownTimer;
  
  late AnimationController _ringAnimationController;
  late Animation<double> _ringAnimation;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription? _accelerometerSubscription;
  List<double> _accelerometerHistory = [];
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
    _ringAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ringAnimationController, curve: Curves.easeInOut),
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
          _guidanceText = 'ضع وجهك داخل الإطار';
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
      
      final faceCenterX = boundingBox.center.dx / imageWidth;
      final faceCenterY = boundingBox.center.dy / imageHeight;
      final faceWidth = boundingBox.width / imageWidth;
      final faceHeight = boundingBox.height / imageHeight;
      
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
    String newGuidance;

    if (faces.isEmpty || face == null) {
      newStatus = CaptureStatus.noFace;
      newGuidance = 'لم يتم اكتشاف وجه';
    } else {
      final boundingBox = face.boundingBox;
      
      final faceCenterX = boundingBox.center.dx / imageWidth;
      final faceCenterY = boundingBox.center.dy / imageHeight;
      final faceWidth = boundingBox.width / imageWidth;
      final faceHeight = boundingBox.height / imageHeight;
      
      final isCentered = (faceCenterX - 0.5).abs() < 0.15 && (faceCenterY - 0.5).abs() < 0.15;
      final isTooClose = faceWidth > 0.7 || faceHeight > 0.8;
      final isTooFar = faceWidth < 0.25 || faceHeight < 0.3;
      final hasGoodLighting = _brightnessLevel > 0.2 && _brightnessLevel < 0.85;
      
      if (!isCentered) {
        newStatus = CaptureStatus.faceNotCentered;
        if (faceCenterX < 0.35) {
          newGuidance = 'حرك الهاتف لليمين';
        } else if (faceCenterX > 0.65) {
          newGuidance = 'حرك الهاتف لليسار';
        } else if (faceCenterY < 0.35) {
          newGuidance = 'ارفع الهاتف للأعلى';
        } else {
          newGuidance = 'أنزل الهاتف للأسفل';
        }
      } else if (isTooClose) {
        newStatus = CaptureStatus.tooClose;
        newGuidance = 'ابتعد قليلاً عن الكاميرا';
      } else if (isTooFar) {
        newStatus = CaptureStatus.tooFar;
        newGuidance = 'اقترب قليلاً من الكاميرا';
      } else if (!hasGoodLighting) {
        newStatus = CaptureStatus.badLighting;
        if (_brightnessLevel < 0.2) {
          newGuidance = 'الإضاءة ضعيفة، انتقل لمكان أفضل';
        } else {
          newGuidance = 'الإضاءة قوية جداً';
        }
      } else if (!_isStable) {
        newStatus = CaptureStatus.unstable;
        newGuidance = 'ثبّت الهاتف';
      } else {
        newStatus = CaptureStatus.ready;
        newGuidance = 'ممتاز! ابقِ ثابتاً';
      }
    }

    setState(() {
      _status = newStatus;
      _guidanceText = newGuidance;
      _detectedFace = face;
    });

    if (newStatus == CaptureStatus.ready && _countdownTimer == null && !_isCapturing) {
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
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _status = CaptureStatus.capturing;
      _guidanceText = 'جاري التقاط الصورة...';
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
    if (_status == CaptureStatus.ready || 
        _status == CaptureStatus.countdown ||
        _detectedFace != null) {
      _cancelCountdown();
      _captureImage();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case CaptureStatus.ready:
      case CaptureStatus.countdown:
        return AppColors.success;
      case CaptureStatus.noFace:
        return Colors.red;
      case CaptureStatus.badLighting:
        return Colors.orange;
      case CaptureStatus.faceNotCentered:
      case CaptureStatus.tooClose:
      case CaptureStatus.tooFar:
      case CaptureStatus.unstable:
        return Colors.amber;
      case CaptureStatus.capturing:
        return AppColors.primary;
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'فحص البشرة الذكي',
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                _buildCameraPreview(),
                _buildFaceGuideOverlay(),
                _buildGuidancePanel(),
                _buildBottomControls(),
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

  Widget _buildFaceGuideOverlay() {
    final statusColor = _getStatusColor();
    final isReady = _status == CaptureStatus.ready || _status == CaptureStatus.countdown;
    
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isReady ? _pulseAnimation.value : 1.0,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(300, 400),
              painter: FaceGuidePainter(
                color: statusColor,
                progress: _status == CaptureStatus.countdown
                    ? (3 - _countdownValue) / 3
                    : (_status == CaptureStatus.ready ? 0.0 : 0.0),
                isReady: isReady,
              ),
            ),
            if (_status == CaptureStatus.countdown)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_countdownValue',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidancePanel() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _getStatusColor().withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _guidanceText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case CaptureStatus.ready:
      case CaptureStatus.countdown:
        return Icons.check_circle;
      case CaptureStatus.noFace:
        return Icons.face_retouching_off;
      case CaptureStatus.badLighting:
        return Icons.lightbulb_outline;
      case CaptureStatus.faceNotCentered:
        return Icons.open_with;
      case CaptureStatus.tooClose:
      case CaptureStatus.tooFar:
        return Icons.straighten;
      case CaptureStatus.unstable:
        return Icons.vibration;
      case CaptureStatus.capturing:
        return Icons.camera_alt;
    }
  }

  Widget _buildBottomControls() {
    final canCapture = _detectedFace != null;
    
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIndicator('الوجه', _detectedFace != null, Icons.face),
              const SizedBox(width: 16),
              _buildStatusIndicator(
                'الإضاءة',
                _brightnessLevel > 0.2 && _brightnessLevel < 0.85,
                Icons.lightbulb_outline,
              ),
              const SizedBox(width: 16),
              _buildStatusIndicator('الثبات', _isStable, Icons.vibration),
            ],
          ),
          const SizedBox(height: 24),
          if (_isCapturing)
            const CircularProgressIndicator(color: AppColors.primary)
          else
            GestureDetector(
              onTap: canCapture ? _manualCapture : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canCapture ? Colors.white : Colors.grey[700],
                  border: Border.all(
                    color: canCapture ? _getStatusColor() : Colors.grey,
                    width: 4,
                  ),
                  boxShadow: canCapture
                      ? [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: canCapture ? _getStatusColor() : Colors.grey[500],
                  size: 36,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _status == CaptureStatus.countdown
                ? 'جاري العد التنازلي...'
                : (canCapture ? 'اضغط للالتقاط أو انتظر التقاط تلقائي' : 'ضع وجهك داخل الإطار'),
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isGood, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isGood
            ? AppColors.success.withValues(alpha: 0.8)
            : Colors.grey[800]!.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check : icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class FaceGuidePainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isReady;

  FaceGuidePainter({
    required this.color,
    required this.progress,
    required this.isReady,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width - 20,
      height: size.height - 20,
    );

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isReady ? 4 : 3;

    final path = Path()..addOval(rect);
    canvas.drawPath(path, borderPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        rect,
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(10, size.height * 0.3),
      Offset(10, size.height * 0.3 - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - 10, size.height * 0.3),
      Offset(size.width - 10, size.height * 0.3 - cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(10, size.height * 0.7),
      Offset(10, size.height * 0.7 + cornerLength),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - 10, size.height * 0.7),
      Offset(size.width - 10, size.height * 0.7 + cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceGuidePainter oldDelegate) {
    return color != oldDelegate.color ||
        progress != oldDelegate.progress ||
        isReady != oldDelegate.isReady;
  }
}
