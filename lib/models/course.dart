class Course {
  String? id;
  String name,course_code;
  String insAdminId, institute_id, department_id, session_id, semester_id;
  int credit_hours;
  String? lecturer_id,lecturer_name;
  int no_of_lectures;
  String type;// theory,lab
  DateTime? created_at=DateTime.now();
  Course({
    required this.name,
    required this.insAdminId,
    required this.institute_id,
    required this.department_id,
    required this.session_id,
    required this.semester_id,
    required this.course_code,
    required this.credit_hours,
    required this.no_of_lectures,
    required this.type,
    this.lecturer_id,
    this.lecturer_name,
    this.created_at,
    this.id
});
}