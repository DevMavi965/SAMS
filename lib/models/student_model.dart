class Student{
  String? id;
   String name,instituteId,insAdminId;
   String sessionId,departId,semesterId;
   String email,role;
   DateTime? created_at=DateTime.now();

  Student({
    this.id,
    required this.role,
    required this.name,
    required this.insAdminId,
    required this.instituteId,
    required this.departId,
    required this.sessionId,
    required this.semesterId,
    required this.email,
    this.created_at,

    });
}