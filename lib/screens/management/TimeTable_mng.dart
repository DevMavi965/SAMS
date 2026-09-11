import 'package:cloud_firestore/cloud_firestore.dart';
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

  const TimetableMng({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.session,
    required this.semester,
  });

  @override
  State<TimetableMng> createState() => _TimetableMngState();
}

class _TimetableMngState extends State<TimetableMng> {
  late DateTime startDate = widget.semester.start_date;
  late DateTime endDate = widget.semester.end_date;
  List<Holidaymodel> holidays = [];
  bool loadingHolidays = true;

  // Cache active-day / holiday lookups so build() isn't recomputing +
  // calling setState mid-build on every rebuild (was happening inside
  // isAholiday()).
  late final Set<DateTime> _holidayDates = {};

  @override
  void initState() {
    super.initState();
    getHolidays(widget.insAdmin.id!, widget.institute.id!);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Timetables", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
      ),
      body: loadingHolidays
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () =>
            getHolidays(widget.insAdmin.id!, widget.institute.id!),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: get_activeDays(startDate, endDate),
          itemBuilder: (context, i) {
            final date = startDate.add(Duration(days: i));

            // Skip weekends and holidays without ever calling
            // setState() from inside a build/list callback.
            if (date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday ||
                _isHoliday(date)) {
              return const SizedBox.shrink();
            }

            return _DayCard(
              date: date,
              accentColor: primaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailySchedule(
                    date: date,
                    insAdmin: widget.insAdmin,
                    institute: widget.institute,
                    department: widget.department,
                    session: widget.session,
                    semester: widget.semester,
                  ),
                ),
              ),
              onMarkHoliday: () => _confirmMarkHoliday(date),
            );
          },
        ),
      ),
    );
  }

  int get_activeDays(DateTime start, DateTime end) {
    int days = 0;
    var d = start;
    while (d.isBefore(end)) {
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        days++;
      }
      d = d.add(const Duration(days: 1));
    }
    return days;
  }

  Future<void> getHolidays(String insAdminId, String instituteId) async {
    try {
      final holidocs = await Provider.of<DbService>(context, listen: false)
          .dbref
          .collection("ins_admins")
          .doc(insAdminId)
          .collection("institutes")
          .doc(instituteId)
          .collection("holidays")
          .get();

      final loaded = holidocs.docs
          .map((h) => Holidaymodel(
        id: h.id,
        title: h["title"],
        dated: (h["dated"] as Timestamp).toDate(),
      ))
          .toList();

      if (!mounted) return;
      setState(() {
        holidays = loaded;
        _holidayDates
          ..clear()
          ..addAll(loaded.map((h) => DateTime(h.dated.year, h.dated.month, h.dated.day)));
        loadingHolidays = false;
      });
    } catch (e) {
      debugPrint("getHolidays failed: $e");
      if (mounted) setState(() => loadingHolidays = false);
    }
  }

  bool _isHoliday(DateTime date) {
    return _holidayDates.contains(DateTime(date.year, date.month, date.day));
  }

  Future<bool> containsLectures(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final lecturesDocs = await Provider.of<DbService>(context, listen: false)
        .indexDoc
        .where("ins_admin_id", isEqualTo: widget.insAdmin.id)
        .where("institute_id", isEqualTo: widget.institute.id)
        .where("dated", isEqualTo: Timestamp.fromDate(dateOnly))
        .get();
    return lecturesDocs.docs.isNotEmpty;
  }

  Future<void> _confirmMarkHoliday(DateTime date) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        // StatefulBuilder so the "Yes" button can show a spinner and
        // disable itself while containsLectures() is in flight, instead
        // of sitting there with no feedback (the thing that made this
        // feel slow / made people tap it twice).
        bool checking = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Mark as Holiday"),
              content: const Text(
                  "Are you sure you want to mark this day as holiday?"),
              actions: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                  ),
                  onPressed: checking
                      ? null
                      : () async {
                    setDialogState(() => checking = true);
                    final hasLectures = await containsLectures(date);
                    if (!mounted) return;

                    if (hasLectures) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Has lectures scheduled, can't be declared a holiday"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddHolidayByDate(
                          insAdmin: widget.insAdmin,
                          institute: widget.institute,
                          dateTime: date,
                        ),
                      ),
                    );
                  },
                  child: checking
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Yes", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all(Theme.of(context).primaryColor),
                  ),
                  onPressed:
                  checking ? null : () => Navigator.pop(dialogContext),
                  child: const Text("No", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A single day row in the timetable list.
class _DayCard extends StatelessWidget {
  final DateTime date;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onMarkHoliday;

  const _DayCard({
    required this.date,
    required this.accentColor,
    required this.onTap,
    required this.onMarkHoliday,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday ? accentColor.withOpacity(0.5) : const Color(0xFFEDEEF2),
                width: isToday ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Date badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat("MMM").format(date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat("d").format(date),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Weekday + icon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat("EEEE").format(date),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2233),
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "TODAY",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(PhosphorIconsBold.chalkboardTeacher,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            "Tap to view schedule",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Mark holiday action
                Material(
                  color: Colors.red.withOpacity(0.08),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: "Mark as holiday",
                    onPressed: onMarkHoliday,
                    icon: Icon(PhosphorIconsBold.calendarX,
                        color: Colors.red.shade400, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class AddHolidayByDate extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final DateTime dateTime;

  const AddHolidayByDate({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.dateTime,
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
  void initState() {
    super.initState();
    date = widget.dateTime;
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: "Select Holiday Date",
    );
    if (selectedDate != null) {
      setState(() => date = selectedDate);
    }
  }

  Future<void> saveHoliday() async {
    if (!_formKey.currentState!.validate()) return;

    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select holiday date")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Deterministic, date-based doc id (yyyyMMdd) lets DbService do a
      // single cheap point-read for the duplicate check instead of a
      // filtered query, and makes the duplicate-check + write safe to
      // run as one transaction.
      final String id = DateFormat('yyyyMMdd').format(date!);

      final holiday = Holidaymodel(
        id: id,
        title: titleController.text.trim(),
        dated: date!,
      );

      final error = await Provider.of<DbService>(context, listen: false)
          .addHolidays(context,widget.insAdmin.id!, widget.institute.id!, holiday);

      if (!mounted) return;

      // if (error != null) {//navigator
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(error), backgroundColor: Colors.red),
      //   );
      //   return; // don't pop — nothing was saved
      // }

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add holiday: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Holiday", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
                Row(
                  children: [
                    Icon(Icons.event_available, color: primaryColor, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      "Holiday Details",
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: "Holiday Title",
                    hintText: "e.g. Quaid-e-Azam Day",
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? "";
                    if (text.isEmpty) return "Please enter holiday title";
                    if (text.length < 3) return "Please enter a valid holiday title";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: date == null ? Colors.grey.shade400 : primaryColor,
                        width: date == null ? 1 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: date == null ? Colors.grey : primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Holiday Date",
                                  style: TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 5),
                              Text(
                                date == null
                                    ? "Select holiday date"
                                    : DateFormat("dd-MMM-yyyy").format(date!),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: date == null ? Colors.grey.shade700 : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 17, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveHoliday,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.save),
                    label: Text(
                      isSaving ? "Saving..." : "Add Holiday",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: primaryColor),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w500),
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