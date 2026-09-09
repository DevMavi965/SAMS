import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/services/db_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum LivenessChallenge {
  turnLeft,
  turnRight,
  blink,
  smile,
}

enum LivenessState {
  idle,
  initializing,
  detectingFace,
  performingChallenge,
  completed,
  failed,
}

class FaceAttendanceScreenChecIn extends StatefulWidget {
  final Student student;
  final LectureModel lecture;
  const FaceAttendanceScreenChecIn({super.key, required this.student, required this.lecture});

  @override
  State<FaceAttendanceScreenChecIn> createState() =>
      _FaceAttendanceScreenChecInState();
}

class _FaceAttendanceScreenChecInState extends State<FaceAttendanceScreenChecIn> {
  // ============================================================
  // FIRESTORE
  // ============================================================

  final CollectionReference<Map<String, dynamic>> _studentsRef =
  FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("embeddings");

  // ============================================================
  // CAMERA
  // ============================================================

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _cameraReady = false;
  bool _isProcessingFrame = false;

  // Last live camera frame.
  CameraImage? _lastCameraImage;

  // ============================================================
  // ML KIT
  // ============================================================

  late FaceDetector _faceDetector;

  // ============================================================
  // FACENET
  // ============================================================

  Interpreter? _interpreter;
  bool _modelReady = false;

  // ============================================================
  // LIVENESS
  // ============================================================

  LivenessState _livenessState = LivenessState.idle;

  final Random _random = Random();

  List<LivenessChallenge> _challenges = [];

  int _currentChallengeIndex = 0;

  int _validFrames = 0;

  int? _trackingId;

  DateTime? _challengeStartedAt;

  DateTime? _sessionStartedAt;

  Timer? _timeoutTimer;

  bool _livenessPassed = false;

  // Used to make head-turn detection require movement
  // from a neutral position rather than simply starting
  // already turned.
  bool _neutralPositionSeen = false;

  // Blink state.
  bool _blinkWasOpen = false;
  bool _blinkWasClosed = false;

  // ============================================================
  // VERIFICATION
  // ============================================================

  bool _isVerifying = false;

  String _status = "Press Start Attendance";

  double _matchScore = 0.0;

  // ============================================================
  // SETTINGS
  // ============================================================

  static const double _matchThreshold = 0.72;

  static const int _requiredValidFrames = 4;

  static const int _challengeTimeoutSeconds = 8;

  static const int _sessionTimeoutSeconds = 30;

  // Head rotation threshold.
  static const double _headTurnThreshold = 22.0;

  // Blink thresholds.
  static const double _eyeOpenThreshold = 0.65;
  static const double _eyeClosedThreshold = 0.25;

  // Smile threshold.
  static const double _smileThreshold = 0.70;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );

    _loadFaceNet();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();

    if (_cameraController != null) {
      _cameraController!.dispose();
    }

    _faceDetector.close();

    _interpreter?.close();

    super.dispose();
  }

  // ============================================================
  // LOAD FACENET
  // ============================================================

  Future<void> _loadFaceNet() async {
    try {
      final options = InterpreterOptions()..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/facenet_512.tflite',
        options: options,
      );

      if (!mounted) return;

      setState(() {
        _modelReady = true;
      });
    } catch (e) {
      debugPrint("FaceNet loading error: $e");

      if (!mounted) return;

      _showSnack(
        "Failed to load FaceNet model: $e",
      );
    }
  }

  // ============================================================
  // START ATTENDANCE
  // ============================================================

  Future<void> _startAttendance() async {
    if (_isVerifying) return;

    if (!_modelReady) {
      _showSnack("Face model is still loading.");
      return;
    }

    try {
      await _stopCamera();

      setState(() {
        _livenessState = LivenessState.initializing;
        _livenessPassed = false;
        _status = "Starting camera...";
        _currentChallengeIndex = 0;
        _validFrames = 0;
        _trackingId = null;
        _neutralPositionSeen = false;
        _blinkWasOpen = false;
        _blinkWasClosed = false;
        _matchScore = 0.0;
      });

      await _initializeCamera();

      _createRandomChallenges();

      _sessionStartedAt = DateTime.now();

      _startTimeoutTimer();

      if (!mounted) return;

      setState(() {
        _livenessState = LivenessState.detectingFace;
        _status = "Look directly at the camera";
      });

      await _startImageStream();
    } catch (e) {
      debugPrint("Attendance camera error: $e");

      await _stopCamera();

      if (!mounted) return;

      setState(() {
        _livenessState = LivenessState.failed;
        _status = "Camera initialization failed";
      });

      _showSnack("Unable to start camera: $e");
    }
  }

  // ============================================================
  // CAMERA INITIALIZATION
  // ============================================================

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      throw Exception("No camera available.");
    }

    CameraDescription selectedCamera = _cameras.first;

    // Prefer front camera.
    for (final camera in _cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        selectedCamera = camera;
        break;
      }
    }

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,

      // ML Kit recommends NV21 on Android.
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() {
      _cameraReady = true;
    });
  }

  // ============================================================
  // START IMAGE STREAM
  // ============================================================

  Future<void> _startImageStream() async {
    if (_cameraController == null) return;

    if (!_cameraController!.value.isInitialized) {
      return;
    }

    await _cameraController!.startImageStream(
          (CameraImage image) {
        _processCameraFrame(image);
      },
    );
  }

  // ============================================================
  // CAMERA FRAME PROCESSING
  // ============================================================

  Future<void> _processCameraFrame(
      CameraImage image,
      ) async {
    if (_isProcessingFrame) return;

    if (_livenessPassed) return;

    if (_livenessState == LivenessState.failed) return;

    if (_livenessState == LivenessState.completed) return;

    _isProcessingFrame = true;

    _lastCameraImage = image;

    try {
      final inputImage = _inputImageFromCameraImage(image);

      if (inputImage == null) {
        return;
      }
//ok
      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      await _handleDetectedFaces(
        faces,
        image,
      );
    } catch (e) {
      debugPrint("Frame processing error: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  // ============================================================
  // CAMERA IMAGE -> ML KIT INPUT IMAGE
  // ============================================================

  InputImage? _inputImageFromCameraImage(
      CameraImage image,
      ) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;

    InputImageRotation? rotation;

    if (Platform.isAndroid) {
      final sensorOrientation = camera.sensorOrientation;

      var rotationCompensation = 0;

      switch (
      _cameraController!.value.deviceOrientation) {
        case DeviceOrientation.portraitUp:
          rotationCompensation = 0;
          break;

        case DeviceOrientation.landscapeLeft:
          rotationCompensation = 90;
          break;

        case DeviceOrientation.portraitDown:
          rotationCompensation = 180;
          break;

        case DeviceOrientation.landscapeRight:
          rotationCompensation = 270;
          break;
      }

      if (camera.lensDirection ==
          CameraLensDirection.front) {
        rotationCompensation =
            (sensorOrientation +
                rotationCompensation) %
                360;
      } else {
        rotationCompensation =
            (sensorOrientation -
                rotationCompensation +
                360) %
                360;
      }

      rotation =
          InputImageRotationValue.fromRawValue(
            rotationCompensation,
          );
    } else {
      rotation =
          InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          );
    }

    if (rotation == null) return null;

    final format =
    InputImageFormatValue.fromRawValue(
      image.format.raw,
    );

    if (format == null) return null;

    // Android should be NV21.
    if (Platform.isAndroid &&
        format != InputImageFormat.nv21) {
      debugPrint(
        "Unsupported Android camera format: $format",
      );
      return null;
    }

    // iOS should be BGRA8888.
    if (Platform.isIOS &&
        format != InputImageFormat.bgra8888) {
      return null;
    }

    if (image.planes.length != 1) {
      debugPrint(
        "Expected one image plane but got "
            "${image.planes.length}",
      );
      return null;
    }

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ============================================================
  // FACE PROCESSING
  // ============================================================

  Future<void> _handleDetectedFaces(
      List<Face> faces,
      CameraImage image,
      ) async {
    if (!mounted) return;

    // ----------------------------------------------------------
    // NO FACE
    // ----------------------------------------------------------

    if (faces.isEmpty) {
      _validFrames = 0;
      _trackingId = null;
      _neutralPositionSeen = false;

      if (_livenessState !=
          LivenessState.detectingFace) {
        setState(() {
          _status = "Face lost. Look at the camera.";
        });
      } else {
        setState(() {
          _status = "Look directly at the camera";
        });
      }

      return;
    }

    // ----------------------------------------------------------
    // MULTIPLE FACES
    // ----------------------------------------------------------

    if (faces.length > 1) {
      _validFrames = 0;

      setState(() {
        _status =
        "Multiple faces detected. Only one person allowed.";
      });

      return;
    }

    final face = faces.first;

    // ----------------------------------------------------------
    // TRACKING ID
    // ----------------------------------------------------------

    final trackingId = face.trackingId;

    if (_trackingId != null &&
        trackingId != null &&
        _trackingId != trackingId) {
      // Face changed.
      _resetLivenessProgress();

      setState(() {
        _status = "Face changed. Restarting liveness.";
      });

      return;
    }

    if (trackingId != null) {
      _trackingId = trackingId;
    }

    // ----------------------------------------------------------
    // FACE QUALITY / POSITION
    // ----------------------------------------------------------

    final qualityMessage =
    _validateFacePosition(
      face,
      image,
    );

    if (qualityMessage != null) {
      _validFrames = 0;

      setState(() {
        _status = qualityMessage;
      });

      return;
    }

    // ----------------------------------------------------------
    // DETECTING INITIAL FACE
    // ----------------------------------------------------------

    if (_livenessState ==
        LivenessState.detectingFace) {
      _validFrames++;

      if (_validFrames >=
          _requiredValidFrames) {
        _validFrames = 0;

        _beginFirstChallenge();
      }

      return;
    }

    // ----------------------------------------------------------
    // CHALLENGE
    // ----------------------------------------------------------

    if (_livenessState ==
        LivenessState.performingChallenge) {
      await _processCurrentChallenge(face);
    }
  }

  // ============================================================
  // FACE POSITION VALIDATION
  // ============================================================

  String? _validateFacePosition(
      Face face,
      CameraImage image,
      ) {
    final box = face.boundingBox;

    final imageArea =
        image.width * image.height;

    if (imageArea <= 0) {
      return "Camera image invalid";
    }

    final faceArea =
        box.width * box.height;

    final ratio =
        faceArea / imageArea;

    if (ratio < 0.04) {
      return "Move closer to the camera";
    }

    if (ratio > 0.65) {
      return "Move farther from the camera";
    }

    final centerX = box.center.dx;
    final centerY = box.center.dy;

    final imageCenterX =
        image.width / 2;

    final imageCenterY =
        image.height / 2;

    final toleranceX =
        image.width * 0.30;

    final toleranceY =
        image.height * 0.35;

    if ((centerX - imageCenterX).abs() >
        toleranceX) {
      return "Move your face to the center";
    }

    if ((centerY - imageCenterY).abs() >
        toleranceY) {
      return "Center your face";
    }

    final rotZ =
        face.headEulerAngleZ ?? 0;

    if (rotZ.abs() > 25) {
      return "Keep your head straight";
    }

    return null;
  }

  // ============================================================
  // CREATE RANDOM CHALLENGES
  // ============================================================

  void _createRandomChallenges() {
    final all = [
      LivenessChallenge.turnLeft,
      LivenessChallenge.turnRight,
      LivenessChallenge.blink,
      LivenessChallenge.smile,
    ];

    all.shuffle(_random);

    _challenges = all.take(2).toList();

    debugPrint(
      "Liveness challenges: $_challenges",
    );
  }

  // ============================================================
  // START FIRST CHALLENGE
  // ============================================================

  void _beginFirstChallenge() {
    if (!mounted) return;

    _currentChallengeIndex = 0;

    _startCurrentChallenge();
  }

  // ============================================================
  // START CURRENT CHALLENGE
  // ============================================================

  void _startCurrentChallenge() {
    _validFrames = 0;

    _neutralPositionSeen = false;

    _blinkWasOpen = false;
    _blinkWasClosed = false;

    _challengeStartedAt =
        DateTime.now();

    setState(() {
      _livenessState =
          LivenessState.performingChallenge;

      _status =
          _challengeInstruction(
            _challenges[_currentChallengeIndex],
          );
    });
  }

  // ============================================================
  // PROCESS CURRENT CHALLENGE
  // ============================================================

  Future<void> _processCurrentChallenge(
      Face face,
      ) async {
    if (_challengeStartedAt == null) {
      _challengeStartedAt =
          DateTime.now();
    }

    final elapsed =
        DateTime.now()
            .difference(
          _challengeStartedAt!,
        )
            .inSeconds;

    if (elapsed >
        _challengeTimeoutSeconds) {
      _failLiveness(
        "Challenge timed out. Try again.",
      );

      return;
    }

    final challenge =
    _challenges[_currentChallengeIndex];

    bool passed = false;

    switch (challenge) {
      case LivenessChallenge.turnLeft:
        passed = _detectTurnLeft(face);
        break;

      case LivenessChallenge.turnRight:
        passed = _detectTurnRight(face);
        break;

      case LivenessChallenge.blink:
        passed = _detectBlink(face);
        break;

      case LivenessChallenge.smile:
        passed = _detectSmile(face);
        break;
    }

    if (passed) {
      _validFrames++;

      if (_validFrames >=
          _requiredValidFrames) {
        await _challengePassed();
      }
    } else {
      // Do not immediately reset everything.
      // Small temporary detection failures are tolerated.
      if (challenge ==
          LivenessChallenge.blink &&
          !_blinkWasClosed) {
        // keep waiting
      }
    }
  }

  // ============================================================
  // TURN LEFT
  // ============================================================

  bool _detectTurnLeft(
      Face face,
      ) {
    final y =
        face.headEulerAngleY;

    if (y == null) return false;

    // First require reasonably neutral position.
    if (!_neutralPositionSeen) {
      if (y.abs() < 10) {
        _neutralPositionSeen = true;

        if (mounted) {
          setState(() {
            _status =
            "Good. Now turn your head LEFT";
          });
        }
      }

      return false;
    }

    return y > _headTurnThreshold;
  }

  // ============================================================
  // TURN RIGHT
  // ============================================================

  bool _detectTurnRight(
      Face face,
      ) {
    final y =
        face.headEulerAngleY;

    if (y == null) return false;

    if (!_neutralPositionSeen) {
      if (y.abs() < 10) {
        _neutralPositionSeen = true;

        if (mounted) {
          setState(() {
            _status =
            "Good. Now turn your head RIGHT";
          });
        }
      }

      return false;
    }

    return y < -_headTurnThreshold;
  }

  // ============================================================
  // BLINK
  // ============================================================

  bool _detectBlink(
      Face face,
      ) {
    final left =
        face.leftEyeOpenProbability;

    final right =
        face.rightEyeOpenProbability;

    if (left == null || right == null) {
      return false;
    }

    final bothOpen =
        left > _eyeOpenThreshold &&
            right > _eyeOpenThreshold;

    final bothClosed =
        left < _eyeClosedThreshold &&
            right < _eyeClosedThreshold;

    // OPEN → CLOSED → OPEN

    if (bothOpen &&
        !_blinkWasClosed) {
      _blinkWasOpen = true;
    }

    if (_blinkWasOpen &&
        bothClosed) {
      _blinkWasClosed = true;

      if (mounted) {
        setState(() {
          _status =
          "Eyes closed — now open them";
        });
      }
    }

    if (_blinkWasOpen &&
        _blinkWasClosed &&
        bothOpen) {
      return true;
    }

    return false;
  }

  // ============================================================
  // SMILE
  // ============================================================

  bool _detectSmile(
      Face face,
      ) {
    final smile =
        face.smilingProbability;

    if (smile == null) {
      return false;
    }

    return smile >= _smileThreshold;
  }

  // ============================================================
  // CHALLENGE PASSED
  // ============================================================

  Future<void> _challengePassed() async {
    if (!mounted) return;

    _validFrames = 0;

    final completed =
        _currentChallengeIndex + 1;

    if (completed >=
        _challenges.length) {
      await _completeLiveness();

      return;
    }

    setState(() {
      _status =
      "Challenge passed ✓";
    });

    await Future.delayed(
      const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    _currentChallengeIndex++;

    _startCurrentChallenge();
  }

  // ============================================================
  // COMPLETE LIVENESS
  // ============================================================

  Future<void> _completeLiveness() async {
    if (_livenessPassed) return;

    _livenessPassed = true;

    if (mounted) {
      setState(() {
        _livenessState =
            LivenessState.completed;

        _status =
        "Liveness verified ✓";
      });
    }

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    await _performFaceVerification();
  }

  // ============================================================
  // FACE VERIFICATION
  // ============================================================

  Future<void> _performFaceVerification() async {
    if (_isVerifying) return;

    _isVerifying = true;

    if (mounted) {
      setState(() {
        _status =
        "Verifying your identity...";
      });
    }

    try {
      await _stopImageStream();

      final image =
          _lastCameraImage;

      if (image == null) {
        throw Exception(
          "No live camera frame available.",
        );
      }

      final faces =
      await _processSingleFrame(image);

      if (faces.length != 1) {
        throw Exception(
          "Live face could not be captured.",
        );
      }

      final face = faces.first;

      final embedding =
      await _getEmbeddingFromCameraFrame(
        image,
        face,
      );

      if (embedding == null) {
        throw Exception(
          "Could not create face embedding.",
        );
      }

      final result =
      await _findMatchingStudent(
        embedding,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _status =
          "Identity verification failed";
        });

        _showResultDialog(
          success: false,
          title: "Verification Failed",
          message:
          "No matching student found.\n\n"
              "Face similarity: "
              "${(_matchScore * 100).toStringAsFixed(1)}%",
        );

        return;
      }

      final name =
          result['name'] as String? ??
              "Unknown";

      final roll =
          result['rollNumber'] as String? ??
              "";

      setState(() {
        _status =
        "Identity verified ✓";
      });

      // IMPORTANT:
      // Call your existing attendance function here.
      //
      // Example:
      //
      // await studentCheckIn(
      //   context,
      //   lectureModel,
      //   roll,
      //   "face",
      // );

      _showResultDialog(
        success: true,
        title: "Attendance Verified ✓",
        message:
        "Student: ${widget.student.name}\n"
            "Roll Number: $roll\n\n"
            "Face similarity: "
            "${(_matchScore * 100).toStringAsFixed(1)}%\n\n"
            "Liveness: PASSED",
      );
    } catch (e) {
      debugPrint(
        "Face verification error: $e",
      );

      if (mounted) {
        setState(() {
          _status =
          "Verification failed";
        });

        _showSnack(
          "Verification failed: $e",
        );
      }
    } finally {
      _isVerifying = false;
    }
  }

  // ============================================================
  // PROCESS ONE FINAL FRAME
  // ============================================================

  Future<List<Face>> _processSingleFrame(
      CameraImage image,
      ) async {
    final inputImage =
    _inputImageFromCameraImage(
      image,
    );

    if (inputImage == null) {
      return [];
    }

    return await _faceDetector
        .processImage(inputImage);
  }

  // ============================================================
  // FIND MATCHING STUDENT
  // ============================================================

  // ============================================================
  // FIND MATCHING STUDENT (Specific Document Only)
  // ============================================================

  Future<Map<String, dynamic>?> _findMatchingStudent(
      List<double> embedding,
      ) async {
    // 1. Fetch only the specific student document using their ID
    final studentDoc = await _studentsRef.doc(widget.student.id).get();

    if (!studentDoc.exists) {
      debugPrint("Student document not found for ID: ${widget.student.id}");
      return null;
    }

    final data = studentDoc.data();
    if (data == null) {
      return null;
    }

    final rawEmbedding = data['embedding'];

    if (rawEmbedding is! List) {
      _matchScore = 0.0;
      return null;
    }

    final storedEmbedding = rawEmbedding
        .whereType<num>()
        .map(
          (e) => e.toDouble(),
    )
        .toList();

    if (storedEmbedding.length != embedding.length) {
      _matchScore = 0.0;
      return null;
    }

    // 2. Compute similarity specifically for this student
    final similarity = _cosineSimilarity(
      embedding,
      storedEmbedding,
    );

    _matchScore = similarity;

    // 3. Check if similarity meets your match threshold
    if (similarity >= _matchThreshold) {
      return data;
    }

    return null;
  }

  // ============================================================
  // FACENET EMBEDDING
  // ============================================================

  Future<List<double>?> _getEmbeddingFromCameraFrame(
      CameraImage cameraImage,
      Face face,
      ) async {
    if (_interpreter == null) {
      return null;
    }

    /*
     * The camera stream is NV21 on Android.
     *
     * Convert the current live frame to a normal image.
     *
     * For the most reliable FaceNet preprocessing,
     * we capture a JPEG immediately after liveness and
     * use that file for FaceNet.
     *
     * Therefore this function temporarily captures a still
     * image from the camera.
     */

    if (_cameraController == null ||
        !_cameraController!
            .value
            .isInitialized) {
      return null;
    }

    final XFile captured =
    await _cameraController!
        .takePicture();

    final file =
    File(captured.path);

    final rawImage =
    img.decodeImage(
      await file.readAsBytes(),
    );

    if (rawImage == null) {
      return null;
    }

    final embedding =
    await _getEmbeddingFromImage(
      file,
      rawImage,
      face,
    );

    try {
      await file.delete();
    } catch (_) {}

    return embedding;
  }

  // ============================================================
  // FACENET FROM IMAGE
  // ============================================================

  Future<List<double>?> _getEmbeddingFromImage(
      File imageFile,
      img.Image rawImage,
      Face face,
      ) async {
    if (_interpreter == null) {
      return null;
    }

    final rect =
        face.boundingBox;

    final x =
    rect.left
        .toInt()
        .clamp(
      0,
      rawImage.width - 1,
    );

    final y =
    rect.top
        .toInt()
        .clamp(
      0,
      rawImage.height - 1,
    );

    final maxWidth =
        rawImage.width - x;

    final maxHeight =
        rawImage.height - y;

    final w =
    rect.width
        .toInt()
        .clamp(
      1,
      maxWidth,
    );

    final h =
    rect.height
        .toInt()
        .clamp(
      1,
      maxHeight,
    );

    final croppedFace =
    img.copyCrop(
      rawImage,
      x: x,
      y: y,
      width: w,
      height: h,
    );

    final resizedFace =
    img.copyResize(
      croppedFace,
      width: 160,
      height: 160,
    );

    final input =
    List.generate(
      1,
          (_) => List.generate(
        160,
            (yy) => List.generate(
          160,
              (xx) {
            final pixel =
            resizedFace.getPixel(
              xx,
              yy,
            );

            return [
              (pixel.r - 127.5) /
                  127.5,
              (pixel.g - 127.5) /
                  127.5,
              (pixel.b - 127.5) /
                  127.5,
            ];
          },
        ),
      ),
    );

    final output =
    List.filled(
      1 * 512,
      0.0,
    ).reshape([
      1,
      512,
    ]);

    _interpreter!.run(
      input,
      output,
    );

    return List<double>.from(
      output[0],
    );
  }

  // ============================================================
  // COSINE SIMILARITY
  // ============================================================

  double _cosineSimilarity(
      List<double> v1,
      List<double> v2,
      ) {
    if (v1.length != v2.length ||
        v1.isEmpty) {
      return 0.0;
    }

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0;
    i < v1.length;
    i++) {
      dot +=
          v1[i] * v2[i];

      normA +=
          v1[i] * v1[i];

      normB +=
          v2[i] * v2[i];
    }

    if (normA == 0 ||
        normB == 0) {
      return 0.0;
    }

    return dot /
        (sqrt(normA) *
            sqrt(normB));
  }

  // ============================================================
  // CHALLENGE TEXT
  // ============================================================

  String _challengeInstruction(
      LivenessChallenge challenge,
      ) {
    switch (challenge) {
      case LivenessChallenge.turnLeft:
        return "Turn your head LEFT";

      case LivenessChallenge.turnRight:
        return "Turn your head RIGHT";

      case LivenessChallenge.blink:
        return "Blink your eyes";

      case LivenessChallenge.smile:
        return "Smile";
    }
  }

  // ============================================================
  // RESET LIVENESS
  // ============================================================

  void _resetLivenessProgress() {
    _validFrames = 0;

    _neutralPositionSeen = false;

    _blinkWasOpen = false;
    _blinkWasClosed = false;
  }

  // ============================================================
  // FAIL LIVENESS
  // ============================================================

  void _failLiveness(
      String message,
      ) {
    if (_livenessPassed) return;

    _timeoutTimer?.cancel();

    _stopCamera();

    if (!mounted) return;

    setState(() {
      _livenessState =
          LivenessState.failed;

      _status = message;
    });

    _showSnack(message);
  }

  // ============================================================
  // TIMEOUT
  // ============================================================

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();

    _timeoutTimer =
        Timer.periodic(
          const Duration(
            milliseconds: 500,
          ),
              (_) {
            if (_sessionStartedAt ==
                null) {
              return;
            }

            final elapsed =
                DateTime.now()
                    .difference(
                  _sessionStartedAt!,
                )
                    .inSeconds;

            if (elapsed >
                _sessionTimeoutSeconds &&
                !_livenessPassed &&
                mounted) {
              _failLiveness(
                "Liveness session timed out.",
              );
            }
          },
        );
  }

  // ============================================================
  // STOP IMAGE STREAM
  // ============================================================

  Future<void> _stopImageStream() async {
    try {
      if (_cameraController != null &&
          _cameraController!
              .value
              .isStreamingImages) {
        await _cameraController!
            .stopImageStream();
      }
    } catch (e) {
      debugPrint(
        "stopImageStream error: $e",
      );
    }
  }

  // ============================================================
  // STOP CAMERA
  // ============================================================

  Future<void> _stopCamera() async {
    _timeoutTimer?.cancel();

    try {
      await _stopImageStream();
    } catch (_) {}

    try {
      await _cameraController?.dispose();
    } catch (_) {}

    _cameraController = null;

    if (mounted) {
      setState(() {
        _cameraReady = false;
      });
    }
  }

  // ============================================================
  // RESULT DIALOG
  // ============================================================

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle
                    : Icons.cancel,
                color: success
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async{
                if(success) {
                  await Provider.of<DbService>(context, listen: false)
                      .studentCheckIn(
                    context, widget.lecture, widget.student.id!,"facial");
                  Navigator.pop(context);
                  _resetScreen();
                }
                Navigator.pop(context);
                _resetScreen();
              },
              child:  Text(success?"confirm attendance":"try again"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RESET SCREEN
  // ============================================================

  Future<void> _resetScreen() async {
    await _stopCamera();

    if (!mounted) return;

    setState(() {
      _livenessState =
          LivenessState.idle;

      _livenessPassed = false;

      _status =
      "Press Start Attendance";

      _currentChallengeIndex = 0;

      _validFrames = 0;

      _trackingId = null;

      _matchScore = 0.0;
    });
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          "Face Attendance",
          style: TextStyle(
            color: Theme.of(context).primaryColor,fontSize: 18,fontWeight: FontWeight.w500
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // CAMERA
            // --------------------------------------------------

            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: _cameraReady &&
                    _cameraController !=
                        null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(
                      _cameraController!,
                    ),

                    // Face guide.
                    Center(
                      child: Container(
                        width: 250,
                        height: 330,
                        decoration:
                        BoxDecoration(
                          border: Border.all(
                            color:
                            _livenessPassed
                                ? Colors.green
                                : Colors.white,
                            width: 3,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            140,
                          ),
                        ),
                      ),
                    ),

                    // Status.
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 20,
                      child: Container(
                        padding:
                        const EdgeInsets
                            .all(
                          14,
                        ),
                        decoration:
                        BoxDecoration(
                          color: Colors.black
                              .withOpacity(
                            0.65,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                        child: Text(
                          _status,
                          textAlign:
                          TextAlign
                              .center,
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),
                    ),

                    // Challenge progress.
                    if (_livenessState ==
                        LivenessState
                            .performingChallenge)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Text(
                          "Challenge "
                              "${_currentChallengeIndex + 1}"
                              " of "
                              "${_challenges.length}",
                          textAlign:
                          TextAlign
                              .center,
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontSize: 16,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),
                  ],
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(
                        Icons
                            .face_retouching_natural,
                        size: 90,
                        color: Colors.grey
                            .shade400,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        _status,
                        style:
                        const TextStyle(
                          fontSize: 18,
                        ),
                        textAlign:
                        TextAlign
                            .center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // BOTTOM PANEL
            // --------------------------------------------------
//Alert
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_modelReady)
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Icon(
                          Icons
                              .verified_user,
                          size: 18,
                          color: _livenessPassed
                              ? Colors.green
                              : Colors.blue,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          _livenessPassed
                              ? "Liveness Passed"
                              : "Liveness Protection Active",
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight.bold,
                            color:
                            _livenessPassed
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(
                    height: 14,
                  ),

                  if (!_cameraReady ||
                      _livenessState ==
                          LivenessState
                              .failed)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child:
                      ElevatedButton.icon(
                        onPressed:
                        _startAttendance,
                        icon:  Icon(
                          Icons.camera_alt,color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          "Start Attendance",
                          style:
                          TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  if (_cameraReady &&
                      !_livenessPassed &&
                      _livenessState !=
                          LivenessState.failed)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child:
                      OutlinedButton.icon(
                        onPressed:
                        _resetScreen,
                        icon: const Icon(
                          Icons.close,
                        ),
                        label:  Text(
                          "Cancel",style: TextStyle(color: Theme.of(context).primaryColor,),
                        ),
                      ),
                    ),

                  if (!_modelReady)
                    const Padding(
                      padding:
                      EdgeInsets.only(
                        top: 10,
                      ),
                      child:
                      LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }//findM
}