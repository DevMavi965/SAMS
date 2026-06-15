import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class AddInstitute extends StatefulWidget {
  final InsAdmin insAdmin;
  const AddInstitute({super.key, required this.insAdmin});

  @override
  State<AddInstitute> createState() => _AddInstituteState();
}

class _AddInstituteState extends State<AddInstitute> {
  // Institute(
  // id: ins.id,
  // insAdminId: widget.insAdmin.id,
  // name: ins['name'],
  // address: ins['address'],
  // contact: ins['contact'],
  // logo: ins['logo'],
  // created_at: ins['created_at'].toDate(),
  // location: ins['location']
  // )
  final fkey=GlobalKey<FormState>();
  TextEditingController name=TextEditingController();
  TextEditingController address=TextEditingController();
  TextEditingController contact=TextEditingController();
  TextEditingController longtitude=TextEditingController();
  TextEditingController latitude=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Add Institute",style: TextStyle(color:Colors.white,fontWeight: FontWeight.bold,fontSize: 22),),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 15
        ),
        child: Form(
          key:fkey,
          child: Column(
            children: [
              SizedBox(height: 20,),
              TextFormField(
                controller: name,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter name";
                  }else if(v.length<4){
                    return "name must be at least 4 characters";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "institute name",
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),

              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: address,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter address";
                  }else if(v.length<4){
                    return "address must be at least 4 characters";
                    }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "institute address",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: contact,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter contact";
                  }else if(v.length<10){
                    return "contact must be at least 10 characters";
                  }else if(v.contains(" ")){
                    return "contact must not contain spaces";
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "institute contact",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: longtitude,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter longitude";
                  }else if(double.tryParse(v)==null){
                    return "enter valid value";
                  }else if(v.contains(" ")){
                    return "longitude must not contain spaces";
                  }else if(double.parse(v)<-180 || double.parse(v)>180){
                    return "longitude must be between -180 and 180";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "institute longitude",
                  prefixIcon: Icon(Icons.edit_location_alt),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: latitude,
                validator: (v){
                  if(v!.isEmpty){
                    return "Please enter latitude";
                  }else if(double.tryParse(v)==null){
                    return "enter valid value";
                  }else if(v.contains(" ")){
                    return "latitude must not contain spaces";
                  }else if(double.parse(v)<-90 || double.parse(v)>90){
                    return "latitude must be between -90 and 90";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "institute latitude",
                  prefixIcon: Icon(Icons.edit_location_alt_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20,),
              ElevatedButton.icon(onPressed: (){
                if(fkey.currentState!.validate()){
                  showDialog(context: context, builder: (_)=>AlertDialog(
                    title: Text("Add institute"),
                    content: Text("Are you sure you want to add this institute?"),
                    actions: [
                      TextButton(onPressed: (){

                        Navigator.pop(context);
                      }, child: Text("No")),
                      TextButton(onPressed: (){
                        Provider.of<DbService>(context,listen: false).addInstitute(context,
                            widget.insAdmin.id!, Institute(
                                name: name.text.trim(),
                                insAdminId: widget.insAdmin.id,
                                address: address.text.trim(),
                                contact: int.parse(contact.text.trim()),
                                created_at: DateTime.now(),
                              logo: getFirstLetters(name.text.trim()),
                                location: {
                                  "long":double.parse(longtitude.text.trim()),
                                  "lat":double.parse(latitude.text.trim()),
                            },
                            ));
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }, child: Text("Yes")),
                    ],
                  ));
                }
              },
                  label: Text("Add institute",style: TextStyle(color: Theme.of(context).primaryColor),),
                  icon: Icon(Icons.add_business_rounded,color: Theme.of(context).primaryColor,),
              )

            ],
          ),
        ),
      ),
    );
  }

  String? getFirstLetters(String trim) {
    return trim.split(" ").map((e) => e[0]).join();

  }
}
