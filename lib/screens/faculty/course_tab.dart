import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/course.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/lecture.dart';

import '../../models/department.dart';
import '../../models/fac_model.dart';
import '../../services/db_service.dart';

class CourseTab extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Lecturer lecturer;
  const CourseTab({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.lecturer,
  });

  @override
  State<CourseTab> createState() => _CourseTabState();
}

class _CourseTabState extends State<CourseTab> {
  // Cache session/semester name lookups so we don't refetch on every rebuild.
  // Keyed by departmentId too, since courses can now span departments.
  final Map<String, Future<String>> _sessionNameCache = {};
  final Map<String, Future<String>> _semesterNameCache = {};

  Future<String> _getSessionName(String departmentId, String sessionId) {
    final cacheKey = "$departmentId/$sessionId";
    return _sessionNameCache.putIfAbsent(cacheKey, () async {
      try {
        final doc = await Provider.of<DbService>(context, listen: false).dbref
            .collection("ins_admins")
            .doc(widget.insAdmin.id)
            .collection("institutes")
            .doc(widget.institute.id)
            .collection("departments")
            .doc(departmentId) // was widget.department.id
            .collection("sessions")
            .doc(sessionId)
            .get();
        if (!doc.exists) return "Unknown session";
        final data = doc.data();
        return (data != null && data.containsKey('name'))
            ? data['name']
            : "Unnamed session";
      } catch (e) {
        return "Unknown session";
      }
    });
  }

  Future<String> _getSemesterName(String departmentId, String sessionId, String semesterId) {
    final cacheKey = "$departmentId/$sessionId/$semesterId";
    return _semesterNameCache.putIfAbsent(cacheKey, () async {
      try {
        final doc = await Provider.of<DbService>(context, listen: false).dbref
            .collection("ins_admins")
            .doc(widget.insAdmin.id)
            .collection("institutes")
            .doc(widget.institute.id)
            .collection("departments")
            .doc(departmentId) // was widget.department.id
            .collection("sessions")
            .doc(sessionId)
            .collection("semesters")
            .doc(semesterId)
            .get();
        if (!doc.exists) return "Unknown semester";
        final data = doc.data();
        // Semester docs store "semester_no", not "name".
        if (data != null && data.containsKey('semester_no')) {
          return "Semester ${data['semester_no']}";
        }
        return "Unnamed semester";
      } catch (e) {
        return "Unknown semester";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Text("My Courses",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          Text("View your courses",style: TextStyle(fontSize: 15,color: Colors.grey),),
          SizedBox(height: 10,),
          StreamBuilder(
            // indexDoc is a flat collection, so this query needs no composite
            // collection-group index and no special security rules beyond
            // what already covers /SAMS/{document=**}.
            stream: Provider.of<DbService>(context, listen: false).indexDoc
                .where("type", isEqualTo: "course")
                .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
                .where("institute_id", isEqualTo: widget.institute.id)
            // Intentionally NOT filtering by department_id — a lecturer
            // can teach courses in departments other than their own.
                .where("lecturer_id", isEqualTo: widget.lecturer.id)
                .snapshots(),
            builder: (context, indexSnapshot) {
              if (indexSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child:SizedBox(
                    height: 60,
                    width: 60,
                    child: Lottie.asset("assets/anims/an1.json")),);
              } else if (indexSnapshot.hasError) {
                return Center(child: Text("snapshot error: ${indexSnapshot.error}"));
              } else if (!indexSnapshot.hasData || indexSnapshot.data!.docs.isEmpty) {
                return Center(child: Text("no courses assigned to you",style: TextStyle(color: Colors.grey),));
              }

              final indexDocs = indexSnapshot.data!.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: indexDocs.length,
                itemBuilder: (context, i) {
                  final idx = indexDocs[i];

                  // Defensive: skip if the index doc is missing path fields.
                  if (idx['department_id'] == null ||
                      idx['session_id'] == null ||
                      idx['semester_id'] == null) {
                    return SizedBox.shrink();
                  }

                  final departmentId = idx['department_id'] as String;

                  return StreamBuilder(
                    stream: Provider.of<DbService>(context, listen: false).dbref
                        .collection("ins_admins")
                        .doc(widget.insAdmin.id)
                        .collection("institutes")
                        .doc(widget.institute.id)
                        .collection("departments")
                        .doc(departmentId) // was widget.department.id
                        .collection("sessions")
                        .doc(idx['session_id'])
                        .collection("semesters")
                        .doc(idx['semester_id'])
                        .collection("courses")
                        .doc(idx['id'])
                        .snapshots(),
                    builder: (context, courseSnapshot) {
                      if (courseSnapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 60,
                          child: Center(child:SizedBox(
                              height: 60,
                              width: 60,
                              child: Lottie.asset("assets/anims/an1.json")),
                          ),
                        );
                      }
                      if (courseSnapshot.hasError) {
                        return SizedBox.shrink();
                      }
                      if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
                        return SizedBox.shrink();
                      }

                      final doc = courseSnapshot.data!;
                      final course = Course(
                        id: doc.id,
                        name: doc['name'],
                        course_code: doc['course_code'],
                        credit_hours: doc['credit_hours'],
                        no_of_lectures: doc['no_of_lectures'],
                        type: doc['type'],
                        lecturer_id: doc['lecturer_id'],
                        lecturer_name: doc['lecturer_name'],
                        created_at: doc['created_at'] != null
                            ? doc['created_at'].toDate()
                            : null,
                        insAdminId: doc['ins_admin_id'],
                        institute_id: doc['institute_id'],
                        department_id: doc['department_id'],
                        session_id: doc['session_id'],
                        semester_id: doc['semester_id'],
                      );

                      return FutureBuilder<List<String>>(
                        future: Future.wait([
                          _getSessionName(departmentId, idx['session_id']),
                          _getSemesterName(departmentId, idx['session_id'], idx['semester_id']),
                        ]),
                        builder: (context, namesSnapshot) {
                          String sessionName = "Loading...";
                          String semesterName = "Loading...";

                          if (namesSnapshot.connectionState == ConnectionState.done) {
                            if (namesSnapshot.hasError) {
                              sessionName = "Unknown session";
                              semesterName = "Unknown semester";
                            } else if (namesSnapshot.hasData) {
                              sessionName = namesSnapshot.data![0];
                              semesterName = namesSnapshot.data![1];
                            }
                          }

                          return _CourseCard(course: course, session: sessionName, semester: semesterName);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
  Widget _CourseCard({required Course course,required String session,required String semester}) {
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
                        PhosphorIconsBold.chalkboardTeacher,
                        color: Colors.black54,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          session,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black54,fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsBold.student,
                        color: Colors.black54,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          semester,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black54,fontWeight: FontWeight.w600, fontSize: 12),
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
          ],
        ),
      ),
    );
  }
}