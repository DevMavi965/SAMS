import 'package:smas3/models/Lecture_model.dart';

class Lecturer{
  String name,deprt,designation,status,email,phone,E_id;
  List<Course> courses;
  Lecturer({
    required this.E_id,
    required this.name,
    required this.deprt,
    required this.designation,
    required this.status,
    required this.email,
    required this.phone,
    required this.courses,
  });


}