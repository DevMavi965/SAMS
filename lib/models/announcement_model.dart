class Announcement{
  String an_title,
      an_message,
      an_type,//urgent,general,event
      target_aud;//all user,students,faculty,any department
  Announcement({required this.an_title,required this.an_message,
    required this.an_type,required this.target_aud});
}