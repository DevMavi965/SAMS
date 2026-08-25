import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/attendance.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/screens/faculty/attend_view.dart';

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

// Merges a calendar date with a TimeOfDay into a real, comparable DateTime.
// lecture.dated alone is midnight-only, so comparing it directly against
// DateTime.now() was the bug: "today" always looked like "already completed".
DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

                      // Real start/end timestamps, not just the bare date.
                      final start = _combineDateAndTime(
                          lecture.dated, lecture.start_time);
                      final end = _combineDateAndTime(
                          lecture.dated, lecture.end_time);

                      return _LectureCard(
                        lecture: lecture,
                        start: start,
                        end: end,
                        onTapWhileOngoing: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AttendView(
                                      lecture: lecture,
                                      insAdminId: widget.insAdmin.id!,
                                      instituteId: widget.institute.id!,
                                      departmentId: entry.departmentId,
                                      sessionId: entry.sessionId,
                                      semesterId: entry.semesterId,
                                      courseId: entry.courseId,
                                    )
                            ),
                          );
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
          attendance: (doc['attendance'] as List<dynamic>? ?? [])
            .map((m) => Attendance.fromMap(Map<String, dynamic>.from(m as Map)))
            .toList(),
          room: doc['room'],
          course: doc['course_name'],
          status: doc['status'],
        );
        return _LectureEntry(
          lecture: lecture,
          // keeing the full DatexTime around separately for sort
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

class _LectureCard extends StatefulWidget {
  final LectureModel lecture;
  final DateTime start;
  final DateTime end;
  final VoidCallback onTapWhileOngoing;

  const _LectureCard({
    required this.lecture,
    required this.start,
    required this.end,
    required this.onTapWhileOngoing,
  });

  @override
  State<_LectureCard> createState() => _LectureCardState();
}

class _LectureCardState extends State<_LectureCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;

  late AnimationController _borderController;
  late Animation<Color?> _borderColor;

  @override
  void initState() {
    super.initState();

    // Border animation: WHITE <-> RED
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _borderColor = ColorTween(
      begin: Colors.white,
      end: Colors.red,
    ).animate(_borderController);

    // Check status every 30 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        if (mounted) {
          setState(() {});
          _updateAnimation();
        }
      },
    );

    // Start animation immediately if already ongoing
    _updateAnimation();
  }

  void _updateAnimation() {
    if (_isOngoing) {
      if (!_borderController.isAnimating) {
        _borderController.repeat(reverse: true);
      }
    } else {
      _borderController.stop();
      _borderController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _borderController.dispose();
    super.dispose();
  }

  bool get _isOngoing {
    final now = DateTime.now();

    return !now.isBefore(widget.start) &&
        !now.isAfter(widget.end);
  }

  @override
  Widget build(BuildContext context) {
    final lecture = widget.lecture;
    final isOngoing = _isOngoing;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),

        onTap: () {
          if (isOngoing) {
            widget.onTapWhileOngoing();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  DateTime.now().isBefore(widget.start)
                      ? "Attendance opens once the lecture starts."
                      : "This lecture has already ended.",
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },

        child: Opacity(
          opacity: isOngoing ? 1.0 : 0.85,

          child: AnimatedBuilder(
            animation: _borderColor,

            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),

                decoration: BoxDecoration(
                  border: Border.all(
                    color: isOngoing
                        ? (_borderColor.value ?? Colors.red)
                        : Colors.grey.withOpacity(0.2),
                    width: isOngoing ? 2 : 1,
                  ),

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(7),
                ),

                child: child,
              );
            },

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture.course,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        "${lecture.dated.day}/${lecture.dated.month}/${lecture.dated.year}"
                            "  ${lecture.start_time.hour.toString().padLeft(2, '0')}:${lecture.start_time.minute.toString().padLeft(2, '0')}"
                            " - ${lecture.end_time.hour.toString().padLeft(2, '0')}:${lecture.end_time.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 7),

                      if (lecture.room != null)
                        Text(
                          "Room: ${lecture.room}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      SizedBox(),
                    ],
                  ),
                ),

                _LectureStatusBadge(
                  start: widget.start,
                  end: widget.end,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Self-ticking status badge. Recomputes its own state on a timer instead
// of relying on the parent list to rebuild, so "upcoming" countdowns and
// the ongoing/completed transition stay live in real time.
class _LectureStatusBadge extends StatefulWidget {
  final DateTime start;
  final DateTime end;

  const _LectureStatusBadge({required this.start, required this.end});

  @override
  State<_LectureStatusBadge> createState() => _LectureStatusBadgeState();
}

class _LectureStatusBadgeState extends State<_LectureStatusBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Standalone helper: time left until [target]. Null if already past.
  static Duration? timeRemaining(DateTime target) {
    final now = DateTime.now();
    if (target.isBefore(now)) return null;
    return target.difference(now);
  }

  static String _formatDuration(Duration d) {
    if (d.inDays > 0) return "${d.inDays}d ${d.inHours % 24}h";
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes % 60}m";
    if (d.inMinutes > 0) return "${d.inMinutes}m";
    return "<1m";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    if (now.isBefore(widget.start)) {
      final remaining = timeRemaining(widget.start)!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
           Badge(backgroundColor: Colors.blue, label:
          Container(
              margin: EdgeInsets.symmetric(
                horizontal: 6,vertical: 5
              ),
              child: Text("upcoming"))),
          const SizedBox(height: 4),
          Text(
            "in ${_formatDuration(remaining)}",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      );
    } else if (now.isAfter(widget.end)) {
      return  Badge(backgroundColor: Colors.green, label:
      Container(
          margin: EdgeInsets.symmetric(
            horizontal: 6,vertical: 5
          ),
          child: Text("completed")));
    } else {
      return  Badge(backgroundColor: Colors.red, label:
      Container(
          margin: EdgeInsets.symmetric(
            horizontal: 6,vertical: 5
          ),
          child: Text("ongoing")));
    }
  }
}