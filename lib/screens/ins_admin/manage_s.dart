import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/db_service.dart';

class ManageAdmins extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const ManageAdmins({super.key, required this.insAdmin, required this.institute});

  @override
  State<ManageAdmins> createState() => _ManageAdminsState();
}

class _ManageAdminsState extends State<ManageAdmins> {
  TextEditingController name=TextEditingController();
  TextEditingController email=TextEditingController();
  TextEditingController password=TextEditingController();
  late  TextEditingController name1=TextEditingController();
  late  TextEditingController email1=TextEditingController();
  final formKey=GlobalKey<FormState>();
  final formKey1=GlobalKey<FormState>();
  List<Admin> admins=[];
  List<String> duties=[
    "Timetable",
    "Announcements",
    "Leave_management",
    "student_management",
    "faculty_management",
    "department_management",//includes adding/removing departments & sessions & semesters
    "course_management",
    "session_management",
  ];
  List<bool> checked=[
    false,
    false,
    false,
    false,//
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
    "Adding/removing departments",
    "Adding/removing courses",
    "Adding/removing sessions & semesters",
  ];
  void _resetForm() {
    name.clear();
    email.clear();
    password.clear();
    assigned.clear();
    for (int i = 0; i < checked.length; i++) {
      checked[i] = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
    ListView(
      children: [
        Text("Manage Admins",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
        SizedBox(height: 7,),
        Text("Admin Management & Permissions",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        StreamBuilder(stream: Provider.of<DbService>(context).dbref.collection("ins_admins")
            .doc(widget.insAdmin.id).collection("institutes")
            .doc(widget.institute.id).collection("admins").snapshots(),
            builder: (context,snapshot){
              if(snapshot.connectionState==ConnectionState.waiting){
                return Center(child:
                SizedBox(
                    width:70,height: 70,
                    child: Lottie.asset("assets/anims/an1.json")),);
              }else
              if(snapshot.hasData){
                admins.clear();
                for(var admin in snapshot.data!.docs){
                  Admin admin1=Admin(
                    id: admin.id,
                    insAdminId: admin['ins_admin_id'],
                    instituteId: admin['institute_id'],
                    name: admin['name'],
                    email: admin['email'],
                    institute: admin['institute'],
                    role: admin['role'],
                    permissions:List<String>.from( admin['permissions']),
                    status: admin['status'],
                  );
                  admins.add(admin1);
                }
                if(admins.isEmpty){
                  return Center(child: Text("No admins found"),);
                }else{
                  return admins.isEmpty?Text("No admins found"):Column(
                    children: [
                      for(int i=0;i<admins.length;i++)...[
                        AdminListCard(admins[i]),
                        SizedBox(height: 10,)
                      ],
                      SizedBox(height: 20,),
                    ],
                  );
                }

              }else
              if(snapshot.hasError){
                return Center(child: Text("Something went wrong"),);
              }return SizedBox();
            }),
        SizedBox(height: 10,),
        ElevatedButton.icon(
          style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,

          ),
          onPressed: (){
            showModalBottomSheet(
                shape:RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                ),
                context: context, builder: (_)=>
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 15,vertical: 10,

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
                                    }else
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
                                    }else if(v.length<8){
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
                                // deprt mng0
                                for(int i=0; i<duties.length; i++)...[
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
                                          Expanded(
                                            flex:1,
                                            child: Container(
                                              margin: EdgeInsets.only(right: 10),
                                              padding: EdgeInsets.all(1),
                                              child: CircleAvatar(

                                                backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                                                child: getIcon(i),
                                              ),
                                            ),),
                                          Expanded(
                                            flex:6,
                                            child:
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(duties[i].split("_").join(" "),style: TextStyle(fontSize: 14),),
                                                SizedBox(height: 3,),
                                                Text(duty_detail[i],overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.grey,fontSize: 12),)
                                              ],
                                            ),),
                                          Expanded(
                                            child: SizedBox(
                                              width: 40,
                                              height: 35,
                                              child: FittedBox(
                                                fit: BoxFit.fill,
                                                child: Switch(
                                                    activeThumbColor: Theme.of(context).primaryColor,
                                                    value: checked[i], onChanged: (v){
                                                  setState(() {
                                                    checked[i]=!checked[i];
                                                  });
                                                }),
                                              ),
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
                                  SizedBox(height: 3,),],
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                                          ),
                                          onPressed: (){

                                        showDialog(context: context, builder:(context)=>AlertDialog(
                                          title: Text("Add Admin"),
                                          content: Text("Are you sure to add the admin?"),
                                          actions: [
                                            ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).primaryColor
                                                ),
                                                onPressed: (){
                                                  Navigator.pop(context);
                                                }, child: Text("No")),
                                            ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).primaryColor
                                                ),
                                                onPressed: (){
                                                  if(formKey.currentState!.validate()){
                                                    for(int i=0; i<checked.length; i++){
                                                      if(checked[i]){
                                                        assigned.add(duties[i]);
                                                      }
                                                    }
                                                    final name1=name.text.trim();
                                                    final email1=email.text.trim();
                                                    final password1=password.text.trim();
                                                    final permissions1=List<String>.from(assigned);
                                                    Admin admin=Admin(
                                                        name: name1,
                                                        insAdminId: widget.insAdmin.id!,
                                                        instituteId: widget.institute.id!,
                                                        email: email1,
                                                        institute: widget.institute.name,
                                                        role: "admin",
                                                        status: "active",
                                                        permissions: permissions1
                                                    );
                                                    _resetForm();
                                                    Provider.of<DbService>(context,listen: false).registerAdmin(widget.insAdmin.id!, widget.institute.id!, admin, password1, context);
                                                  }else{
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("enter valid values")));
                                                  }
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                }, child: Text("Yes")),
                                          ],
                                        ) );
                                      }, child: Text("add",style: TextStyle(color: Colors.white),)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 30,),
                              ],
                            ),
                          ),
                        );
                      },

                    ),
                  ),
                ));
          }, label: Text("add admin",style: TextStyle(fontWeight: FontWeight.w500,color: Colors.white),),icon: Icon(Icons.person_add_alt_rounded,color:Colors.white,),)
      ],
    ));
  }
  Widget AdminListCard(Admin admin){

    return InkWell(
      onDoubleTap: (){
        assigned.clear();
        assigned=List<String>.from(admin.permissions!);
        for(int i=0; i<checked.length; i++){
          checked[i]=false;

        }
        for(int i=0; i<assigned.length; i++){
          checked[duties.indexOf(assigned[i])]=true;
        }
        name1.text=admin.name;
        showModalBottomSheet(
            shape:RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
            ),
            context: context, builder: (_)=>
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 15,vertical: 10,

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
                        key: formKey1,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Update Admin",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                                Spacer(),
                                IconButton(onPressed: (){
                                  Navigator.pop(context);
                                }, icon: Icon(Icons.close))
                              ],
                            ),
                            SizedBox(height: 10,),
                            TextFormField(
                              controller: name1,
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
                            // deprt mng0
                            for(int i=0; i<duties.length; i++)...[
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
                                      Expanded(
                                        flex:1,
                                        child: Container(
                                          margin: EdgeInsets.only(right: 10),
                                          padding: EdgeInsets.all(1),
                                          child: CircleAvatar(

                                            backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                                            child: getIcon(i),
                                          ),
                                        ),),
                                      Expanded(
                                        flex:6,
                                        child:
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(duties[i].split("_").join(" "),style: TextStyle(fontSize: 14),),
                                            SizedBox(height: 3,),
                                            Text(duty_detail[i],overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.grey,fontSize: 12),)
                                          ],
                                        ),),
                                      Expanded(
                                        child: SizedBox(
                                          width: 40,
                                          height: 35,
                                          child: FittedBox(
                                            fit: BoxFit.fill,
                                            child: Switch(
                                                activeThumbColor: Theme.of(context).primaryColor,
                                                value: checked[i], onChanged: (v){
                                              setState(() {
                                                checked[i]=!checked[i];
                                              });
                                            }),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                              ),
                              SizedBox(height: 3,),],
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(onPressed: (){
                                    showDialog(context: context, builder:(context)=>AlertDialog(
                                      title: Text("update Admin"),
                                      content: Text("Are you sure to update the admin?"),
                                      actions: [
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).primaryColor
                                            ),
                                            onPressed: (){
                                              Navigator.pop(context);
                                            }, child: Text("No")),
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Theme.of(context).primaryColor
                                            ),
                                            onPressed: (){
                                              assigned.clear();
                                              if(formKey1.currentState!.validate()){
                                                for(int i=0; i<checked.length; i++){
                                                  if(checked[i]){
                                                    assigned.add(duties[i]);
                                                  }
                                                }
                                                Admin admin1=Admin(
                                                  id: admin.id,//
                                                    name: name1.text.trim(),
                                                    insAdminId: widget.insAdmin.id!,
                                                    instituteId: widget.institute.id!,
                                                    email:admin.email,
                                                    institute: widget.institute.name,
                                                    role: "admin",
                                                    status: "active",
                                                    permissions: assigned
                                                );
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                                Provider.of<DbService>(context,listen: false).updateAdmin(context, admin1);
                                              }else{
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("enter valid values")));
                                              }

                                            }, child: Text("Yes")),
                                      ],
                                    ) );
                                  }, child: Text("add")),
                                ),
                              ],
                            ),
                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    );
                  },

                ),
              ),
            ));
      },
      child: Container(

        padding: EdgeInsets.only(
          left: 15,
          top: 12,
          bottom: 5,
          right: 12
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              offset: Offset(-1, -1),
              blurRadius: 2,
              color: Colors.grey.shade200
            ),
            BoxShadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.grey.shade200
            )
          ],
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
      SizedBox(height: 15,),
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
      SizedBox(height: 10,),
         Row(
       children: [
         Text("created at : ${ DateFormat("dd/MM/yyyy").format(admin.created_at)}",style: TextStyle(color: Colors.grey),),
         Spacer(),
         IconButton(onPressed: (){
           showDialog(context: context, builder: (_)=>AlertDialog(
             title: Text("Delete Admin"),
             icon: Icon(Icons.delete,size: 32,color: Theme.of(context).primaryColor,),
             content: Text("Are you sure you want to delete this admin?"),
             actions: [
               ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).primaryColor
                 ),
                 onPressed: (){
                 Navigator.pop(context);
               }, child: Text("No",style: TextStyle(color: Colors.white),),),
               ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Theme.of(context).primaryColor
                 ),
                 onPressed: (){
                  setState(() {
                  admins.remove(admin);
                  });
                 Provider.of<DbService>(context,listen: false).removeAdmin(context, admin.id!);
                 // Navigator.pop(context);
                 Navigator.pop(context);
               }, child: Text("Yes",style: TextStyle(color: Colors.white),),),

             ],
           ));
         }, icon: Icon(Icons.delete,color: Theme.of(context).primaryColor,))
       ],
         )
        ],
      ),
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

  Widget? getIcon(int i) {
    switch(i){
      case 0:
        return Icon(PhosphorIconsBold.clock,color: Theme.of(context).primaryColor,);
        break;
      case 1:
        return Icon(PhosphorIconsBold.speakerSimpleHigh,color: Theme.of(context).primaryColor,);
        break;
      case 2:
        return Icon(PhosphorIconsBold.notepad,color: Theme.of(context).primaryColor,);
        break;
      case 3:
        return Icon(Icons.person_add_alt_1,color: Theme.of(context).primaryColor,);
        break;
      case 4:
        return Icon(Icons.person_add_alt,color: Theme.of(context).primaryColor,);
        break;
      case 5:
        return Icon(PhosphorIconsBold.buildingApartment,color: Theme.of(context).primaryColor,);
        break;
      case 6:
        return Icon(PhosphorIconsBold.books,color: Theme.of(context).primaryColor,);
        break;
      case 7:
        return Icon(PhosphorIconsBold.desktop,color: Theme.of(context).primaryColor,);
        break;
    }
  }
}


