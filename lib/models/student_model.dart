class Student{
  String? id;
   String name,instituteId,insAdminId;
   String depart;
   int semester;
   String email,role;
   DateTime? created_at=DateTime.now();

  Student({
    this.id,
    required this.role,
    required this.name,
    required this.insAdminId,
    required this.instituteId,
    required this.depart,
    required this.semester,
    required this.email,
    this.created_at,

    });
}