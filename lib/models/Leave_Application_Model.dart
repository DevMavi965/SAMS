class LeaveApplication{
  String std_name;
  String std_id;
  String type ;//academic,personal,medical,emergency
  String appliedDate,fromDate,tillDate,reason;
  String status;//pending,approved,rejected
  LeaveApplication({
    required this.appliedDate,
    required this.type,
    required this.fromDate,
    required this.tillDate,
    required this.reason,
    required this.status,
    required this.std_name,
    required this.std_id,


});
}