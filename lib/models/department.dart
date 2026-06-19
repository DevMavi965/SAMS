import 'package:smas3/maxins/rm_functions.dart';

class Department with RMFuncts{
  String name,hod_name;
  String? id;
  DateTime? created_at;
  Department({
    required this.name,
    required this.hod_name,
    this.id,
    this.created_at
});
  getDepartCode(){
  return  RMFuncts.getFirstLetters(name);
  }
}