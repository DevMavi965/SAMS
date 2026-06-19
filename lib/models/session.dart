class Session {
  String? id;
  String name;
  DateTime start_date,end_date;
  Session({
    required this.name,
    required this.start_date,
    required this.end_date,
    this.id,
});
  getSession(String departInitials){
    String srt2="${end_date.year}";
    return "$departInitials${start_date.year}"+srt2[srt2.length-2]+srt2[srt2.length-1];
  }
}