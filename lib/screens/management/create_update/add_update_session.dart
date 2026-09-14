import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/screens/management/create_update/semester_ops.dart';

import '../../../models/department.dart';
import '../../../services/db_service.dart';

class AddUpdateSession extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  const AddUpdateSession({super.key, required this.department, required this.insAdmin, required this.institute});

  @override
  State<AddUpdateSession> createState() => _AddUpdateSessionState();
}

class _AddUpdateSessionState extends State<AddUpdateSession> {
  List<Session> sessions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("${widget.department.name} Sessions"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: Provider.of<DbService>(context, listen: false).dbref
            .collection("ins_admins").doc(widget.insAdmin.id)
            .collection("institutes").doc(widget.institute.id)
            .collection("departments").doc(widget.department.id)
            .collection("sessions").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          } else if (snapshot.hasData) {
            sessions.clear();
            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No sessions found"));
            } else {
              for (var session in snapshot.data!.docs) {
                sessions.add(
                  Session(
                    id: session.id,
                    name: session['name'],
                    start_date: session['start_date'].toDate(),
                    end_date: session['end_date'].toDate(),
                  ),
                );
              }
              return ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, count) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SemesterOps(
                              insAdmin: widget.insAdmin,
                              institute: widget.institute,
                              department: widget.department,
                              session: sessions[count])));
                    },
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Row(
                          children: [
                            const SizedBox(width: 5),
                            Expanded(
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(1),
                                child: const Icon(Icons.school_outlined, color: Colors.white, size: 30),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sessions[count].name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          color: Theme.of(context).primaryColor)),
                                  const SizedBox(height: 10),
                                  Text(
                                      "Start Date: ${sessions[count].start_date.day}/${sessions[count].start_date.month}/${sessions[count].start_date.year}",
                                      style: TextStyle(color: Colors.black.withAlpha(130))),
                                  const SizedBox(height: 10),
                                  Text(
                                      "End Date: ${sessions[count].end_date.day}/${sessions[count].end_date.month}/${sessions[count].end_date.year}",
                                      style: TextStyle(color: Colors.black.withAlpha(130))),
                                  const SizedBox(height: 10),
                                  Text(
                                      "Duration: ${RMFuncts.getDuration(sessions[count].start_date, sessions[count].end_date)}",
                                      style: TextStyle(color: Colors.black.withAlpha(130))),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      int semesterCount = await getSemesterCount(context, sessions[count].id!);
                                      if (!context.mounted) return;
                                      if (semesterCount > 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                            content: Text("Cannot delete session with semesters"),
                                            backgroundColor: Colors.red));
                                      } else {
                                        showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor: Colors.white,
                                              icon: Icon(Icons.delete, color: Theme.of(context).primaryColor, size: 33),
                                              title: const Text("Delete Session"),
                                              content: const Text("Are you sure you want to delete this session?"),
                                              actions: [
                                                FilledButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                                                  ),
                                                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    Provider.of<DbService>(context, listen: false)
                                                        .removeSession(context, sessions[count].id!);
                                                  },
                                                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                                                  child: const Text("Yes", style: TextStyle(color: Colors.white)),
                                                )
                                              ],
                                            ));
                                      }
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  ),
                                  const SizedBox(height: 5),
                                  // update button — navigates to dedicated screen instead of a dialog
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UpdateSessionScreen(
                                            insAdmin: widget.insAdmin,
                                            institute: widget.institute,
                                            department: widget.department,
                                            session: sessions[count],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.edit_calendar, color: Theme.of(context).primaryColor),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          // navigates to a dedicated screen instead of a dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSessionScreen(
                insAdmin: widget.insAdmin,
                institute: widget.institute,
                department: widget.department,
                existingSessions: sessions,
              ),
            ),
          );
        },
        label: const Text("Add Session", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<int> getSemesterCount(BuildContext context, String sessionID) async {
    try {
      final counter = await Provider.of<DbService>(context, listen: false)
          .dbref
          .collection("ins_admins")
          .doc(widget.insAdmin.id)
          .collection("institutes")
          .doc(widget.institute.id)
          .collection("departments")
          .doc(widget.department.id)
          .collection("sessions")
          .doc(sessionID)
          .collection("semesters")
          .count()
          .get();

      return counter.count ?? 0;
    } catch (e) {
      // ignore: avoid_print
      print(e.toString());
      return 0;
    }
  }
}
//adding session yaha pr

class AddSessionScreen extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;// pasin the already-loaded sessions so we can block duplicate names
  // without re-querying Firestore
  final List<Session> existingSessions;

  const AddSessionScreen({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.existingSessions,
  });

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Add Session"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              PhosphorIconsDuotone.calendarHeart,
              color: Theme.of(context).primaryColor,
              size: 48,
            ),
            const SizedBox(height: 20),
            const Text("Start date", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _DatePickerRow(
              date: startDate,
              placeholder: "Select start date",
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 20),
            const Text("End date", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _DatePickerRow(
              date: endDate,
              placeholder: "Select end date",
              onTap: _pickEndDate,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                    ),
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Add", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 395 * 5));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 2));
    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      initialDate: DateTime.now(),
      lastDate: lastDate,
    );
    if (!context.mounted) return;
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 395));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 6));
    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      initialDate: DateTime.now().add(const Duration(days: 185)),
      lastDate: lastDate,
    );
    if (!context.mounted) return;
    if (picked != null) setState(() => endDate = picked);
  }

  void _submit() {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start and end date")),
      );
      return;
    }
    if (!startDate!.isBefore(endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start date must be before end date")),
      );
      return;
    }
    final durationDays = endDate!.difference(startDate!).inDays;
    if (durationDays < 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session must be at least 6 months long")),
      );
      return;
    }
    if (durationDays >= 365 * 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session must be at most 5 years long")),
      );
      return;
    }

    final name = _getDepartmentName(widget.department.name, startDate!, endDate!);
    if (widget.existingSessions.map((e) => e.name).contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session already exists")),
      );
      return;
    }

    setState(() => saving = true);

    Provider.of<DbService>(context, listen: false).addSession(
      context,
      widget.insAdmin.id!,
      widget.institute.id!,
      widget.department.id!,
      Session(name: name, start_date: startDate!, end_date: endDate!),
    );

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  String _getDepartmentName(String name, DateTime st, DateTime et) {
    String initial = RMFuncts.getFirstLetters(name);
    String year1 = st.year.toString();
    String year2 = et.year.toString();
    return "$initial$year1-${year2[2]}${year2[3]}".toUpperCase();
  }
}

class _DatePickerRow extends StatelessWidget {
  final DateTime? date;
  final String placeholder;
  final VoidCallback onTap;

  const _DatePickerRow({
    required this.date,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Text(
              date == null
                  ? placeholder
                  : DateFormat("dd/MM/yyyy").format(date!),
            ),
          ],
        ),
      ),
    );
  }
}

//update SesSion yaha

class UpdateSessionScreen extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  final Department department;
  final Session session;

  const UpdateSessionScreen({
    super.key,
    required this.insAdmin,
    required this.institute,
    required this.department,
    required this.session,
  });

  @override
  State<UpdateSessionScreen> createState() => _UpdateSessionScreenState();
}

class _UpdateSessionScreenState extends State<UpdateSessionScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    startDate = widget.session.start_date;
    endDate = widget.session.end_date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text("Update Session"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              PhosphorIconsDuotone.calendarHeart,
              color: Theme.of(context).primaryColor,
              size: 48,
            ),
            const SizedBox(height: 20),
            const Text("Start date", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _DatePickerRow(
              date: startDate,
              placeholder: "Select start date",
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 20),
            const Text("End date", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _DatePickerRow(
              date: endDate,
              placeholder: "Select end date",
              onTap: _pickEndDate,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                    ),
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Update", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 395 * 5));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 2));
    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      initialDate: startDate ?? DateTime.now(),
      lastDate: lastDate,
    );
    if (!context.mounted) return;
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final firstDate = DateTime.now().subtract(const Duration(days: 395));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 6));
    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      initialDate: endDate ?? DateTime.now().add(const Duration(days: 185)),
      lastDate: lastDate,
    );
    if (!context.mounted) return;
    if (picked != null) setState(() => endDate = picked);
  }

  void _submit() {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start and end date")),
      );
      return;
    }
    if (!startDate!.isBefore(endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start date must be before end date")),
      );
      return;
    }
    final durationDays = endDate!.difference(startDate!).inDays;
    if (durationDays <= 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session must be at least 6 months long")),
      );
      return;
    }
    if (durationDays > 365 * 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session must be at most 5 years long")),
      );
      return;
    }

    final name = _getDepartmentName(widget.department.name, startDate!, endDate!);

    setState(() => saving = true);

    Provider.of<DbService>(context, listen: false).updateSession(
      context,
      Session(
        id: widget.session.id,
        name: name,
        start_date: startDate!,
        end_date: endDate!,
      ),
    );

    if (!context.mounted) return;
    Navigator.pop(context);
  }

  String _getDepartmentName(String name, DateTime st, DateTime et) {
    String initial = RMFuncts.getFirstLetters(name);
    String year1 = st.year.toString();
    String year2 = et.year.toString();
    return "$initial$year1-${year2[2]}${year2[3]}".toUpperCase();
  }
}//navigator

