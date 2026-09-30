import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/screens/faculty/group_checkin.dart';

import '../../models/attendance.dart';
import '../../models/student_model.dart';
import '../../services/db_service.dart';

class AttendView extends StatefulWidget {
  final LectureModel lecture;
  final String insAdminId, instituteId, departmentId, sessionId, semesterId, courseId;
  const AttendView({
    super.key,
    required this.lecture,
    required this.insAdminId,
    required this.instituteId,
    required this.departmentId,
    required this.sessionId,
    required this.semesterId,
    required this.courseId});

  @override
  State<AttendView> createState() => _AttendViewState();
}

class _AttendViewState extends State<AttendView> {
  List<Student> students = [];
  Set<String> _onLeave = {}; // student ids
  bool _autoMarking = false; // prevents double runs
  Timer? _ticker;
  bool _finalizing = false;
  bool _finalized = false;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
    _loadFinalized();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // true from 5 min before lecture end, and any time after it
  bool get _canFinalize {
    final t = widget.lecture.end_time;
    if (t == null) return false;
    final d = widget.lecture.dated;
    final end = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    return DateTime.now().isAfter(end.subtract(const Duration(minutes: 5)));
  }

  // hide the button if this lecture was already finalized
  Future<void> _loadFinalized() async {
    try {
      final snap = await Provider.of<DbService>(context, listen: false)
          .indexDoc.doc(widget.lecture.id).get();
      if (mounted && snap.data()?['attendance_finalized'] == true) {
        setState(() => _finalized = true);
      }
    } catch (_) {}
  }

  Future<void> _finalize() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Finalize attendance?"),
        content: const Text(
            "Students without a complete record (check-in, mid-point and check-out) "
                "will be marked absent. Approved leaves are kept. This can't be undone."),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red
            ),
              onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel",style: TextStyle(color: Colors.white),)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor
            ),
              onPressed: () => Navigator.pop(ctx, true), child: const Text("Finalize",style: TextStyle(color: Colors.white),)),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _finalizing = true);
    final done = await Provider.of<DbService>(context, listen: false)
        .finalizeLectureAttendance(context, widget.lecture, onLeaveIds: _onLeave);
    if (!mounted) return;
    setState(() {
      _finalizing = false;
      if (done) _finalized = true;
    });
  }

  Widget _finalizeSection() {
    final Widget child;
    if (_finalized) {
      child = Container(
        key: const ValueKey('done'),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text("Attendance finalized",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else if (_canFinalize) {
      child = Padding(
        key: const ValueKey('btn'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _RotatingBorderButton(
          label: "Finalize Attendance",
          icon: Icons.verified_rounded,
          color: Theme.of(context).primaryColor,
          busy: _finalizing,
          onPressed: _finalizing ? null : _finalize,
        ),
      );
    } else {
      child = const SizedBox.shrink(key: ValueKey('none'));
    }

    // fades and slides open when the 5-minute window starts
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: SizeTransition(sizeFactor: a, axisAlignment: -1, child: c),
      ),
      child: child,
    );
  }

  // load approved leaves, then auto-mark them
  Future<void> _loadLeaves() async {
    try {
      final snap = await Provider.of<DbService>(context, listen: false)
          .dbref
          .collection("ins_admins").doc(widget.insAdminId)
          .collection("institutes").doc(widget.instituteId)
          .collection("leave_applications")
          .where("status", isEqualTo: "approved")
          .get();

      final d = widget.lecture.dated;
      final day = DateTime(d.year, d.month, d.day);
      final ids = <String>{};

      for (var doc in snap.docs) {
        final s = doc['start_date'].toDate();
        final e = doc['end_date'].toDate();
        final start = DateTime(s.year, s.month, s.day);
        final end = DateTime(e.year, e.month, e.day);
        // lecture inside leave
        if (!day.isBefore(start) && !day.isAfter(end)) {
          ids.add(doc['student_id']);
        }
      }
      if (!mounted) return;
      setState(() => _onLeave = ids);
      await _autoMarkLeaves();
    } catch (e) {
      print("leave load error: $e");
    }
  }

  // mark every student on leave (of this semester) automatically
  Future<void> _autoMarkLeaves() async {
    if (_autoMarking || _onLeave.isEmpty) return;
    _autoMarking = true;
    try {
      final db = Provider.of<DbService>(context, listen: false);

      // leaves are institute-wide, so keep only this semester's students
      final stdSnap = await db.dbref
          .collection("ins_admins").doc(widget.insAdminId)
          .collection("institutes").doc(widget.instituteId)
          .collection("departments").doc(widget.departmentId)
          .collection("sessions").doc(widget.sessionId)
          .collection("semesters").doc(widget.semesterId)
          .collection("students")
          .get();
      final semesterIds = stdSnap.docs.map((d) => d.id).toSet();

      // MUST be sequential: each call rewrites the whole attendance array
      for (final id in _onLeave.where(semesterIds.contains)) {
        if (!mounted) return;
        await db.studentMarkLeave(context, widget.lecture, id, "auto", silent: true);
      }
      if (mounted) setState(() {}); // refresh cards + summary
    } catch (e) {
      print("auto mark leave error: $e");
    } finally {
      _autoMarking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
          title: Text("${widget.lecture.course}  ${DateFormat("dd MMM yyyy").format(widget.lecture.dated)}",style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColor,
          ),),
        ),
        body:Provider.of<DbService>(context,listen: false).loading?
        RMFuncts.loadingAnimation2(context):
        StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
            .collection("ins_admins").doc(widget.insAdminId)
            .collection("institutes").doc(widget.instituteId)
            .collection("departments").doc(widget.departmentId)
            .collection("sessions").doc(widget.sessionId)
            .collection("semesters").doc(widget.semesterId)
            .collection("students")
            .snapshots(),
            builder: (context,snapshot){
              if(snapshot.connectionState==ConnectionState.waiting){
                return RMFuncts.loadingAnimation(context);
              }else if(snapshot.hasError){
                return Center(child: Text(snapshot.error.toString()),);
              }else if(!snapshot.hasData){
                return Center(child: Text("No data found"),);
              }else if(snapshot.hasData){
                students.clear();
                for(var std in snapshot.data!.docs){
                  students.add(
                      Student(
                        id: std.id,
                        role: std['role'],
                        name: std['name'],
                        insAdminId: std['ins_admin_id'],
                        instituteId: std['institute_id'],
                        departId: std['department_id'],
                        sessionId: std['session_id'],
                        semesterId: std['semester_id'],
                        email: std['email'],
                        created_at: std['created_at'].toDate(),
                      )
                  );
                }
                final attd = widget.lecture.attendance ?? <Attendance>[];
                return students.isEmpty?Center(child: Text("no students found,Add first"),):
                ListView(
                  children: [
                    _PresentAbsentSummary(
                      present: getPresent(attd,students),
                      absent:getAbsent(attd,students),
                      late: getLate(attd,students),
                      onLeave: getOnLeave(attd,students),
                      total: students.length, date: widget.lecture.dated,
                      start: widget.lecture.start_time,
                      end: widget.lecture.end_time,
                    ),
                    MarkAttGroupFacial(lecture: widget.lecture,students: students,),
                    _finalizeSection(),
                    const SizedBox(height: 10,),
                    // attendance cards
                    for(var i=0;i<students.length;i++)
                    //student attendance card
                      _buildStudentAttendanceCard(context, students[i])
                  ],
                );
              }
              return SizedBox();
            })
    );
  }

  Widget _statusBadge(String? status) {
    if (status == "present") {
      return Badge(
        backgroundColor:Theme.of(context).primaryColor,
        label:  Padding(
          padding: const EdgeInsets.all(3.0),
          child: Text("Present", style: TextStyle(color: Colors.white)),
        ),
      );
    } else if (status == "late") {
      return Badge(
        backgroundColor: Colors.orange,
        label:  Padding(
          padding: const EdgeInsets.all(3.0),
          child: Text("Late", style: TextStyle(color: Colors.white)),
        ),
      );
    } else if (status == "absent") {
      return Badge(
        backgroundColor: Colors.red,
        label:  Padding(
          padding: const EdgeInsets.all(3.0),
          child: Text("Absent", style: TextStyle(color: Colors.white)),
        ),
      );
    }else if (status == "leave") {
      return Badge(
        backgroundColor: Colors.blue,
        label:  Padding(
          padding: const EdgeInsets.all(3.0),
          child: Text("on leave", style: TextStyle(color: Colors.white)),
        ),
      );
    } else {
      // no record yet
      return CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey.shade400,
        child: const Text("-", style: TextStyle(color: Colors.white)),
      );
    }
  }

  Widget? _attIcon(String? method) {
    if(method=="fingerprint"){
      return PhosphorIcon(PhosphorIconsBold.fingerprint,color: Theme.of(context).primaryColor,);
    }else if(method=="facial"){
      return PhosphorIcon(Icons.face,color: Theme.of(context).primaryColor,);
    }else{
      return Icon(PhosphorIconsBold.handTap,color: Theme.of(context).primaryColor,);
    }
  }

  int _count(List<Attendance> attd, String status) =>
      attd.where((a) => a.status == status).length;

  int getPresent(List<Attendance> attd,List<Student> students) => _count(attd, "present");
  int getAbsent(List<Attendance> attd,List<Student> students) => _count(attd, "absent");
  int getOnLeave(List<Attendance> attd,List<Student> students) => _count(attd, "leave");
  int getLate(List<Attendance> attd,List<Student> students) => _count(attd, "late");

  Widget _buildStudentAttendanceCard(BuildContext context, Student student) {
    final primaryColor = Theme.of(context).primaryColor;
    final record = widget.lecture.attendance
        ?.firstWhereOrNull((element) => element.sid == student.id);

    final bool isCheckedIn = record?.status == "present" || record?.status == "late";
    final bool hasMidPoint = record?.mid_point == true;
    final bool hasCheckout = record?.checkout != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top row
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.12),
                        radius: 22,
                        child: Icon(PhosphorIconsDuotone.student, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              RMFuncts.getSentenceCase(student.name),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.email,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(record?.status),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Colors.black12),
                  ),

                  // bottom section
                  if (isCheckedIn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // check-in
                        Expanded(
                          child: _buildStateTrackerItem(
                            context,
                            title: "Check-in",
                            valueOrWidget: Text(
                              record?.checkin?.format(context) ?? "--:--",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                            ),
                            icon: "assets/icons/checkin.png",
                            isImage: true,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // mid-point
                        Expanded(
                          child: _buildStateTrackerItem(
                            context,
                            title: "Mid-point",
                            valueOrWidget:hasMidPoint? Icon(
                              CupertinoIcons.checkmark_alt_circle_fill ,
                              color: hasMidPoint ? Colors.green : Colors.grey.shade400,
                              size: 20,
                            ):OutlinedButton(
                              onPressed: () {
                                Provider.of<DbService>(context, listen: false)
                                    .studentMidPoint(context, widget.lecture, student.id!,);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 26),
                                side: const BorderSide(color: Colors.red, width: 0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text("mid-point", style: TextStyle(fontSize: 10, color: Colors.red)),
                            ),
                            iconPhosphor: PhosphorIconsBold.target,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // check-out
                        Expanded(
                          child: _buildStateTrackerItem(
                            context,
                            title: "Check-out",
                            valueOrWidget: hasCheckout
                                ? Text(
                              record!.checkout!.format(context),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red),
                            )
                                : OutlinedButton(
                              onPressed: () {
                                Provider.of<DbService>(context, listen: false)
                                    .studentCheckOut(context, widget.lecture, student.id!, "manual");
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 26),
                                side: const BorderSide(color: Colors.red, width: 0.8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text("Out", style: TextStyle(fontSize: 10, color: Colors.red)),
                            ),
                            icon: "assets/icons/checkout.png",
                            isImage: true,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(),
                              Text(
                                "Method : ",
                                style: TextStyle(fontSize: 11,),
                              ),
                              SizedBox(width: 5,),
                              SizedBox(
                                height: 18,
                                child: _attIcon(record?.method),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: SizedBox())
                      ],
                    ),
                    SizedBox(height: 8,),
                  ] else if (record?.status == "leave") ...[
                    // leave already recorded
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: Center(
                        child: Text(
                          "Approved leave",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  ] else if (_onLeave.contains(student.id)) ...[
                    // on leave but not recorded yet (fallback if auto-mark failed)
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Provider.of<DbService>(context, listen: false)
                              .studentMarkLeave(context, widget.lecture, student.id!, "manual");
                          if (mounted) setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.event_available_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          "Confirm Leave",
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  ] else ...[
                    // not checked in
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<DbService>(context, listen: false)
                              .studentCheckIn(context, widget.lecture, student.id!, "manual");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.how_to_reg_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          "Mark Attendance",
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateTrackerItem(
      BuildContext context, {
        required String title,
        required Widget valueOrWidget,
        String? icon,
        IconData? iconPhosphor,
        bool isImage = false,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isImage && icon != null)
                Image.asset(icon, height: 14, width: 14)
              else if (iconPhosphor != null)
                Icon(iconPhosphor, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 24,
            child: Center(child: valueOrWidget),
          ),
        ],
      ),
    );
  }
}


// Finalize button with a colorful, continuously rotating border
class _RotatingBorderButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback? onPressed;

  const _RotatingBorderButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.busy = false,
  });

  @override
  State<_RotatingBorderButton> createState() => _RotatingBorderButtonState();
}

class _RotatingBorderButtonState extends State<_RotatingBorderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  static const _colors = [
    Colors.redAccent,
    Colors.orange,
    Colors.yellow,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.redAccent, // same as first so the sweep loops seamlessly
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      // inner button is built once and reused every frame
      child: Material(
        color: widget.color,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.busy
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      builder: (context, child) {//alert
        return Container(
          padding: const EdgeInsets.all(3), // border thickness
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: SweepGradient(
              colors: _colors,
              transform: GradientRotation(_c.value * 2 * math.pi),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}


class _PresentAbsentSummary extends StatelessWidget {
  final int present;
  final int absent;
  final int late;
  final int onLeave;
  final int total;
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final VoidCallback? onMark;

  const _PresentAbsentSummary({
    required this.present,
    required this.absent,
    required this.late,
    this.onLeave = 0,
    required this.total,
    required this.date,
    this.start,
    this.end,
    this.onMark,
  });

  // combine date + time
  DateTime? _at(TimeOfDay? t) =>
      t == null ? null : DateTime(date.year, date.month, date.day, t.hour, t.minute);

  // e.g. 1h 30m
  String _duration(DateTime s, DateTime e) {
    final d = e.difference(s);
    if (d.isNegative) return "--";
    final h = d.inHours, m = d.inMinutes % 60;
    if (h == 0) return "${m}m";
    return m == 0 ? "${h}h" : "${h}h ${m}m";
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final s = _at(start), e = _at(end);
    final now = DateTime.now();

    // lecture status
    String status = "Live";
    Color statusColor = Colors.greenAccent;
    if (s != null && now.isBefore(s)) {
      status = "Upcoming";
      statusColor = Colors.amberAccent;
    } else if (e != null && now.isAfter(e)) {
      status = "Ended";
      statusColor = Colors.white70;
    }

    // attended ratio
    final double ratio =
    total == 0 ? 0 : ((present + late) / total).clamp(0.0, 1.0);
    final int pending = (total - present - absent - late - onLeave).clamp(0, total);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // time header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primary.withOpacity(0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          DateFormat("EEE, dd MMM yyyy").format(date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: statusColor),
                            const SizedBox(width: 5),
                            Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _TimeBlock(
                        label: "Starts",
                        time: start?.format(context) ?? "--:--",
                      ),
                      // duration line
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              (s != null && e != null) ? _duration(s, e) : "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 6, color: Colors.white70),
                                Expanded(
                                  child: Container(
                                      height: 1.2,
                                      color: Colors.white38),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 10, color: Colors.white70),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _TimeBlock(
                        label: "Ends",
                        time: end?.format(context) ?? "--:--",
                        alignEnd: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),//pending

            // stats body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Attendance Overview",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${(ratio * 100).round()}% present",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: "Present",
                          value: present,
                          icon: CupertinoIcons.checkmark_alt_circle_fill,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          label: "Absent",
                          value: absent,
                          icon: CupertinoIcons.xmark_circle_fill,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          label: "Late",
                          value: late,
                          icon: CupertinoIcons.time_solid,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          label: "Leave",
                          value: onLeave,
                          icon: Icons.event_available_rounded,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 6, color: Colors.grey.shade200),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary, primary.withOpacity(0.7)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${present + late} of $total attended",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "$pending pending",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // mark button
                  if (onMark != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onMark,
                        icon: const Icon(Icons.playlist_add_check_circle,
                            color: Colors.white, size: 20),
                        label: const Text(
                          "Mark Attendance",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// time block
class _TimeBlock extends StatelessWidget {
  final String label;
  final String time;
  final bool alignEnd;

  const _TimeBlock({
    required this.label,
    required this.time,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class MarkAttGroupFacial extends StatelessWidget {
  final LectureModel lecture;
  final List<Student> students;
  const MarkAttGroupFacial({super.key, required this.lecture, required this.students});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue,
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(
            horizontal: 5,vertical: 10
        ),
        padding: EdgeInsets.symmetric(horizontal: 2,vertical: 3),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 3,
                    child: Column(//finalize
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mark Attendance Group",style: TextStyle(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 15),),
                        SizedBox(height: 5,),
                        Text("Use facial recognition to mark attendance",style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),),
                      ],
                    )),
                Expanded(child: Icon(PhosphorIconsDuotone.userFocus,color: Colors.white,size: 40,)),
              ],
            ),
            SizedBox(height: 15,),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child:ElevatedButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (_)=>GroupCheckInFace(lecture: lecture,students: students,)));
                        },
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              )
                          ),
                          backgroundColor: MaterialStateColor.resolveWith((states) => Colors.white),
                        ),
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.arrowRightToBracket,color: Colors.blue,),
                            SizedBox(width: 5,),
                            Text("Check In",style: TextStyle(color: Colors.blue),),
                          ],
                        )
                    )),
                Expanded(child: SizedBox(width: 10,)),
                Expanded(
                    flex: 2,
                    child:ElevatedButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (_)=>GroupCheckInFace(lecture: lecture,students: students,)));
                        },
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              )
                          ),
                          backgroundColor: MaterialStateColor.resolveWith((states) => Colors.white),
                        ),
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.arrowRightFromBracket,color: Colors.blue,),
                            SizedBox(width: 5,),
                            Text("Check Out",style: TextStyle(color: Colors.blue),),
                          ],
                        )
                    )),
              ],
            )
          ],
        ),
      ),
    );
  }
}