import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/lecture.dart';

import '../../services/db_service.dart';
// import the attendance-marking screen once it exists, e.g.:
// import 'mark_attendance_screen.dart';

class FacMarkAttendanceTab extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Lecturer lecturer;

  const FacMarkAttendanceTab({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.lecturer,
  });

  @override
  State<FacMarkAttendanceTab> createState() => _FacMarkAttendanceTabState();
}

// Bundles a lecture with the path context needed to navigate to it.
// Kept together so sorting the list never desyncs a lecture from its ids.
class _LectureEntry {
  final LectureModel lecture;
  final DateTime sortKey; // full date+time — TimeOfDay alone can't be ordered across dates
  final String departmentId, sessionId, semesterId, courseId;

  _LectureEntry({
    required this.lecture,
    required this.sortKey,
    required this.departmentId,
    required this.sessionId,
    required this.semesterId,
    required this.courseId,
  });
}

class _FacMarkAttendanceTabState extends State<FacMarkAttendanceTab> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Text("Mark Attendance",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 7),
          Text("Your lectures, latest first",
              style: TextStyle(fontSize: 15, color: Colors.grey)),
          SizedBox(height: 20),

          StreamBuilder(
            // Reuse the same course-lookup pattern as CourseTab — flat
            // index query, no collection-group index/rules needed.
            stream: Provider.of<DbService>(context, listen: false).indexDoc
                .where("type", isEqualTo: "course")
                .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
                .where("institute_id", isEqualTo: widget.institute.id)
                .where("lecturer_id", isEqualTo: widget.lecturer.id)
                .snapshots(),
            builder: (context, courseIndexSnapshot) {
              if (courseIndexSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ));
              } else if (courseIndexSnapshot.hasError) {
                return Center(child: Text("Error: ${courseIndexSnapshot.error}"));
              } else if (!courseIndexSnapshot.hasData ||
                  courseIndexSnapshot.data!.docs.isEmpty) {
                return Center(
                    child: Text("No courses assigned to you",
                        style: TextStyle(color: Colors.grey)));
              }

              final courseIdxDocs = courseIndexSnapshot.data!.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .where((idx) =>
              idx['department_id'] != null &&
                  idx['session_id'] != null &&
                  idx['semester_id'] != null)
                  .toList();

              return FutureBuilder<List<_LectureEntry>>(
                future: _fetchAllLectures(context, courseIdxDocs),
                builder: (context, lecSnapshot) {
                  if (lecSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ));
                  }
                  if (lecSnapshot.hasError) {
                    return Center(child: Text("Error: ${lecSnapshot.error}"));
                  }

                  final entries = lecSnapshot.data ?? [];
                  // sort as a single unit — lecture and its ids move together
                  entries.sort((a, b) => b.sortKey.compareTo(a.sortKey));

                  if (entries.isEmpty) {
                    return Center(
                        child: Text("No lectures found",
                            style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final lecture = entry.lecture;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MarkAttendancePlaceholder(
                                lecture: lecture,
                                insAdminId: widget.insAdmin.id!,
                                instituteId: widget.institute.id!,
                                departmentId: entry.departmentId,
                                sessionId: entry.sessionId,
                                semesterId: entry.semesterId,
                                courseId: entry.courseId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lecture.course,
                                        style: TextStyle(fontWeight: FontWeight.w600)),
                                    SizedBox(height: 4),
                                    Text(
                                      "${lecture.dated.day}/${lecture.dated.month}/${lecture.dated.year}"
                                          "  ${lecture.start_time.hour.toString().padLeft(2, '0')}:${lecture.start_time.minute.toString().padLeft(2, '0')}"
                                          " - ${lecture.end_time.hour.toString().padLeft(2, '0')}:${lecture.end_time.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    SizedBox(height: 4),
                                    if (lecture.room != null)
                                      Text("Room: ${lecture.room}",
                                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              _StatusBadge(status: lecture.status!),
                            ],
                          ),
                        ),
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

  // Fetches every lecture across all of this lecturer's courses.
  // One-time read (.get(), not .snapshots()) per course's lectures
  // subcollection — simplest way to combine several collections into
  // one sorted list without pulling in a stream-merging package.
  Future<List<_LectureEntry>> _fetchAllLectures(
      BuildContext context, List<Map<String, dynamic>> courseIdxDocs) async {
    final db = Provider.of<DbService>(context, listen: false);
    final results = await Future.wait(courseIdxDocs.map((idx) async {
      final departmentId = idx['department_id'] as String;
      final sessionId = idx['session_id'] as String;
      final semesterId = idx['semester_id'] as String;
      final courseId = idx['id'] as String;

      final lecturesSnap = await db.dbref
          .collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").doc(departmentId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("courses").doc(courseId)
          .collection("lectures")
          .get();

      return lecturesSnap.docs.map((doc) {
        final DateTime startDateTime = doc['start_time'].toDate();
        final DateTime endDateTime = doc['end_time'].toDate();
        final lecture = LectureModel(
          id: doc.id,
          dated: doc['dated'].toDate(),
          // model expects TimeOfDay, Firestore gives a Timestamp -> DateTime
          start_time: TimeOfDay.fromDateTime(startDateTime),
          end_time: TimeOfDay.fromDateTime(endDateTime),
          present: List<String>.from(doc['present'] ?? []),
          absent: List<String>.from(doc['absent'] ?? []),
          room: doc['room'],
          course: doc['course_name'],
          status: doc['status'],
        );
        return _LectureEntry(
          lecture: lecture,
          // keep the full DateTime around separately for sorting —
          // TimeOfDay alone can't be compared across different dates
          sortKey: startDateTime,
          departmentId: departmentId,
          sessionId: sessionId,
          semesterId: semesterId,
          courseId: courseId,
        );
      });
    }));

    return results.expand((e) => e).toList();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case "completed":
        color = Colors.green;
        break;
      case "upcoming":
        color = Colors.orange;
        break;
      case "ongoing":
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// Placeholder — replace with your real attendance-marking screen.
class MarkAttendancePlaceholder extends StatelessWidget {
  final LectureModel lecture;
  final String insAdminId, instituteId, departmentId, sessionId, semesterId, courseId;

  const MarkAttendancePlaceholder({
    super.key,
    required this.lecture,
    required this.insAdminId,
    required this.instituteId,
    required this.departmentId,
    required this.sessionId,
    required this.semesterId,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lecture.course)),
      body: Center(child: Text("TODO: list students of this semester and mark present/absent/late")),
    );
  }
}