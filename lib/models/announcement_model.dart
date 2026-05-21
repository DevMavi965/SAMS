class Announcement{
  String? id;
  String an_title,
      an_message,
      an_type;//urgent,general,event
     String? target_aud;//all user,students,faculty,any department
  DateTime? created_at=DateTime.now();
  Announcement({
    required this.an_title,
    required this.an_message,
    required this.an_type,
    this.id,
    this.created_at,
    this.target_aud});

}