import 'package:smas3/models/semester.dart';
import 'package:smas3/models/course.dart';

class Lecturer{
  String name, deprt,designation,status,email,phone,role;
  String? id;
  String insAdminId,instituteId,departmentId;
  List<String>? courses;
  List<int>? semesters;
  DateTime? created_at;
  Lecturer({
    this.id,
    required this.name,
    required this.deprt,
    required this.role,
    required this.insAdminId,
    required this.instituteId,
    required this.departmentId,
    required this.designation,
    required this.status,
    required this.email,
    required this.phone,
    this.courses,
    this.semesters,
    this.created_at,
  });


}