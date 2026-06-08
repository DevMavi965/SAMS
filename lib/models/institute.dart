import 'package:cloud_firestore/cloud_firestore.dart';

class Institute {
  String name,address,logo;
  int contact;
  DateTime created_at;
  Map<String,dynamic> location;
  String? id,insAdminId;
  Institute({
    required this.name,
    required this.address,
    required this.contact,
    required this.logo,
    required this.created_at,
    required this.location,
    this.id,
    this.insAdminId
});
}