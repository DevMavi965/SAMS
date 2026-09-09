import 'package:cloud_firestore/cloud_firestore.dart';

class Holidaymodel {
  String? id;
  String title;
  DateTime dated;
  Holidaymodel({
    required this.id,
    required this.title,
    required this.dated
});
  Map<String,dynamic>toMap(){
    return{
      "id":id,
      "title":title,
      "dated":Timestamp.fromDate(dated)
    };
  }
}