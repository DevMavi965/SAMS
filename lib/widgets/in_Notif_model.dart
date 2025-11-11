class In_Notification{
  String title;
  String body;
  String type;//good ,warning,upcoming,attendance
  String time;
  bool is_read;
  In_Notification({
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    required this.is_read,
});
}