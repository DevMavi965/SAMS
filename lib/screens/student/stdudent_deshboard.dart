import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/screens/admin/admin_deshboard.dart';
import 'package:smas3/screens/student/alert_tab.dart';
import 'package:smas3/screens/student/leave_tab.dart';
import 'package:smas3/screens/student/profile_tab.dart';
import 'package:smas3/screens/student/scheduleTab.dart';
import 'package:smas3/screens/student/std_home.dart';
import 'package:smas3/widgets/student_widgets/Custome_line_chart.dart';
import 'package:smas3/widgets/student_widgets/att_rec_card.dart';
import 'package:smas3/widgets/student_widgets/daily_status_card.dart';
import 'package:smas3/widgets/student_widgets/over_all_att_card.dart';
import 'package:smas3/widgets/student_widgets/std_announc_card.dart';
import 'package:smas3/widgets/student_widgets/upcoming_class_card.dart';

import '../../models/Leave_Application_Model.dart';
import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../services/db_service.dart';
/*
 Student dashboard shell — bottom nav + the 5 tab screens.

 [Scheduletab] needs `insAdmin`/`institute`/`department`/`session`/
 [semester], which are only known after `getInsAdminInsDep()` finishes
 its Firestore reads. Previously `screens` was a `late` field built
 with `insAdmin!` etc., and `build()` read it unconditionally — so the
 very first frame (before the fetch resolves) force-unwrapped still-null
 fields and crashed with "Null check operator used on a null value".
 Because the field was `late`, that failed initialization didn't stick:
 the next rebuild (triggered once the fetch's `setState` actually ran)
 retried and succeeded — which is why the crash only flashed for a
 couple of seconds instead of staying broken.

 Fix: [......build().....] now returns a loading screen until every required
 field is actually nonnull, and the tab list is built via a getter
 (computed fresh each build) instead of a `late` field, so it's never
evaluated before the data it depends on exists.

 */
class StudentDeshboard extends StatefulWidget {
  final Student student;
  const StudentDeshboard({super.key, required this.student});

  @override
  State<StudentDeshboard> createState() => _StudentDeshboardState();
}

class _StudentDeshboardState extends State<StudentDeshboard> {
  InsAdmin? insAdmin;
  Institute? institute;
  Department? department;
  Session? session;
  Semester? semester;

  bool isLoading = true;
  String? loadError;

  Future<void> getInsAdminInsDep() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final db = Provider.of<DbService>(context, listen: false);

      final insAdmindoc =
      await db.dbref.collection("ins_admins").doc(widget.student.insAdminId).get();
      final loadedInsAdmin = InsAdmin(
        id: insAdmindoc.id,
        role: insAdmindoc['role'],
        name: insAdmindoc['name'],
        email: insAdmindoc['email'],
        status: insAdmindoc['status'],
        last_login: insAdmindoc['last_login'].toDate(),
        created_at: insAdmindoc['created_at'].toDate(),
      );

      final instituteDoc = await db.dbref
          .collection("ins_admins")
          .doc(widget.student.insAdminId)
          .collection("institutes")
          .doc(widget.student.instituteId)
          .get();
      final loadedInstitute = Institute(
        id: instituteDoc.id,
        name: instituteDoc['name'],
        address: instituteDoc['address'],
        contact: instituteDoc['contact'],
        created_at: instituteDoc['created_at'].toDate(),
        location: instituteDoc['location'],
        insAdminId: widget.student.insAdminId,
        logo: instituteDoc['logo'],
      );

      final depDoc = await db.dbref
          .collection("ins_admins")
          .doc(widget.student.insAdminId)
          .collection("institutes")
          .doc(widget.student.instituteId)
          .collection("departments")
          .doc(widget.student.departId)
          .get();
      final loadedDepartment = Department(
        id: depDoc.id,
        name: depDoc['name'],
        hod_name: depDoc['hod_name'],
        created_at: depDoc['created_at'].toDate(),
      );

      final sesDoc = await db.dbref
          .collection("ins_admins")
          .doc(widget.student.insAdminId)
          .collection("institutes")
          .doc(widget.student.instituteId)
          .collection("departments")
          .doc(widget.student.departId)
          .collection("sessions")
          .doc(widget.student.sessionId)
          .get();
      final loadedSession = Session(
        id: sesDoc.id,
        name: sesDoc["name"],
        start_date: sesDoc["start_date"].toDate(),
        end_date: sesDoc["end_date"].toDate(),
      );

      final sems = await db.dbref
          .collection("ins_admins")
          .doc(widget.student.insAdminId)
          .collection("institutes")
          .doc(widget.student.instituteId)
          .collection("departments")
          .doc(widget.student.departId)
          .collection("sessions")
          .doc(widget.student.sessionId)
          .collection("semesters")
          .doc(widget.student.semesterId)
          .get();
      final loadedSemester = Semester(
        id: sems.id,
        institute_id: widget.student.instituteId,
        ins_admin_id: widget.student.insAdminId,
        department_id: widget.student.departId,
        session_id: widget.student.sessionId,
        semester_no: sems['semester_no'],
        start_date: sems['start_date'].toDate(),
        end_date: sems['end_date'].toDate(),
      );

      if (!mounted) return;
      setState(() {
        insAdmin = loadedInsAdmin;
        institute = loadedInstitute;
        department = loadedDepartment;
        session = loadedSession;
        semester = loadedSemester;
      });
    } catch (e) {
      debugPrint("StudentDeshboard.getInsAdminInsDep error: $e");
      if (!mounted) return;
      setState(() {
        loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  int current = 0;
  static const List<String> menus = ["home", "schedule", "leave", "announcements_std", "profile"];


  List<Widget> get _screens => [
    StdHome(student: widget.student),
    Scheduletab(
      insAdmin: insAdmin!,
      institute: institute!,
      department: department!,
      session: session!,
      semester: semester!,
    ),
    LeaveTab(student: widget.student,
      insAdmin: insAdmin!,
      institute: institute!,
      department: department!,
      session: session!,
      semester: semester!,
    ),
    AlertTab(
      insAdmin: insAdmin!,
      institute: institute!,
    ),
    ProfileTab(student: widget.student),
  ];

  @override
  void initState() {
    super.initState();
    getInsAdminInsDep();
  }

  bool get _dataReady =>
      insAdmin != null &&
          institute != null &&
          department != null &&
          session != null &&
          semester != null;

  @override
  Widget build(BuildContext context) {
    if (!_dataReady) {
      if (loadError != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text("Couldn't load your dashboard.\n$loadError",
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: getInsAdminInsDep,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _screens[current],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        currentIndex: current,
        type: BottomNavigationBarType.fixed,
        onTap: (v) {
          setState(() {
            current = v;
          });
        },
        items: [
          for (int i = 0; i < menus.length; i++)
            BottomNavigationBarItem(
              icon: i == 4
                  ? const Icon(CupertinoIcons.profile_circled)
                  : (i == 3
                  ? const Icon(PhosphorIconsBold.bell)
                  : (i == 2
                  ? const Icon(PhosphorIconsBold.notebook)
                  : (i == 0 ? const Icon(Icons.home) : const Icon(PhosphorIconsBold.calendarBlank)))),
              label: menus[i],
            ),
        ],
      ),
    );
  }
}