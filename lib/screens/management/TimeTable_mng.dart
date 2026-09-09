import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/holidayModel.dart';
import 'package:smas3/screens/management/create_update/Daily_schedule.dart';

import '../../models/department.dart';
import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../models/semester.dart';
import '../../models/session.dart';
import '../../services/db_service.dart';
import 'Timetable_sel.dart';

class TimetableMng extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;
  final Semester semester;
  const TimetableMng({super.key, required this.insAdmin, required this.institute, required this.department, required this.session, required this.semester});

  @override
  State<TimetableMng> createState() => _TimetableMngState();
}
class _TimetableMngState extends State<TimetableMng> {
  late DateTime startDate=widget.semester.start_date;
  late DateTime endDate=widget.semester.end_date;

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
          horizontal: 5,vertical: 5
        ),
        child: ListView(
          children: [
            SizedBox(height: 10,),
            for(int i=0;i<get_activeDays(startDate, endDate);i++)
          startDate.add(Duration(days: i)).weekday!=DateTime.saturday && startDate.add(Duration(days: i)).weekday!=DateTime.sunday?
          InkWell(
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (_)=>DailySchedule(date: startDate.add(Duration(days: i),), insAdmin: widget.insAdmin, institute: widget.institute, department: widget.department, session: widget.session, semester: widget.semester,)));
              // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("you clicked on ${DateFormat("dd MMM yy").format(startDate.add(Duration(days: i)))}")));
            },
            child: Card(
               color: Colors.white,
               child: Container(
                 margin: EdgeInsets.symmetric(
                   horizontal: 5,vertical: 10
                 ),
                 child: Row(
                   children: [
                     Expanded(child: CircleAvatar(child: Icon(PhosphorIconsBold.chalkboardTeacher,size: 25,),)),
                     SizedBox(width: 5,),
                     Expanded(child: Text(DateFormat("dd MMM yy").format(startDate.add(Duration(days: i))))),
                     Expanded(flex:2,child: SizedBox()),
                     Expanded(flex:1,child: IconButton(onPressed: (){
                       showDialog(context: context, builder: (context)=>AlertDialog(
                         title: Text("Mark as Holiday"),
                         content: Text("Are you sure you want to mark this day as holiday?"),
                         actions: [
                           ElevatedButton(onPressed: (){
                             Navigator.push(context, MaterialPageRoute(builder: (_)=>AddHolidayByDate(insAdmin: widget.insAdmin, institute: widget.institute,  dateTime: startDate.add(Duration(days: i))),));

                           }, child: Text("Yes")),
                           ElevatedButton(onPressed: (){
                             Navigator.pop(context);
                           }, child: Text("No"))
                         ],
                       ));
                     }, icon: Icon(PhosphorIconsBold.calendarX))),
                   ],
                 ),
               ),
             ),
          ):
          SizedBox(),
          ],
        ),
      ),
    );
  }
  int get_activeDays(DateTime startDate,DateTime endDate){
    int days=0;
    while(startDate.isBefore(endDate)){
      if(startDate.weekday!=DateTime.saturday && startDate.weekday!=DateTime.sunday){
        days++;
      }
      startDate=startDate.add(Duration(days: 1));
    }
    return days;
  }
}
class AddHolidayByDate extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final DateTime dateTime;
  const AddHolidayByDate({
    super.key,
    required this.insAdmin,
    required this.institute, required this.dateTime,
  });

  @override
  State<AddHolidayByDate> createState() => _AddHolidayByDateState();
}

class _AddHolidayByDateState extends State<AddHolidayByDate> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();

  DateTime? date;
  bool isSaving = false;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }
@override
  void initState() {
  date=widget.dateTime;
    // TODO: implement initState
    super.initState();
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

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text("Holiday added successfully"),
      //   ),
      // );

      // Return to timetable screen.
      Navigator.pop(context);
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
                        width: 2,//
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