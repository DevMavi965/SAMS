import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/course.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/screens/management/Course_add.dart';
import 'package:smas3/screens/management/Course_upd.dart';

import '../../models/department.dart';
import '../../models/institute.dart';
import '../../models/semester.dart';
import '../../models/session.dart';
import '../../services/db_service.dart';

class CourseOps extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;
  const CourseOps({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.session,
    required this.semester,
  });

  @override
  State<CourseOps> createState() => _CourseOpsState();
}

class _CourseOpsState extends State<CourseOps> {
  List<Course> courses = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Courses", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: Provider.of<DbService>(context, listen: false).dbref
            .collection("ins_admins")
            .doc(widget.insAdmin.id)
            .collection("institutes")
            .doc(widget.institute.id)
            .collection("departments")
            .doc(widget.department.id)
            .collection("sessions")
            .doc(widget.session.id)
            .collection("semesters")
            .doc(widget.semester.id)
            .collection("courses")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData) {
            return Center(child: Text("No data found"));
          } else if (snapshot.hasData) {
            if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No course found, Add first"));
            } else {
              courses.clear();
              for (var course1 in snapshot.data!.docs) {
                courses.add(
                  Course(
                    id: course1.id,
                    name: course1['name'],
                    course_code: course1['course_code'],
                    credit_hours: course1['credit_hours'],
                    no_of_lectures: course1['no_of_lectures'],
                    type: course1['type'],
                    lecturer_id: course1['lecturer_id'],
                    lecturer_name: course1['lecturer_name'],
                    created_at: course1['created_at'].toDate(),
                    insAdminId: course1['ins_admin_id'],
                    institute_id: course1['institute_id'],
                    department_id: course1['department_id'],
                    session_id: course1['session_id'],
                    semester_id: course1['semester_id'],
                  ),
                );
              }
            }
            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, i) {
                return _CourseCard(course: courses[i]);
              },
            );
          }
          return SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseAdd(
                insAdmin: widget.insAdmin,
                institute: widget.institute,
                department: widget.department,
                session: widget.session,
                semester: widget.semester,
              ),
            ),
          );
        },
        child: FaIcon(FontAwesomeIcons.plus),
      ),
    );
  }

  Widget _CourseCard({required Course course}) {
    return Card(
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.2),
                radius: 28,
                // Image.asset("assets/images/course.png",fit: BoxFit.contain,height: 25,width: 25,),
                child: FaIcon(
                  FontAwesomeIcons.book,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        "Course Code ",
                        style: TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                      SizedBox(width: 5),
                      Text(
                        course.course_code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_crop_circle,
                        color: Colors.black54,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          course.lecturer_name == null
                              ? "not assigned"
                              : course.lecturer_name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.timer,
                        color: Colors.black54,
                        size: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(width: 5),
                      Text(
                        "${course.credit_hours} credit hours",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        color: Colors.black54,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        "${course.no_of_lectures} Total lectures",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          icon: Icon(Icons.delete,color: Colors.red,size: 25,),
                          title: Text("Delete Course"),
                          content: Text(
                            "Are you sure you want to delete this course?",
                          ),
                          actions: [
                            FilledButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  Colors.red,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Cancel",style: TextStyle(color: Colors.white),),
                            ),
                            FilledButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                              onPressed: () {
                                Provider.of<DbService>(
                                  context,
                                  listen: false,
                                ).removeCourse(context, course.id!);
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text("Yes",style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.delete,color: Colors.red,),
                  ),
                  IconButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>CourseUpd(insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, session: widget.session, semester: widget.semester,course: course,)));
                  }, icon: FaIcon(FontAwesomeIcons.penToSquare,size: 18,color: Theme.of(context).primaryColor,))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
