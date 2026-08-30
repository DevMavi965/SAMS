import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/Leave_Application_Model.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/services/db_service.dart';

class LeaveApplicationFormScreen extends StatefulWidget {
  final Student student;
  final LeaveApplication? existingLeave; // null = add mode, non-null = edit mode

  const LeaveApplicationFormScreen({
    super.key,
    required this.student,
    this.existingLeave,
  });

  bool get isEditing => existingLeave != null;

  @override
  State<LeaveApplicationFormScreen> createState() =>
      _LeaveApplicationFormScreenState();
}

class _LeaveApplicationFormScreenState
    extends State<LeaveApplicationFormScreen> {
  final formKey = GlobalKey<FormState>();
  final reasonCon = TextEditingController();

  final List<String> leaveTypes = ["Medical", "Personal", "Emergency", "Academic"];
  late String selectedType;
  DateTime? fromDate;
  DateTime? tillDate;
  String? fromDateError;
  String? tillDateError;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLeave;
    selectedType = existing?.type ?? "Personal";
    fromDate = existing?.fromDate;
    tillDate = existing?.tillDate;
    reasonCon.text = existing?.reason ?? "";
  }

  @override
  void dispose() {
    reasonCon.dispose();
    super.dispose();
  }

  bool _validateDates() {
    setState(() {
      fromDateError = fromDate == null ? "Please select start date" : null;
      tillDateError = tillDate == null ? "Please select end date" : null;
    });

    if (fromDate == null || tillDate ==  null) return false;
    if (fromDate!.isBefore(DateTime.now())) {
      setState(() => fromDateError = "Start date cannot be in the past");
      return false;
    }
    if (tillDate!.isBefore(fromDate!)) {
      setState(() => tillDateError = "End date cannot be before start date");
      return false;
    }
    return true;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? fromDate : tillDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
          fromDateError = null;
        } else {
          tillDate = picked;
          tillDateError = null;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate() || !_validateDates()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all the required fields"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => saving = true);
    final dbService = Provider.of<DbService>(context, listen: false);

    try {
      if (widget.isEditing) {
        final existing = widget.existingLeave!;
        final updated = LeaveApplication(
          type: selectedType,
          reason: reasonCon.text,
          fromDate: fromDate!,
          tillDate: tillDate!,
          status: existing.status,
          approvedby: existing.approvedby,
          appliedDate: existing.appliedDate,
          std_name: existing.std_name,
          std_id: existing.std_id,
        )..id = existing.id; // preserve doc id — adjust if your model
        // exposes `id` differently (e.g. via constructor)
        await dbService.updateStudentLeaveApplication(context, updated);
      } else {
        final newLeave = LeaveApplication(
          type: selectedType,
          reason: reasonCon.text,
          fromDate: fromDate!,
          tillDate: tillDate!,
          status: "pending",
          approvedby: null,
          appliedDate: DateTime.now(),
          std_name: widget.student.name,
          std_id: widget.student.id.toString(),
        );
        await dbService.addStudentLeaveApplication(
          context,
          widget.student.insAdminId,
          widget.student.instituteId,
          newLeave,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? "Edit Leave Application"
            : "New Leave Application"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Leave Type",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    items: leaveTypes
                        .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedType = value!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text("Start Date",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDate(isFrom: true),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: fromDateError != null
                            ? Colors.red
                            : Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fromDate != null
                            ? DateFormat('dd-MMM-yyyy').format(fromDate!)
                            : "Select start date",
                        style: TextStyle(
                            color: fromDate != null ? Colors.black : Colors.grey),
                      ),
                      Icon(Icons.calendar_today,
                          color: Theme.of(context).primaryColor, size: 20),
                    ],
                  ),
                ),
              ),
              if (fromDateError != null) ...[
                const SizedBox(height: 4),
                Text(fromDateError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 20),

              Text("End Date",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDate(isFrom: false),
                child: Container(
                  height: 50,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: tillDateError != null
                            ? Colors.red
                            : Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tillDate != null
                            ? DateFormat('dd-MMM-yyyy').format(tillDate!)
                            : "Select end date",
                        style: TextStyle(
                            color: tillDate != null ? Colors.black : Colors.grey),
                      ),
                      Icon(Icons.calendar_today,
                          color: Theme.of(context).primaryColor, size: 20),
                    ],
                  ),
                ),
              ),
              if (tillDateError != null) ...[
                const SizedBox(height: 4),
                Text(tillDateError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 20),

              Text("Reason",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              TextFormField(
                controller: reasonCon,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Please enter a reason";
                  if (v.length < 10) return "Reason must be at least 10 characters";
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Explain your reason for leave...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 1),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: saving ? null : _submit,
                  child: saving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    widget.isEditing
                        ? "Update Application"
                        : "Submit Application",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}