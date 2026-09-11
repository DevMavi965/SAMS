import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/student_model.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../services/db_service.dart';
import '../../services/face_net_service/facePainter.dart';

// Multi-face student registration + face-verification screen.
// - Register: capture a face photo (single face expected), generate a
//   512-dim FaceNet embedding, save {name, rollNumber, embedding} to
//   Firestore's "students" collection.
// - Verify: capture a photo containing ANY NUMBER of faces, extract an
//   embedding for each one, and match every face against the registered
//   students in a single pass — so a group photo marks attendance for
//   everyone recognized in it, not just the best single match.
class GroupCheckInFace extends StatefulWidget {
  final List<Student> students;
  final LectureModel lecture;
  const GroupCheckInFace({super.key, required this.students, required this.lecture});
  @override
  State<GroupCheckInFace> createState() => _GroupCheckInFaceState();
}

/// Result of matching one detected face against the students collection.
class _FaceMatch {
  final Face face;
  final List<double>? embedding;
  String? name;
  String? id;
  double score;
  bool matched;

  _FaceMatch({
    required this.face,
    required this.embedding,
    this.name,
    this.id,
    this.score = 0.0,
    this.matched = false,
  });
}

class _GroupCheckInFaceState extends State<GroupCheckInFace> {

  // --- Firestore ---
  final CollectionReference<Map<String, dynamic>> _studentsRef =
  FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("embeddings");

  // --- ML Kit / TFLite ---
  FaceDetector? _faceDetector;
  Interpreter? _interpreter;

  // --- UI / capture state ---
  File? pickedImg;
  Size? imgSize;

  // One entry per face detected in the current photo.
  List<_FaceMatch> faceMatches = [];

  bool isModelReady = false;
  bool isScanning = false;
  bool isSaving = false;
  bool isVerifying = false;
  bool _verifiedOnce = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController rollController = TextEditingController();

  static const double _matchThreshold = 0.72;

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

  @override
  void dispose() {
    _faceDetector?.close();
    _interpreter?.close();
    nameController.dispose();
    rollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Image capture + per-face embedding extraction
  // ---------------------------------------------------------------------

  Future<void> pickImage(ImageSource source) async {
    final result = await ImagePicker().pickImage(source: source);
    if (result == null) return;

    setState(() {
      faceMatches = [];
      pickedImg = File(result.path);
      imgSize = null;
      isScanning = true;
      _verifiedOnce = false;
    });

    await _decodeImageSize();
    await _detectFacesAndExtractEmbeddings();

    if (mounted) setState(() => isScanning = false);
  }

  Future<void> _decodeImageSize() async {
    if (pickedImg == null) return;
    final bytes = await pickedImg!.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() {//ok
      imgSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    });
  }

  /// Detects every face in the photo and extracts one embedding per face.
  /// This is the key change from the single-face version: instead of
  /// grabbing `detectedFaces.first`, we loop over all of them.
  Future<void> _detectFacesAndExtractEmbeddings() async {
    if (pickedImg == null || _faceDetector == null) return;

    final inputImage = InputImage.fromFilePath(pickedImg!.path);
    final detectedFaces = await _faceDetector!.processImage(inputImage);

    if (!mounted) return;

    if (detectedFaces.isEmpty) {
      setState(() => faceMatches = []);
      _showSnack("No face detected — try another photo.");
      return;
    }

    // Decode the source image once and reuse it for every crop instead of
    // re-reading + re-decoding the file per face.
    final rawImage = img.decodeImage(await pickedImg!.readAsBytes());

    final matches = <_FaceMatch>[];
    for (final face in detectedFaces) {
      final embedding = rawImage == null
          ? null
          : await _getEmbeddingFromDecoded(rawImage, face);
      matches.add(_FaceMatch(face: face, embedding: embedding));
    }

    if (!mounted) return;
    setState(() => faceMatches = matches);

    final withEmbedding = matches.where((m) => m.embedding != null).length;
    if (withEmbedding < matches.length) {
      _showSnack(
          "Detected ${matches.length} face(s), embedded $withEmbedding — some crops failed.");
    } else {
      _showSnack("Detected ${matches.length} face(s).");
    }
  }

  /// Crops [face] out of an already-decoded [rawImage], resizes to 160x160,
  /// normalizes pixels, and runs the FaceNet TFLite model to get a
  /// 512-dim embedding.
  Future<List<double>?> _getEmbeddingFromDecoded(
      img.Image rawImage, Face face) async {
    if (_interpreter == null) return null;

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
  // Firestore: register (still single-face — registration only makes
  // sense for one identity at a time)
  // ---------------------------------------------------------------------



  // ---------------------------------------------------------------------
  // Firestore: verify / check-in — now matches EVERY face in the photo
  // ---------------------------------------------------------------------

  Future<void> _verifyStudents() async {
    if (faceMatches.isEmpty || faceMatches.every((m) => m.embedding == null)) {
      _showSnack("Scan a photo with at least one face before verifying.");
      return;
    }

    setState(() => isVerifying = true);
    try {
      final snapshot = await _studentsRef.get();
      if (snapshot.docs.isEmpty) {
        _showSnack("No students registered yet.");
        return;
      }

      // Pre-decode every stored student embedding once.
      final students = snapshot.docs.map((doc) {
        final data = doc.data();
        final raw = (data['embedding'] as List<dynamic>? ?? []);
        return (
        name: data['name'] as String?,
        id: data['id'] as String?,
        embedding: raw.map((e) => (e as num).toDouble()).toList(),
        );
      }).toList();
      for (final m in faceMatches) {
        m.matched = false;
        m.name = null;
        m.id = null;
        m.score = 0.0;
      }
      // Score every (face, student) pair.
      // candidates: (faceIndex, studentIndex, score)
      final candidates = <(int, int, double)>[];
      for (int f = 0; f < faceMatches.length; f++) {
        final faceEmbedding = faceMatches[f].embedding;
        if (faceEmbedding == null) continue;
        for (int s = 0; s < students.length; s++) {
          final score = _cosineSimilarity(faceEmbedding, students[s].embedding);
          if (score >= _matchThreshold) {
            candidates.add((f, s, score));
          }
        }
      }

      // Greedy assignment, highest score first, so the same student can't
      // be double-booked to two different faces in one group photo, and
      // one face can't be matched to two students.
      candidates.sort((a, b) => b.$3.compareTo(a.$3));
      final claimedFaces = <int>{};
      final claimedStudents = <int>{};

      for (final (f, s, score) in candidates) {
        if (claimedFaces.contains(f) || claimedStudents.contains(s)) continue;
        claimedFaces.add(f);
        claimedStudents.add(s);
        faceMatches[f].matched = true;
        faceMatches[f].name = students[s].name;
        faceMatches[f].id = students[s].id;
        faceMatches[f].score = score;
      }
      // Faces that stayed unclaimed just keep matched = false.

      // Batch-write attendance for everyone who matched. Adjust the
      // target path/fields to whatever SAMS's lecture attendance schema
      // expects (e.g. lectures/{lectureId} -> attendance array) — this is
      // a generic example writing to a flat "attendance_log" collection.
      final matchedCount = faceMatches.where((m) => m.matched).length;
      // if (matchedCount > 0) {
      //   final batch = FirebaseFirestore.instance.batch();
      //   for (final m in faceMatches.where((m) => m.matched)) {
      //     final logRef = FirebaseFirestore.instance
      //         .collection('attendance_log')
      //         .doc(); // auto-id per check-in event
      //     batch.set(logRef, {
      //       'rollNumber': m.rollNumber,
      //       'name': m.name,
      //       'score': m.score,
      //       'method': 'face',
      //       'checkin': FieldValue.serverTimestamp(),
      //     });
      //   }
      //   await batch.commit();
      // }

      if (!mounted) return;
      setState(() => _verifiedOnce = true);
      _showResultsDialog(matchedCount);
    } catch (e) {
      _showSnack("Verification failed: $e");
      print(e.toString());
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  void _showResultsDialog(int matchedCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(matchedCount > 0
            ? "$matchedCount / ${faceMatches.length} Marked ✅"
            : "No Matches Found ❌"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: faceMatches.length,
            itemBuilder: (context, i) {
              final m = faceMatches[i];
              return ListTile(
                dense: true,
                leading: Icon(
                  m.matched ? Icons.check_circle : Icons.cancel,
                  color: m.matched ? Colors.green : Colors.red,
                ),
                title: Text(m.matched ? "${m.name} (${m.id})" : "Face ${i + 1} — unknown"),
                subtitle: Text("Score: ${(m.score * 100).toStringAsFixed(1)}%"),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
            ),
            onPressed: (){
              List<String> matchedStudentIds=[];
              for(int i=0;i<faceMatches.length;i++){
                if(faceMatches[i].matched){
                  matchedStudentIds.add(faceMatches[i].id!);
                }
              }
              if(matchedStudentIds.isEmpty){
                _showSnack("No student face matched");
                Navigator.pop(context);
                // _resetCapture(clearForm: true);
                return;
              }
              Provider.of<DbService>(context,listen: false).checkInGroup(context,widget.lecture,matchedStudentIds,"facial");
              Navigator.pop(context);

              _resetCapture(clearForm: true);
            },
            child:  Text(faceMatches.length<0?"ok":"confirm check-in",style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),),
          ),
        ],
      ),
    );
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
      faceMatches = [];
      _verifiedOnce = false;
      if (clearForm) {
        nameController.clear();
        rollController.clear();
      }
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
    final hasFaces = faceMatches.isNotEmpty;
    final busy = isScanning || isSaving || isVerifying;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        title:  Text("Face Attendance",style: TextStyle(fontWeight: FontWeight.w500,color: Theme.of(context).primaryColor),),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isModelReady)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),

            // --- Registration form (only used for the single-face
            // Register flow; ignored by Verify) ---
            // TextFormField(
            //   controller: nameController,
            //   enabled: !busy,
            //   decoration: const InputDecoration(
            //     labelText: "Student Name",
            //     border: OutlineInputBorder(),
            //     prefixIcon: Icon(Icons.person_outline),
            //   ),
            //   textCapitalization: TextCapitalization.words,
            // ),
            // const SizedBox(height: 12),
            // TextFormField(
            //   controller: rollController,
            //   enabled: !busy,
            //   decoration: const InputDecoration(
            //     labelText: "Roll Number",
            //     border: OutlineInputBorder(),
            //     prefixIcon: Icon(Icons.badge_outlined),
            //   ),
            //   keyboardType: TextInputType.text,
            // ),

            const SizedBox(height: 20),
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
                    child: Center(child: Text("No photo scanned yet")),
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
                            painter: Facepainter(
                              faces: faceMatches.map((m) => m.face).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isScanning) const CircularProgressIndicator(),
                  if (!isScanning && hasFaces)
                    Text(
                      "${faceMatches.length} face(s) captured"
                          "${_verifiedOnce ? " — ${faceMatches.where((m) => m.matched).length} matched" : ""}",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  // Per-face result chips after verification.
                  if (_verifiedOnce)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: faceMatches.asMap().entries.map((e) {
                          final m = e.value;
                          return Chip(
                            backgroundColor:
                            m.matched ? Colors.green.shade100 : Colors.red.shade100,
                            label: Text(m.matched ? "${m.name}" : "Face ${e.key + 1}: ?"),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: busy || !isModelReady ? null : () => pickImage(ImageSource.camera),
                        icon:  Icon(CupertinoIcons.camera,color:  Theme.of(context).primaryColor,),
                        label:  Text("Camera",style: TextStyle(color:  Theme.of(context).primaryColor),),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(

                        onPressed: busy || !isModelReady ? null : () => pickImage(ImageSource.gallery),
                        icon: Icon(Icons.collections,color:  Theme.of(context).primaryColor,),
                        label:  Text("Gallery",style: TextStyle(color:  Theme.of(context).primaryColor),),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Register button (single face only) ---
            // ElevatedButton.icon(
            //   onPressed: (faceMatches.length == 1 && !busy) ? _registerStudent : null,
            //   icon: isSaving
            //       ? const SizedBox(
            //     height: 18,
            //     width: 18,
            //     child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            //   )
            //       : const Icon(Icons.person_add),
            //   label: Text(isSaving ? "Registering..." : "Register Student"),
            //   style: ElevatedButton.styleFrom(
            //     minimumSize: const Size.fromHeight(50),
            //     backgroundColor: Colors.blue,
            //     foregroundColor: Colors.white,
            //   ),
            // ),
            const SizedBox(height: 10),

            // --- Verify button (all faces at once) ---
            ElevatedButton.icon(
              onPressed: (hasFaces && !busy) ? _verifyStudents : null,
              icon: isVerifying
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.how_to_reg),
              label: Text(isVerifying
                  ? "Verifying..."
                  : "Verify All (Mark Attendance)"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
