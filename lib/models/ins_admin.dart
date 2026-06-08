class InsAdmin {
  String? id;
  String name,email ,role;
  String status;
  DateTime? created_at,last_login;
  InsAdmin({
    this.id,
    required this.role,
    required this.name,
    required this.email,
    required this.status,
     this.created_at,
     this.last_login
});
}