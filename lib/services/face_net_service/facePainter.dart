import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class Facepainter extends CustomPainter{
  final List<Face> faces;
 const Facepainter({required this.faces});
  @override
  void paint(Canvas canvas, Size size) {
   final paint=Paint()
       ..style=PaintingStyle.stroke
       ..strokeWidth=5
       ..color=Colors.red;
   for(Face face in faces){
     canvas.drawRect(face.boundingBox, paint);
   }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}