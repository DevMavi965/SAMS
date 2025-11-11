import 'package:smas3/models/Lecture_model.dart';

class Lecture{
  Course course;
  int total_std,absent_std,late_std,present_std;
  String status;
  Lecture({
    required this.course,
    required this.total_std,
    required this.absent_std,
    required this.late_std,
    required this.present_std,
    required this.status,//comp for complete,incomplete,upcoming
});
}