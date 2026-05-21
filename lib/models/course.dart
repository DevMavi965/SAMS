class Course {
  String? id;
  String name,course_code;
  int credit_hours;
  String? lecturer;
  int no_of_lectures;
  String type;// theory,lab
  DateTime? created_at=DateTime.now();
  Course({
    required this.name,
    required this.course_code,
    required this.credit_hours,
    required this.no_of_lectures,
    required this.type,
    this.created_at,
    this.id
});
}