import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/admin_model.dart';

class ManageAdmins extends StatefulWidget {
  const ManageAdmins({super.key});

  @override
  State<ManageAdmins> createState() => _ManageAdminsState();
}

class _ManageAdminsState extends State<ManageAdmins> {
  TextEditingController name=TextEditingController();
  TextEditingController email=TextEditingController();
  TextEditingController password=TextEditingController();
  final formKey=GlobalKey<FormState>();
  List<Admin> admins=[
    Admin(name: "farhan abdullah", insAdminId: "23456789", instituteId: "123456789", email: "abf@gmail.com", institute: "ADS", role: "admin", status: "active",permissions: ["student_management","faculty_management"]),
    Admin(name: "abdul martial", insAdminId: "23456789", instituteId: "123456789", email: "abf@gmail.com", institute: "ADS", role: "admin", status: "active",permissions: ["Announcements",]),
    Admin(
        name: "John ali",
        insAdminId: "23456789",
        instituteId: "123456789",
        email: "abf@gmail.com",
        institute: "ADS",
        role: "admin",
        status: "active",
        permissions: ["Timetable","Announcements","Leave_management","student_management","faculty_management","department_management","institute_management"]),
  ];
  List<String> duties=[
    "Timetable",
    "Announcements",
    "Leave_management",
    "student_management",
    "faculty_management",
    "department_management",//includes adding/removing departments & sessions & semesters
  ];
  List<bool> checked=[
    false,
    false,
    false,
    false,
    false,
    false,
  ];
  List<String> assigned=[];
  List<String> duty_detail=[
    "Scheduling lectures & labs",
    "Posting announcements",
    "Approving/Rejecting leave requests",
    "Adding/removing/Editing students records",
    "Managing faculty",
    "Adding/removing departments & sessions & semesters & courses",
  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(
      children: [
        Text("Manage Admins",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
        SizedBox(height: 7,),
        Text("Admin Management & Permissions",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        admins.isEmpty?Text("No admins found"):Column(
          children: [
            for(int i=0;i<admins.length;i++)...[
              AdminListCard(admins[i]),
              SizedBox(height: 10,)
            ],
            SizedBox(height: 20,),
          ],
        ),
       SizedBox(height: 10,),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 0.5
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            )
          ),
          onPressed: (){
          showModalBottomSheet(
              shape:RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
              context: context, builder: (_)=>
              Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10,vertical: 10,

            ),
           child: SizedBox(
             // 70% height of device

             height: MediaQuery.of(context).size.height*0.8,
             //equal to  device width
             width: MediaQuery.of(context).size.width,
             child: StatefulBuilder(
               builder: (BuildContext context, void Function(void Function()) setState) {
                 return  SingleChildScrollView(
                   child: Form(
                     key: formKey,
                     child: Column(
                       children: [
                         Row(
                           children: [
                             Text("Add Admin",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                             Spacer(),
                             IconButton(onPressed: (){
                               Navigator.pop(context);
                             }, icon: Icon(Icons.close))
                           ],
                         ),
                         SizedBox(height: 10,),
                         TextFormField(
                           controller: name,
                           decoration: InputDecoration(
                             labelText: "Name",
                             border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(10),
                                 borderSide: BorderSide(
                                     width: 0.5,
                                     color: Colors.grey
                                 )
                             ),
                           ),
                           validator: (v){
                             if(v!.isEmpty){
                               return "Please enter name";
                             }else if(v.length<3){
                               return "Please enter valid name";
                             }
                             return null;
                           },
                         ),//name
                         SizedBox(height: 15,),
                         TextFormField(
                           controller: email,
                           decoration: InputDecoration(
                             labelText: "Email",
                             border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(10),
                                 borderSide: BorderSide(
                                     width: 0.5,
                                     color: Colors.grey
                                 )
                             ),
                           ),
                           validator: (v){
                             if(v!.isEmpty){
                               return "Please enter email";
                             }else if(v.length<3){
                               return "Please enter valid email";
                             }else if(!v.contains("@")){
                               return "Please enter valid email";
                             }else if(!v.contains(".")){
                               return "Please enter valid email";
                             }else if(!v.contains("com")){
                               return "Please enter valid email";
                             }else if(!v.contains("gmail" )&&!v.contains("yahoo")&&!v.contains("outlook")){
                               return "Please enter valid email";
                             }
                             // method II
                             // final emailRegex =
                             // RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                             // if (!emailRegex.hasMatch(v.trim())) {
                             //   return "Please enter valid email";
                             // }
                             return null;
                           },
                         ),//email
                         SizedBox(height: 15,),
                         TextFormField(
                           controller: password,
                           decoration: InputDecoration(
                             labelText: "password",
                             border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(10),
                                 borderSide: BorderSide(
                                     width: 0.5,
                                     color: Colors.grey
                                 )
                             ),
                           ),
                           validator: (v){
                             if(v!.isEmpty){
                               return "Please enter password";
                             }else if(v.length<6){
                               return "Password must be at least 6 characters";
                             }
                             return null;
                           },
                         ),//password
                         SizedBox(height: 15,),
                         SizedBox(height: 7,),
                         Row(
                           children: [
                             Text("Duties & Permissions",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600)),
                           ],
                         ),
                         SizedBox(height: 3,),
                         Row(
                           children: [
                             Text("Select what admin is allowed to manage",style: TextStyle(fontSize: 13,color: Colors.grey),),
                           ],
                         ),
                         SizedBox(height: 7,),
                         // deprt mng
                         Container(
                           padding: EdgeInsets.symmetric(
                             horizontal: 10,vertical: 10
                           ),
                             decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(10),
                                 border: Border.all(
                                     color: Colors.grey.shade300,
                                     width: 0.5
                                 )
                             ),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 CircleAvatar(
                                   child: Icon(PhosphorIconsBold.buildingApartment),
                                 ),
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(duties[0]),
                                     SizedBox(height: 3,),
                                     Text(duty_detail[0],style: TextStyle(color: Colors.grey),)
                                   ],
                                 ),
                                 SizedBox(
                                   width: 40,
                                   height: 35,
                                   child: FittedBox(
                                     fit: BoxFit.fill,
                                     child: Switch(value: checked[0], onChanged: (v){
                                       setState(() {
                                         checked[0]=!checked[0];
                                       });
                                     }),
                                   ),
                                 )
                                 // IconButton(onPressed: (){
                                 //   setState(() {
                                 //     checked[0]=!checked[0];
                                 //   });
                                 // }, icon: Icon(checked[0]?Icons.check_circle:Icons.circle_outlined))

                               ],
                             )
                         ),
                         SizedBox(height: 3,),
                         // students
                         Container(
                             padding: EdgeInsets.symmetric(
                                 horizontal: 10,vertical: 10
                             ),
                             decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(10),
                                 border: Border.all(
                                     color: Colors.grey.shade300,
                                     width: 0.5
                                 )
                             ),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 CircleAvatar(
                                   child: Icon(Icons.people_alt),
                                 ),
                                 Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(duties[1]),
                                     SizedBox(height: 3,),
                                     Text(duty_detail[1],style: TextStyle(color: Colors.grey),)
                                   ],
                                 ),
                                 SizedBox(
                                   width: 40,
                                   height: 35,
                                   child: FittedBox(
                                     fit: BoxFit.fill,
                                     child: Switch(value: checked[1], onChanged: (v){
                                       setState(() {
                                         checked[1]=!checked[1];
                                       });
                                     }),
                                   ),
                                 )
                                 // IconButton(onPressed: (){
                                 //   setState(() {
                                 //     checked[0]=!checked[0];
                                 //   });
                                 // }, icon: Icon(checked[0]?Icons.check_circle:Icons.circle_outlined))

                               ],
                             )
                         ),
                         SizedBox(height: 3,),
                         //
                         ElevatedButton(onPressed: (){}, child: Text("add"))
                       ],
                     ),
                   ),
                 );
               },

             ),
           ),
          ));
        }, label: Text("add admin",style: TextStyle(fontWeight: FontWeight.w500,color: Theme.of(context).primaryColor),),icon: Icon(Icons.person_add_alt_rounded,color: Theme.of(context).primaryColor,),)
      ],
    ));
  }
  Widget AdminListCard(Admin admin){

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,vertical: 10
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5
        )
      ),
child: Column(
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withAlpha(70),
        radius: 28,
        child: Text(getFirstLetters(admin.name),style: TextStyle(
          color: Theme.of(context).primaryColor,
        ),),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(admin.name,style: TextStyle(fontWeight: FontWeight.w600),),
          SizedBox(height: 3,),
          Text(admin.email,style: TextStyle(color: Colors.grey),),
        ],
      ),
      SizedBox(),
      Badge(
        backgroundColor: Theme.of(context).primaryColor.withAlpha(240),
        label: Padding(padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 8),
        child:Text(admin.permissions==null?"no duties":(admin.permissions!.isEmpty?"no duties":"${admin.permissions!.length} duties"),))
      )
    ],),
    SizedBox(height: 10,),
    Row(
      children: [
        for(int i=0;i<admin.permissions!.length && i<3;i++)...[
         Badge(
           backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
           label: Padding(padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 8),
               child:Text(getFirstWord(admin.permissions![i]),style: TextStyle(fontSize: 10,color: Theme.of(context).primaryColor),),
         )),
        SizedBox(width: 5,)],
        admin.permissions!.length>3?Badge(
            backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
            label: Padding(padding: const EdgeInsets.symmetric(horizontal: 7,vertical: 8),
              child:Text("${admin.permissions!.length-3} More",style: TextStyle(fontSize: 10,color: Theme.of(context).primaryColor),),
            )):SizedBox()
      ],
    ),
  ],
),
    );
   }

  String getFirstLetters(String name) {
    if (name.isEmpty) return '';
    List<String> words = name.split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.length == 1) {
      String singleWord = words[0];
      if (singleWord.length == 1) return singleWord.toUpperCase();
      return singleWord.substring(0, 2).toUpperCase();
    }
    return words.map((word) => word[0]).join().toUpperCase();
  }

  String getFirstWord(String s) {
    return s.split("_")[0];
  }
}


