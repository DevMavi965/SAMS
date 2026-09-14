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
  List<Student> students=[];
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
        RMFuncts.loadingAnimation(context):
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
                return students.isEmpty?Center(child: Text("no students found,Add first"),):
                ListView(
                  children: [
                    _PresentAbsentSummary(
                      present: getPresent(widget.lecture.attendance!,students),
                      absent:getAbsent(widget.lecture.attendance!,students),
                      late: getLate(widget.lecture.attendance!,students),
                      total: students.length,),
                    MarkAttGroupFacial(lecture: widget.lecture,students: students,),

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
      return CircleAvatar(
        radius: 12,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Text("P", style: TextStyle(color: Colors.white)),
      );
    } else if (status == "late") {
      return CircleAvatar(
        radius: 12,
        backgroundColor: Colors.orange,
        child: const Text("L", style: TextStyle(color: Colors.white)),
      );
    } else if (status == "absent") {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Colors.red,
        child: Text("A", style: TextStyle(color: Colors.white)),
      );
    } else {
      // no attendance record yet — student hasn't checked in
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

  getPresent(List<Attendance> attd,List<Student> students) {
    int count=0;
    for(var i=0;i<attd.length;i++){
      if(attd[i].status=="present"){
        count++;
      }
    }
    return count;
  }
  getAbsent(List<Attendance> attd,List<Student> students) {
    int count=0;
    for(var i=0;i<attd.length;i++){
      if(attd[i].status=="absent"){
        count++;
      }
    }
    return count;
  }
  getLate(List<Attendance> attd,List<Student> students) {
    int count=0;
    for(var i=0;i<attd.length;i++){
      if(attd[i].status=="late"){
        count++;
      }
    }
    return count;
  }
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
            onTap: () {
              // Tap to toggle mid-point quickly
              Provider.of<DbService>(context, listen: false)
                  .studentMidPoint(context, widget.lecture, student.id!);
            },
            onDoubleTap: () {
              // Double tap to quick-checkout
              Provider.of<DbService>(context, listen: false)
                  .studentCheckOut(context, widget.lecture, student.id!, "fingerprint");
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar, Info, Status Badge
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

                  // Bottom Section: Dynamic States or Interactive Action Controls
                  if (isCheckedIn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Check-in State//method
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
                        // Mid-Point State
                        Expanded(
                          child: _buildStateTrackerItem(
                            context,
                            title: "Mid-point",
                            valueOrWidget: Icon(
                              hasMidPoint ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.circle,
                              color: hasMidPoint ? Colors.green : Colors.grey.shade400,
                              size: 20,
                            ),
                            iconPhosphor: PhosphorIconsBold.target,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Check-out State
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
                            // mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  ] else ...[
                    // Not checked in yet: Show prominent mark attendance action
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


class _PresentAbsentSummary extends StatelessWidget {
  final int present;
  final int absent;
  final int late;
  final int total;
  final VoidCallback? onMark;

  const _PresentAbsentSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
    this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    // progress is present + late over total (both count as "attended")
    final double attendedRatio =
    total == 0 ? 0 : ((present + late) / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ─────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withOpacity(0.65)],
                  ),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Attendance Overview",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // attended-count pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${((attendedRatio) * 100).round()}% present",
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

          // ── stat tiles ─────────────────────────────────────────
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
            ],
          ),

          const SizedBox(height: 14),

          // ── progress bar ───────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 6, color: Colors.grey.shade200),
                FractionallySizedBox(
                  widthFactor: attendedRatio,
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
          const SizedBox(height: 6),
          Text(
            "${present + late} of $total students attended",
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.55),
              fontWeight: FontWeight.w500,
            ),
          ),

          // ── mark button ────────────────────────────────────────
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mark Attendance Group",style: TextStyle(fontWeight: FontWeight.w500,color: Colors.white,fontSize: 15),),
                        SizedBox(height: 5,),
                        Text("Use facial recognition to mark attendance",style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          // fontWeight: FontWeight.w400
                        ),),
                      ],
                    )),
                // Expanded(child: SizedBox(width: 10,)),
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
                          List<String> studentIds=[];
                          for(var i=0;i<students.length;i++){
                            studentIds.add(students[i].id!);
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (_)=>GroupCheckInFace(lecture: lecture,students: students,)));
                          // Provider.of<DbService>(context,listen: false).checkInGroup(context, lecture, studentIds,"facial");
                        },
                        style: ButtonStyle(
                          //radius
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              )
                          ),
                          backgroundColor: MaterialStateColor.resolveWith((states) => Colors.white),
                        ),
                        child: Row(
                          children: [//Check-in
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
                          List<String> studentIds=[];
                          for(var i=0;i<students.length;i++){
                            studentIds.add(students[i].id!);
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (_)=>GroupCheckInFace(lecture: lecture,students: students,)));
                        },
                        style: ButtonStyle(
                          //radius
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              )
                          ),
                          backgroundColor: MaterialStateColor.resolveWith((states) => Colors.white),
                        ),
                        child: Row(
                          children: [//progress
                            FaIcon(FontAwesomeIcons.arrowRightFromBracket,color: Colors.blue,),
                            SizedBox(width: 5,),
                            Text("check Out",style: TextStyle(color: Colors.blue),),
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