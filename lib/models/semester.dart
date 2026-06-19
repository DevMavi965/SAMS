class Semester {
  String? id;
  DateTime start_date,end_date;
  int semester_no;
  String institute_id,ins_admin_id,department_id,session_id;
  Semester({
    this.id,
    required this.institute_id,
    required this.ins_admin_id,
    required this.department_id,
    required this.session_id,
   required this.semester_no,
   required this.start_date,
   required this.end_date,
});
}