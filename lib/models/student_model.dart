class Student{
  String? id;
   String name;
   String depart;
   int semester;
   String email;
   DateTime? created_at=DateTime.now();

  Student({
    this.id,
    required this.name,
    required this.depart,
    required this.semester,
    required this.email,
    this.created_at,

    });
}