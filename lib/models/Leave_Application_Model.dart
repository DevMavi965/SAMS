class LeaveApplication{
  String? id;
  String std_name;
  String std_id;
  String type ;//academic,personal,medical,emergency
  DateTime appliedDate,fromDate,tillDate;
  String reason;
  String status;//pending,approved,rejected
  String? approvedby;
  LeaveApplication(
    {
    required this.appliedDate,
    required this.type,
    required this.fromDate,
    required this.tillDate,
    required this.reason,
    required this.status,
    required this.std_name,
    required this.std_id,
     this.approvedby

});
}