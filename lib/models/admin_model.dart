class Admin{
  String? id;
  String name,insAdminId,instituteId;
  String email;
  String institute,role,status;
  DateTime created_at=DateTime.now();
  List<String>? permissions;
  Admin({
    required this.name,
    required this.insAdminId,
    required this.instituteId,
    required this.email,
    required this.institute,
    required this.role,
    this.id,
    this.permissions,
    required this.status});
}