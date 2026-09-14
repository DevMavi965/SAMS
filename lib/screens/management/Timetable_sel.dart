import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/semester.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/screens/management/TimeTable_mng.dart';

import '../../models/holidayModel.dart';
import '../../services/db_service.dart';

class TimetableSel extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const TimetableSel({super.key, required this.insAdmin, required this.institute});

  @override
  State<TimetableSel> createState() => _TimetableSelState();
}

class _TimetableSelState extends State<TimetableSel> {
  List<Department> departments=[];
  List<Session> sessions =[];
  List<Semester> semesters=[];
  String? depId,sessionId,semesterId;
  List<Holidaymodel> holidays=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Timetables",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10
        ),
        child: ListView(
          children: [
            SizedBox(height: 20,),
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
                      .collection("departments").snapshots() ,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return RMFuncts.loadingAnimation(context);
                    }else if(snapshot.hasError){
                      return Center(child: Text(snapshot.error.toString()),);
                    }else if(!snapshot.hasData){
                      return Center(child: Text("No data found"),);
                    }else if(snapshot.hasData){
                      if(snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Container(//Holiday added successfully
                              padding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
                              child: Card(child: Text("No department found,add department to continue"))),);
                      }
                      departments.clear();
                      for(var doc in snapshot.data!.docs){
                        departments.add(
                            Department(
                              id: doc.id,
                                name: doc['name'],
                                hod_name: doc['hod_name'],
                                created_at: doc['created_at'].toDate(),
                            )
                        );
                      }
                      return DropdownButton(
                          value: depId,
                          hint: Text("Select Department"),
                          isExpanded: true,
                          icon: Icon(PhosphorIconsBold.buildingApartment),
                          items: [
                            for(var dep in departments)
                              DropdownMenuItem(value: dep.id,child: Text(dep.name),),
                          ],
                          onChanged: (v){
                            setState(() {
                              depId=v;
                              sessionId=null;
                              semesterId=null;
                            });
                          });
                    }
                    return SizedBox();
                  }),
            ),
            SizedBox(height: 15,),
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
                      .collection("departments").doc(depId)
                      .collection("sessions")
                      .snapshots() ,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return RMFuncts.loadingAnimation(context);
                    }else if(snapshot.hasError){
                      return Center(child: Text(snapshot.error.toString()),);
                    }else if(!snapshot.hasData){
                      return Center(child: Text("No data found"),);
                    }else if(snapshot.hasData){
                      if(snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,vertical: 10
                          ),
                            child: Text("No session found,add session to continue"));
                      }
                      sessions.clear();
                      for(var session in snapshot.data!.docs){
                        sessions.add(
                            Session(
                              id: session.id,
                              name: session['name'],
                              start_date: session['start_date'].toDate(),
                              end_date: session['end_date'].toDate(), )
                        );

                      }
                      return DropdownButton(
                          value: sessionId,
                          hint: Text("Select Session"),
                          isExpanded: true,
                          icon: Icon(Icons.calendar_month_rounded),
                          items: [
                            for(var ses in sessions)
                              DropdownMenuItem(value: ses.id,child: Text(ses.name),),
                          ],
                          onChanged: (v){
                            setState(() {
                              sessionId=v;
                              semesterId=null;
                            });
                          });
                    }
                    return SizedBox();
                  }),
            ),
            SizedBox(height: 15,),
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
                      .collection("departments").doc(depId)
                      .collection("sessions").doc(sessionId)
                      .collection("semesters")
                      .snapshots() ,
                  builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return RMFuncts.loadingAnimation(context);
                    }else if(snapshot.hasError){
                      return Center(child: Text(snapshot.error.toString()),);
                    }else if(!snapshot.hasData){
                      return Center(child: Text("No data found"),);
                    }else if(snapshot.hasData){
                      if(snapshot.data!.docs.isEmpty) {
                        return Center(
                          child:
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white
                            ),
                              padding: EdgeInsets.all(5),
                              child: Container(
                                padding: EdgeInsets.all(5),
                                child: Row(
                                  children: [
                                    Text("No semester found,add semester to continue"),
                                  ],
                                ),
                              )),);
                      }
                      semesters.clear();
                      for(var sem in snapshot.data!.docs){
                        semesters.add(
                            Semester(
                                id: sem.id,
                                institute_id: sem['institute_id'],
                                ins_admin_id: sem["ins_admin_id"],
                                department_id: sem["department_id"],
                                session_id: sem["session_id"],
                                semester_no: sem["semester_no"],
                                start_date: sem["start_date"].toDate(),
                                end_date: sem["end_date"].toDate(),
                            )
                        );

                      }
                      return DropdownButton(
                          value: semesterId,
                          hint: Text("Select Semester"),
                          isExpanded: true,
                          icon: Icon(Icons.calendar_today_outlined),
                          items: [
                            for(var sem in semesters)
                              DropdownMenuItem(value: sem.id,child: Text(sem.semester_no.toString()),),
                          ],
                          onChanged: (v){
                            setState(() {
                              semesterId=v;
                            });
                          });
                    }
                    return SizedBox();
                  }),
            ),
            SizedBox(height: 25,),
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                ),
                onPressed: (){
              if(depId!=null && sessionId!=null && semesterId!=null){
                Department dep=departments.firstWhere((element) => element.id==depId);
                Session ses=sessions.firstWhere((element) => element.id==sessionId);
                Semester sem=semesters.firstWhere((element) => element.id==semesterId);
                 Navigator.push(context, MaterialPageRoute(builder: (_)=>TimetableMng(insAdmin: widget.insAdmin, institute: widget.institute, department: dep, session: ses, semester: sem,)));

              }else{
                setState(() {
                  depId=semesterId=sessionId=null;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("please select all fields"),));
              }
            }, child: Text("View Timetable",style: TextStyle(color: Colors.white),)),
            SizedBox(height: 15,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Holidays",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                ElevatedButton.icon(style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                ),onPressed: (){
                 Navigator.push(context, MaterialPageRoute(builder: (_)=>AddHoliday(insAdmin: widget.insAdmin, institute: widget.institute,)));
                }, label: Text("Add holiday",style: TextStyle(color: Colors.white,fontSize: 13),), icon: Icon(PhosphorIconsBold.plus,color: Colors.white,size: 16,),)
              ],
            ),
            SizedBox(height: 15,),
            Container(
              child: StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
                  .collection("ins_admins").doc(widget.insAdmin.id)
                  .collection("institutes").doc(widget.institute.id)
                  .collection("holidays")
                  .snapshots(), builder: (context,snapshot){
                if(snapshot.connectionState==ConnectionState.waiting){
                  return Center(child: CircularProgressIndicator(),);
                }else if(snapshot.hasError){
                  return Center(child: Text(snapshot.error.toString()),);
                }else if(!snapshot.hasData){
                  return Center(child: Text("No data found"),);
                }else if(snapshot.hasData){
                  if(snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 5,vertical: 5),
                          child: Card(child: Text("No holiday found,add holiday to continue"))),);
                  }else{
                    holidays.clear();
                    for(var h in snapshot.data!.docs){
                      holidays.add(
                          Holidaymodel(
                            id: h.id,
                            title: h["title"],
                            dated: h["dated"].toDate(),
                          )
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        for(var h in holidays)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.08),
                                    child: FaIcon(
                                      FontAwesomeIcons.solidCalendarXmark,
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        size: 8,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                h.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat("dd MMM yyyy").format(h.dated),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event,
                                            size: 10,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat("EEE").format(h.dated),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UpdateHolidayScreen(
                                            insAdmin: widget.insAdmin,
                                            institute: widget.institute,
                                            holiday: h,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: FaIcon(
                                      FontAwesomeIcons.edit,
                                      color: Theme.of(context).primaryColor.withOpacity(0.6),
                                      size: 16,
                                    ),
                                    splashRadius: 20,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // Add confirmation dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          title: const Text(
                                            "Delete Holiday",
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          content: Text(
                                            "Delete '${h.title}'? This action cannot be undone.",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text(
                                                "Cancel",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Provider.of<DbService>(
                                                  context,
                                                  listen: false,
                                                ).removeHolidays(
                                                  context,
                                                  widget.insAdmin.id!,
                                                  widget.institute.id!,
                                                  h,
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade300,
                                      size: 18,
                                    ),
                                    splashRadius: 20,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                }
                return SizedBox();
              }),
            ),
            SizedBox(height: 15,),
          ],
        ),
      ),
    );
  }
}

class AddHoliday extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;

  const AddHoliday({
    super.key,
    required this.insAdmin,
    required this.institute,
  });

  @override
  State<AddHoliday> createState() => _AddHolidayState();
}

class _AddHolidayState extends State<AddHoliday> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();

  DateTime? date;
  bool isSaving = false;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: "Select Holiday Date",
    );

    if (selectedDate != null) {
      setState(() {
        date = selectedDate;
      });
    }
  }

  Future<void> saveHoliday() async {
    // Validate title
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate date
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select holiday date"),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final String id =
      DateTime.now().millisecondsSinceEpoch.toString();

      final Holidaymodel holiday = Holidaymodel(
        id: id,
        title: titleController.text.trim(),
        dated: date!,
      );

      await Provider.of<DbService>(
        context,
        listen: false,
      ).addHolidays(
        context,
        widget.insAdmin.id!,
        widget.institute.id!,
        holiday,
      );

      if (!mounted) return;


      // Return to timetable screen.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add holiday: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Holiday",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: primaryColor,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // Header
                Row(
                  children: [
                    Icon(
                      Icons.event_available,
                      color: primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Holiday Details",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Holiday title
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "Holiday Title",
                    hintText: "e.g. Quaid-e-Azam Day",
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? "";

                    if (text.isEmpty) {
                      return "Please enter holiday title";
                    }

                    if (text.length < 3) {
                      return "Please enter a valid holiday title";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Date selection
                InkWell(
                  onTap: isSaving ? null : selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: date == null
                            ? Colors.grey.shade400
                            : primaryColor,
                        width: date == null ? 1 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: date == null
                              ? Colors.grey
                              : primaryColor,
                          size: 28,
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Holiday Date",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                date == null
                                    ? "Select holiday date"
                                    : DateFormat(
                                  "dd-MMM-yyyy",
                                ).format(date!),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: date == null
                                      ? Colors.grey.shade700
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          Icons.arrow_forward_ios,
                          size: 17,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // Save button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveHoliday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save),

                    label: Text(
                      isSaving
                          ? "Saving..."
                          : "Add Holiday",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Cancel button
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: primaryColor,
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//update holiday screen
class UpdateHolidayScreen extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Holidaymodel holiday;

  const UpdateHolidayScreen({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.holiday,
  });

  @override
  State<UpdateHolidayScreen> createState() => _UpdateHolidayScreenState();
}

class _UpdateHolidayScreenState extends State<UpdateHolidayScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;

  DateTime? selectedDate;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.holiday.title,
    );

    selectedDate = widget.holiday.dated;
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 365),
      ),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> updateHoliday() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a holiday date"),
        ),
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      final updatedHoliday = Holidaymodel(
        id: widget.holiday.id,
        title: titleController.text.trim(),
        dated: selectedDate!,
      );

      await Provider.of<DbService>(
        context,
        listen: false,
      ).updateHolidays(
        context,
        widget.insAdmin.id!,
        widget.institute.id!,
        updatedHoliday,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Holiday updated successfully"),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update holiday: $e"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Holiday",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Holiday title
                TextFormField(
                  controller: titleController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: "Holiday title",
                    hintText: "e.g. Quaid-e-Azam Day",
                    prefixIcon: const Icon(
                      Icons.event_note,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Please enter holiday title";
                    }

                    if (value.trim().length < 3) {
                      return "Please enter a valid holiday title";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Date selector
                InkWell(
                  onTap: isUpdating ? null : selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: primaryColor,
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Holiday date",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                selectedDate == null
                                    ? "Select date"
                                    : "${selectedDate!.day.toString().padLeft(2, '0')}-"
                                    "${selectedDate!.month.toString().padLeft(2, '0')}-"
                                    "${selectedDate!.year}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.arrow_drop_down,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Update button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                    isUpdating ? null : updateHoliday,
                    icon: isUpdating
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.update),
                    label: Text(
                      isUpdating
                          ? "Updating..."
                          : "Update Holiday",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: isUpdating
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
