import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/course.dart';
import 'package:smas3/models/fac_model.dart';

import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../models/semester.dart';
import '../../models/session.dart';
import '../../services/db_service.dart';

class CourseUpd extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;
  final Course course;

  const CourseUpd({super.key, required this.insAdmin, required this.institute, required this.department, required this.session, required this.semester, required this.course});

  @override
  State<CourseUpd> createState() => _CourseUpdState();
}

class _CourseUpdState extends State<CourseUpd> {
  final fkey=GlobalKey<FormState>();
  TextEditingController name=TextEditingController();
  TextEditingController course_code=TextEditingController();
  TextEditingController credit_hours=TextEditingController();
  TextEditingController no_of_lectures=TextEditingController();
  List<Lecturer> lecturers=[];
  String? selectedType;//theory or lab
  String? selectedFac;
  @override
  void initState() {
    name.text=widget.course.name;
    course_code.text=widget.course.course_code;
    credit_hours.text=widget.course.credit_hours.toString();
    no_of_lectures.text=widget.course.no_of_lectures.toString();
    selectedType=widget.course.type;
    selectedFac=widget.course.lecturer_id;
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("update Course",style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: Form(
        key: fkey,
        child: ListView(
          padding: EdgeInsets.symmetric(
              vertical: 20,horizontal: 15),
          children: [
            SizedBox(height: 10,),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Course Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  // borderSide: BorderSide(color: Colors.grey),
                ),

                prefixIcon: Icon(CupertinoIcons.book),
              ),
              controller: name,
              validator: (v){
                if(v!.isEmpty){
                  return "Please enter course name";
                }else if(v.length<4){
                  return "Course name should be at least 4 characters";
                }else if(v.length>30){
                  return "Course name should be less than 30 characters";
                }
                return null;
              },
            ),
            SizedBox(height: 10,),
            TextFormField(
              decoration: InputDecoration(
                labelText: "Course Code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  // borderSide: BorderSide(color: Colors.grey),
                ),

                prefixIcon: Icon(PhosphorIconsBold.cashRegister),
              ),
              controller: course_code,
              validator: (v){
                if(v!.isEmpty){
                  return "Please enter course code";
                }else if(v.length<3){
                  return "Course code should be at least 3 characters";
                }else if(v.length>10){
                  return "Course code should be less than 0 characters";
                }
                return null;
              },
            ),
            SizedBox(height: 10,),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Credit Hours",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  // borderSide: BorderSide(color: Colors.grey),
                ),

                prefixIcon: Icon(CupertinoIcons.timer),
              ),
              controller: credit_hours,
              validator: (v){
                if(v!.isEmpty){
                  return "Please enter credit hours";
                }else if(int.parse(v)<0){
                  return "please enter valid value";
                }else if(int.parse(v)>10){
                  return "Course cannot have more than 10 credit hours";
                }
                return null;
              },
            ),
            SizedBox(height: 10,),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "No of Lectures",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  // borderSide: BorderSide(color: Colors.grey),
                ),

                prefixIcon: Icon(CupertinoIcons.calendar),
              ),
              controller: no_of_lectures,
              validator: (v){
                if(v!.isEmpty){
                  return "Please enter no of lectures";
                }else if(int.parse(v)<0){
                  return "please enter valid value";
                }else if(int.parse(v).runtimeType!=int){
                  return "please enter valid value";
                }else if(int.parse(v)>200){
                  return "Course cannot have more than 200 lectures";
                }
                return null;
              },
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white
              ),
              margin: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: StreamBuilder(
                  stream:Provider.of<DbService>(context,listen: false).dbref
                      .collection("ins_admins").doc(widget.insAdmin.id)
                      .collection("institutes").doc(widget.institute.id)
                      .collection("departments").doc(widget.department.id)
                      .collection("faculty").snapshots() ,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return Center(child: CircularProgressIndicator(),);
                    }else if(snapshot.hasError){
                      return Center(child: Text(snapshot.error.toString()),);
                    }else if(!snapshot.hasData){
                      return Center(child: Text("No data found"),);
                    }else if(snapshot.hasData){
                      if(snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text("No faculty found,add faculty to continue"),);
                      }
                      lecturers.clear();
                      for(var doc in snapshot.data!.docs){
                        lecturers.add(
                            Lecturer(
                              id: doc.id,
                              name: doc['name'],
                              deprt: doc['depart'],
                              role: doc['role'],
                              instituteId: widget.institute.id!,
                              insAdminId: widget.insAdmin.id!,
                              departmentId: doc['department_id'],
                              designation: doc['designation'],
                              status: doc['status'],
                              email: doc['email'],
                              phone: doc['phone'],
                              semesters: List<int>.from(doc['semester']),
                              courses: List<String>.from(doc['courses']),
                              created_at: doc['created_at'].toDate(),
                            )
                        );
                      }
                      return DropdownButton(
                          value: selectedFac,
                          hint: Text("Select Faculty"),
                          isExpanded: true,
                          icon: Icon(Icons.person),
                          items: [
                            for(var lec in lecturers)
                              DropdownMenuItem(value: lec.id,child: Text(lec.name),),
                          ],
                          onChanged: (v){
                            setState(() {
                              selectedFac=v;
                            });
                          });
                    }
                    return SizedBox();
                  }),
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white
              ),
              margin: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: DropdownButton(
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down),
                  value: selectedType,
                  hint: Text("Select Course Type"),
                  items:
                  [
                    DropdownMenuItem(value: "theory",child: Text("Theory")),
                    DropdownMenuItem(value: "lab",child: Text("Lab")),

                  ]
                  , onChanged: (v){
                setState(() {
                  selectedType=v;
                });
              }),
            ),
            SizedBox(height: 15,),

            ElevatedButton(
                onPressed: (){
                  if(fkey.currentState!.validate()){
                    if(selectedType!=null && selectedFac!=null){
                      showDialog(context: context, builder: (context)=>AlertDialog(
                        title: Text("Update Course"),
                        content: Text("Are you sure you want to update this course?"),
                        actions: [
                          FilledButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(Colors.red)
                              ),
                              onPressed: (){
                                Navigator.pop(context);
                              }, child: Text("Cancel")),
                          FilledButton(
                              style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor)
                              ),
                              onPressed: (){
                                Course course1=  Course(
                                    id: widget.course.id,
                                    name: name.text.trim(),
                                    course_code: course_code.text.trim(),
                                    credit_hours: int.parse(credit_hours.text.trim()),
                                    no_of_lectures: int.parse(no_of_lectures.text.trim()),
                                    type: selectedType!,
                                    lecturer_id: selectedFac,
                                    insAdminId: widget.insAdmin.id!,
                                    institute_id: widget.institute.id!,
                                    department_id: widget.department.id!,
                                    session_id: widget.session.id!,
                                    semester_id: widget.semester.id!,
                                    lecturer_name: lecturers.firstWhere((element) => element.id==selectedFac).name,
                                    created_at: widget.course.created_at,
                                );
                                Provider.of<DbService>(context,listen: false).updateCourse(context, course1);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }, child: Text("Yes")),

                        ],
                      ));

                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select course type and faculty"),));
                    }
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all the fields"),));
                  }

                  // Provider.of<DbService>(context,listen: false).addCourse(context, widget.insAdmin.id!, widget.institute.id!, widget.department.id!, widget.session.id!, widget.semester.id!, course);
                }, child: Text("Add"))
          ],
        ),
      ),
    );
  }
}
