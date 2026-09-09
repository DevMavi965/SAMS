import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../models/student_model.dart';

/// Single-file student registration + face-verification screen.
/// - Register: capture a face photo, generate a 512-dim FaceNet embedding,
///   save {name, rollNumber, embedding} to Firestore's "students" collection.
/// - Verify: capture a face photo, compare its embedding against every
///   registered student via cosine similarity, and report the best match.
/// - Registration can only be updated once every 7 days per student.
class StdFaceReg extends StatefulWidget {
  final Student student;
  const StdFaceReg({super.key, required this.student});

  @override
  State<StdFaceReg> createState() => _StdFaceRegState();
}

class _StdFaceRegState extends State<StdFaceReg> {
  // --- Firestore ---
  final CollectionReference<Map<String, dynamic>> _studentsRef =
  FirebaseFirestore.instance
      .collection("SAMS")
      .doc("SAMS_DB")
      .collection("embeddings");

  // --- ML Kit / TFLite ---
  FaceDetector? _faceDetector;
  Interpreter? _interpreter;

  // --- UI / capture state ---
  File? pickedImg;
  Size? imgSize;
  List<Face> faces = [];
  List<double>? extractedEmbedding;

  bool isModelReady = false;
  bool isScanning = false;
  bool isSaving = false;
  bool isVerifying = false;

  // --- 7-day re-registration lock state ---
  bool _checkingRegistration = true;
  bool _alreadyRegistered = false;
  int _daysUntilNextRegistration = 0;

  static const double _matchThreshold = 0.72;
  static const int _reRegisterCooldownDays = 7;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _loadModel();
    _checkRegistrationStatus();
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/facenet_512.tflite',
        options: options,
      );
      if (mounted) setState(() => isModelReady = true);
    } catch (e) {
      debugPrint("Error loading FaceNet model: $e");
    }
  }

  /// Checks whether this student registered facial recognition within the
  /// last [_reRegisterCooldownDays] days. If so, blocks re-registration
  /// until the cooldown expires.
  Future<void> _checkRegistrationStatus() async {
    try {
      final snapshot = await _studentsRef.doc(widget.student.id).get();
      final data = snapshot.data();

      final embedding = data?['embedding'] as List<dynamic>?;
      final createdAt = (data?['created_at'] as Timestamp?)?.toDate();

      if (embedding != null && createdAt != null) {
        final daysSince = DateTime.now().difference(createdAt).inDays;
        if (daysSince < _reRegisterCooldownDays) {
          if (mounted) {
            setState(() {
              _alreadyRegistered = true;
              _daysUntilNextRegistration =
                  _reRegisterCooldownDays - daysSince;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking registration status: $e");
    } finally {
      if (mounted) setState(() => _checkingRegistration = false);
    }
  }

  @override
  void dispose() {
    _faceDetector?.close();
    _interpreter?.close();

    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Image capture + embedding extraction
  // ---------------------------------------------------------------------

  Future<void> pickImage(ImageSource source) async {
    final result = await ImagePicker().pickImage(source: source);
    if (result == null) return;

    setState(() {
      faces.clear();
      pickedImg = File(result.path);
      imgSize = null;
      extractedEmbedding = null;
      isScanning = true;
    });

    await _decodeImageSize();
    await _detectFaceAndExtractEmbedding();

    if (mounted) setState(() => isScanning = false);
  }

  Future<void> _decodeImageSize() async {
    if (pickedImg == null) return;
    final bytes = await pickedImg!.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() {
      imgSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    });
  }

  Future<void> _detectFaceAndExtractEmbedding() async {
    if (pickedImg == null || _faceDetector == null) return;

    final inputImage = InputImage.fromFilePath(pickedImg!.path);
    final detectedFaces = await _faceDetector!.processImage(inputImage);

    if (!mounted) return;

    if (detectedFaces.isEmpty) {
      setState(() {
        faces = [];
        extractedEmbedding = null;
      });
      _showSnack("No face detected — try another photo.");
      return;
    }

    if (detectedFaces.length > 1) {
      _showSnack("Multiple faces detected — using the first one.");
    }

    final embedding = await _getEmbedding(pickedImg!, detectedFaces.first);

    if (!mounted) return;
    setState(() {
      faces = detectedFaces;
      extractedEmbedding = embedding;
    });
  }

  /// Crops the detected face out of [imageFile], resizes to 160x160,
  /// normalizes pixels, and runs the FaceNet TFLite model to get a
  /// 512-dim embedding.
  Future<List<double>?> _getEmbedding(File imageFile, Face face) async {
    if (_interpreter == null) return null;

    final rawImage = img.decodeImage(await imageFile.readAsBytes());
    if (rawImage == null) return null;
    final rect = face.boundingBox;
    final x = rect.left.toInt().clamp(0, rawImage.width);
    final y = rect.top.toInt().clamp(0, rawImage.height);
    final w = rect.width.toInt().clamp(1, rawImage.width - x);
    final h = rect.height.toInt().clamp(1, rawImage.height - y);

    final croppedFace = img.copyCrop(rawImage, x: x, y: y, width: w, height: h);
    final resizedFace = img.copyResize(croppedFace, width: 160, height: 160);

    final input = List.generate(
      1,
          (_) => List.generate(
        160,
            (yy) => List.generate(160, (xx) {
          final pixel = resizedFace.getPixel(xx, yy);
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5,
          ];
        }),
      ),
    );
    final output = List.filled(1 * 512, 0.0).reshape([1, 512]);

    _interpreter!.run(input, output);
    return List<double>.from(output[0]);
  }

  // ---------------------------------------------------------------------
  // Firestore: register
  // ---------------------------------------------------------------------

  Future<void> _registerStudent() async {
    if (extractedEmbedding == null) {
      _showSnack("Scan a face before registering.");
      return;
    }

    // Guard against the cooldown elapsing/racing between build and tap.
    if (_alreadyRegistered) {
      _showSnack(
        "You can only update facial recognition once every "
            "$_reRegisterCooldownDays days. "
            "$_daysUntilNextRegistration day(s) left.",
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      // Doc id = rollNumber, so re-registering the same roll number
      // overwrites the previous record instead of creating a duplicate.
      await _studentsRef.doc(widget.student.id).set({
        'name': widget.student.name,
        'embedding': extractedEmbedding,
        "id": widget.student.id,
        'created_at': Timestamp.fromDate(DateTime.now()),
        // Firestore stores List<double> natively
      });

      _showSnack(
          "Registered ${widget.student.name} (${widget.student.id}) successfully!");
      _resetCapture(clearForm: true);

      if (mounted) {
        setState(() {
          _alreadyRegistered = true;
          _daysUntilNextRegistration = _reRegisterCooldownDays;
        });
      }
    } catch (e) {
      _showSnack("Registration failed: $e");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // ---------------------------------------------------------------------
  // Firestore: verify / check-in
  // ---------------------------------------------------------------------

  Future<void> _verifyStudent() async {
    if (extractedEmbedding == null) {
      _showSnack("Scan a face before verifying.");
      return;
    }

    setState(() => isVerifying = true);
    try {
      final stdDoc = await _studentsRef.doc(widget.student.id).get();
      if (stdDoc.data() == null) {
        _showSnack("No facial recognition data registered yet.");
        return;
      }

      String? matchedName;
      String? matchedRoll;
      double highestScore = 0.0;

      final data = stdDoc.data();
      final rawEmbedding = (data?['embedding'] as List<dynamic>? ?? []);
      final storedEmbedding =
      rawEmbedding.map((e) => (e as num).toDouble()).toList();

      final similarity = _cosineSimilarity(extractedEmbedding!, storedEmbedding);

      if (similarity > highestScore) {
        highestScore = similarity;
        if (similarity >= _matchThreshold) {
          matchedName = data?['name'] as String?;
          matchedRoll = data?['id'] as String?;
        }
      }

      final isMatched = matchedName != null;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isMatched ? "Attendance Marked! " : "Verification Failed "),
          content: Text(
            isMatched
                ? "Matched: $matchedName ($matchedRoll)\nScore: ${(highestScore * 100).toStringAsFixed(1)}%"
                : "No matching face found.\nHighest Score: ${(highestScore * 100).toStringAsFixed(1)}%",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack("Verification failed: $e");
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  double _cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  void _resetCapture({bool clearForm = false}) {
    setState(() {
      pickedImg = null;
      imgSize = null;
      faces = [];
      extractedEmbedding = null;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasEmbedding = extractedEmbedding != null;
    final busy = isScanning || isSaving || isVerifying;
    final canRegister =
        hasEmbedding && !busy && !_alreadyRegistered && !_checkingRegistration;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title: Text(
          "Face Recognition",
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isModelReady || _checkingRegistration)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),

            // --- Cooldown notice ---
            if (!_checkingRegistration && _alreadyRegistered)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Facial recognition already set up. You can update it "
                            "again in $_daysUntilNextRegistration day"
                            "${_daysUntilNextRegistration == 1 ? '' : 's'}.",
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // --- Face capture area ---
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  pickedImg == null || imgSize == null
                      ? const SizedBox(
                    height: 220,
                    child: Center(child: Text("No photo picked yet")),
                  )
                      : FittedBox(
                    child: SizedBox(
                      height: imgSize!.height,
                      width: imgSize!.width,
                      child: Stack(
                        children: [
                          Image.file(pickedImg!),
                          CustomPaint(
                            size: imgSize!,
                            painter: Facepainter(faces: faces),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isScanning) const CircularProgressIndicator(),
                  if (!isScanning && hasEmbedding)
                    Text(
                      "Face captured — embedding ready (${extractedEmbedding!.length}-dim)",
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: busy || !isModelReady
                            ? null
                            : () => pickImage(ImageSource.camera),
                        icon: Icon(
                          CupertinoIcons.camera,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          "Camera",
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          //border color
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          // foregroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: busy || !isModelReady
                            ? null
                            : () => pickImage(ImageSource.gallery),
                        icon: Icon(
                          Icons.collections,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          "Gallery",
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Register button ---
            ElevatedButton.icon(
              onPressed: canRegister ? _registerStudent : null,
              icon: isSaving
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.person_add),
              label: Text(
                isSaving
                    ? "setting facial recognition..."
                    : _alreadyRegistered
                    ? "Locked (available in $_daysUntilNextRegistration day"
                    "${_daysUntilNextRegistration == 1 ? '' : 's'})"
                    : "Register facial recognition",
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // --- Verify button ---
            // ElevatedButton.icon(
            //   onPressed: (hasEmbedding && !busy) ? _verifyStudent : null,
            //   icon: isVerifying
            //       ? const SizedBox(
            //     height: 18,
            //     width: 18,
            //     child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            //   )
            //       : const Icon(Icons.how_to_reg),
            //   label: Text(isVerifying ? "Verifying..." : "Verify (Mark Attendance)"),
            //   style: ElevatedButton.styleFrom(
            //     minimumSize: const Size.fromHeight(50),
            //     backgroundColor: Colors.green,
            //     foregroundColor: Colors.white,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class Facepainter extends CustomPainter {
  final List<Face> faces;
  const Facepainter({required this.faces});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.red;
    for (Face face in faces) {
      canvas.drawRect(face.boundingBox, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}