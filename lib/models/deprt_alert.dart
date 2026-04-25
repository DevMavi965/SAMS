class DepartmentalAlerts {
  String id, content;
  String type; //positive ,negative,neutral
  DateTime created_at;

  DepartmentalAlerts({required this.id,
    required this.content,
    required this.type,
    required this.created_at
  });
}