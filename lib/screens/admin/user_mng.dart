import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/models/course.dart';

class UserMng extends StatefulWidget {
  const UserMng({super.key});

  @override
  State<UserMng> createState() => _UserMngState();
}

class _UserMngState extends State<UserMng> {
  List<String> opts=[
    "Students","Faculty"
  ];
  List<Student> students=[
    Student(id: "2345", name: "hasan", depart: "Computer Science", semester: 1, email: "hasan@gmail.com", ),
    Student(id: "t656", name: "noor", depart: "Information Technology", semester: 6, email: "n00r45@gmail.com", ),
    Student(id: "7666", name: "hasan", depart: "Computer Science", semester: 1, email: "hasan@gmail.com", ),
    Student(id: "6578", name: "noor", depart: "Information Technology", semester: 6, email: "n00r45@gmail.com", ),
    Student(id: "9765", name: "hasan", depart: "Computer Science", semester: 1, email: "hasan@gmail.com", ),
    Student(id: "5583", name: "noor", depart: "Information Technology", semester: 6, email: "n00r45@gmail.com",),


  ];
  List<Lecturer> lecturers=[
    Lecturer(id: "6789",
      name:"murad ali",
      deprt: "Computer Science",
      designation: "Assistant Professor",
      status: "active",
      email: "murad@gmail.com",
      phone: "03351094534",
      courses: ["CS703","CS704"],
      semesters: [1,2],),
    Lecturer(id: "6789", name:"murad ali", deprt: "Computer Science",
        designation: "Assistant Professor", status: "active", email: "murad@gmail.com",
        phone: "03351094534", courses:["CS703","CS704"]),
    Lecturer(id: "9876", name:"murad ali", deprt: "Physics",
        designation: "Assistant Professor", status: "active",
        email: "murad@gmail.com", phone: "03351094534", courses: ["CS703","CS704"]),
  ];
  int selected_opt=0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ListView(

      children: [
        Text("User Management",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
        SizedBox(height: 7,),
        Text("Manage Faculty and Students",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10,vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade400,
              width: 0.5
            )
          ),
          child:
          selected_opt==0?TextFormField(
            onChanged: (v){
              setState(() {
                students.clear();
                for(int i=0;i<students.length;i++){
                  if(students[i].name.contains(v)){
                    students.add(students[i]);
                  }
                }
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none
              ),
              hintText: "Search users...",
              hintStyle: TextStyle(
                color: Colors.grey
              ),
              prefixIcon: Icon(Icons.search,color: Colors.grey,size: 30,),
            ),
          ):TextFormField(
            onChanged: (v){
              setState(() {
                lecturers.clear();
                for(int i=0;i<lecturers.length;i++){
                  if(lecturers[i].name.contains(v)){
                    lecturers.add(lecturers[i]);
                  }
                }
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none
              ),
              hintText: "Search users...",
              hintStyle: TextStyle(
                  color: Colors.grey
              ),
              prefixIcon: Icon(Icons.search,color: Colors.grey,size: 30,),
            ),
          ),
        ),
        SizedBox(height: 20,),
        // selector panel
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
          padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
          decoration: BoxDecoration(
              color:Color(0xfff1f5f9) ,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey.shade300,
                  width: 0.9
              )
          ),
          child: Row(
            children: [
              for(int i=0;i<opts.length;i++)
                Expanded(
                  child: InkWell(
                    onTap: (){
                      setState(() {
                        selected_opt=i;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                          color:i==selected_opt? Colors.white:Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              width:i==selected_opt? 0.1:0,
                              color: i==selected_opt? Colors.grey.shade200:Colors.transparent
                          )
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(i==0?Icons.people_alt_outlined:Icons.school_outlined,),
                            SizedBox(width: 5,),
                            Text(opts[i],textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black,fontWeight: FontWeight.w400),),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
        SizedBox(height: 20,),
        Container(
          child:selected_opt==0?
          (students.isEmpty?Text("No students found"): Column(children: [
            for(int i=0;i<students.length;i++)
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: 5,vertical: 5
                ),
                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),


                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(70),
                      radius:28,
                      child: Text(getFirstLetters(students[i].name),style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(students[i].name,style: TextStyle(fontWeight: FontWeight.w600),),
                        SizedBox(height: 3,),
                        Text(students[i].email,style: TextStyle(color: Colors.grey),),
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Badge(label: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text(students[i].depart,style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black
                              ),),
                            ),backgroundColor: Colors.grey.withAlpha(70),),
                            SizedBox(width: 10,),
                            Badge(label: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text("semester ${students[i].semester}",style: TextStyle(color: Colors.black),),
                            ),backgroundColor: Color(0xfff1f5f9),),

                          ],
                        )
                      ],),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Badge(label: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Text(students[i].id!,style: TextStyle(color: Colors.black),),
                        ),backgroundColor:Color(0xfff1f5f9),),
                        SizedBox(height: 10,),
                        Icon(Icons.more_vert,color: Colors.grey,),
                      ],
                    )
                  ],),
              ),
            SizedBox(height: 20,),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0.5
                    ),
                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(15),
                    )
                ),
                onPressed: (){

                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1_outlined,color:Colors.black,),
                    SizedBox(width: 10,),
                    Text("Add Student",style: TextStyle(color: Colors.black),),
                  ],))
          ],)):
         (lecturers.isEmpty?Text("No lecturers found"): Column(children: [
            for(int i=0;i<lecturers.length;i++)
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: 5,vertical: 5
                ),
                padding: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),


                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(70),
                      radius:28,
                      child: Text(getFirstLetters(lecturers[i].name),style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lecturers[i].name,style: TextStyle(fontWeight: FontWeight.w600),),
                        SizedBox(height: 3,),
                        Text(lecturers[i].email,style: TextStyle(color: Colors.grey),),
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Badge(label: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text(lecturers[i].deprt,style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black
                              ),),
                            ),backgroundColor: Colors.grey.withAlpha(70),),
                            SizedBox(width: 10,),
                            Badge(label: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Text("courses ${lecturers[i].courses!.length}",style: TextStyle(color: Colors.black),),
                            ),backgroundColor: Color(0xfff1f5f9),),

                          ],
                        )
                      ],),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Badge(label: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Text(lecturers[i].id!,style: TextStyle(color: Colors.black),),
                        ),backgroundColor:Color(0xfff1f5f9),),
                        SizedBox(height: 10,),
                        Icon(Icons.more_vert,color: Colors.grey,),
                      ],
                    )
                  ],),
              ),
            SizedBox(height: 20,),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 0.5
                    ),
                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(15),
                    )
                ),
                onPressed: (){

                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1_outlined,color:Colors.black,),
                    SizedBox(width: 10,),
                    Text("Add Faculty",style: TextStyle(color: Colors.black),),
                  ],))
          ],)),
        ),

      ],
    )
    );
  }
  static String getFirstLetters(String input) {
    if (input.isEmpty) return '';

    List<String> words = input.split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    // If only one word_deprtm name, return first 2letters
    if (words.length == 1) {
      String singleWord = words[0];
      if (singleWord.length == 1) return singleWord.toUpperCase();
      return singleWord.substring(0, 2).toUpperCase();
    }

    // Multiple words: return first letter of each word
    return words.map((word) => word[0]).join().toUpperCase();
  }
}
