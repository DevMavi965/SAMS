class Semester {
  String? id;
  DateTime start_date,end_date;
  int semester_no;
  Semester({
    this.id,
   required this.semester_no,
   required this.start_date,
   required this.end_date,
});
}