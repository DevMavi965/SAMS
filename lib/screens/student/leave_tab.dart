import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/Leave_Application_Model.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/widgets/student_widgets/leave_Selection_card.dart';
import 'package:smas3/widgets/student_widgets/leave_acceptance_record.dart';
import 'package:intl/intl.dart';

class LeaveTab extends StatefulWidget {
  final Student student;
  final List<LeaveApplication> leaveApplications;
  const LeaveTab({super.key, required this.leaveApplications, required this.student});

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController reasonCon = TextEditingController();


  List<String> leaveTypes = ["Medical", "Personal", "Emergency", "Academic"];
  String selectedType = "Personal";
  DateTime? from_Date;
  DateTime? till_Date;
  String? fromDateError;
  String? tillDateError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    reasonCon.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      reasonCon.clear();
      from_Date = null;
      till_Date = null;
      selectedType = "Personal";
      fromDateError = null;
      tillDateError = null;
    });
  }

  bool _validateDates() {
    bool isValid = true;

    if (from_Date == null) {
      setState(() {
        fromDateError = "Please select start date";
      });
      isValid = false;
    } else {
      setState(() {
        fromDateError = null;
      });
    }

    if (till_Date == null) {
      setState(() {
        tillDateError = "Please select end date";
      });
      isValid = false;
    } else {
      setState(() {
        tillDateError = null;
      });
    }

    if (from_Date != null && till_Date != null && till_Date!.isBefore(from_Date!)) {
      setState(() {
        tillDateError = "End date cannot be before start date";
      });
      isValid = false;
    }

    return isValid;
  }

  void _submitApplication(BuildContext context) {
    if (formKey.currentState!.validate() && _validateDates()) {
      LeaveApplication newLeaveApplication = LeaveApplication(
        type: selectedType,
        reason: reasonCon.text,
        fromDate: DateFormat('dd-MMM-yyyy').format(from_Date!),
        tillDate: DateFormat('dd-MMM-yyyy').format(till_Date!),
        status: "pending",
        appliedDate: DateFormat('dd-MMM-yyyy').format(DateTime.now()), std_name:widget.student.name, std_id: widget.student.id.toString(),
      );
      setState(() {
        widget.leaveApplications.add(newLeaveApplication);
      });
      _resetForm();
      Navigator.pop(context);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all the required fields"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
      ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white),
      child: ListView(
        children: [
          SizedBox(
            height: 100,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Leave Applications",
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 7),
                    Text(
                      "Request time off from classes",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 10),
                    Transform.scale(
                      scale: 0.8,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return AlertDialog(
                                    icon: Icon(
                                      PhosphorIconsBold.calendarBlank,
                                      color: Theme.of(context).primaryColor,
                                      size: 40,
                                    ),
                                    title: SizedBox(
                                      width: 430,
                                      child: ListTile(
                                        title: Text(
                                          "New Leave Application",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Fill in the details for your leave request",
                                          style: TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    ),
                                    content: Form(
                                      key: formKey,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: [
                                          SizedBox(height: 10),

                                          // Leave Type
                                          Text(
                                            "Leave Type",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedType,
                                                isExpanded: true,
                                                items: leaveTypes.map((String type) {
                                                  return DropdownMenuItem<String>(
                                                    value: type,
                                                    child: Text(type),
                                                  );
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  setDialogState(() {
                                                    selectedType = newValue!;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 20),

                                          // Start Date
                                          Text(
                                            "Start Date",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          InkWell(
                                            onTap: () async {
                                              DateTime? selectedDate = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime.now().subtract(Duration(days: 365)),
                                                lastDate: DateTime.now().add(Duration(days: 365)),
                                              );
                                              if (selectedDate != null) {
                                                setDialogState(() {
                                                  from_Date = selectedDate;
                                                  fromDateError = null;
                                                });
                                              }
                                            },
                                            child: Container(
                                              height: 50,
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: fromDateError != null ? Colors.red : Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    from_Date != null
                                                        ? DateFormat('dd-MMM-yyyy').format(from_Date!)
                                                        : "Select start date",
                                                    style: TextStyle(
                                                      color: from_Date != null ? Colors.black : Colors.grey,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.calendar_today,
                                                    color: Theme.of(context).primaryColor,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (fromDateError != null) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              fromDateError!,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                          SizedBox(height: 20),

                                          // End Date
                                          Text(
                                            "End Date",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          InkWell(
                                            onTap: () async {
                                              DateTime? selectedDate = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime.now().subtract(Duration(days: 365)),
                                                lastDate: DateTime.now().add(Duration(days: 365)),
                                              );
                                              if (selectedDate != null) {
                                                setDialogState(() {
                                                  till_Date = selectedDate;
                                                  tillDateError = null;
                                                });
                                              }
                                            },
                                            child: Container(
                                              height: 50,
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: tillDateError != null ? Colors.red : Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    till_Date != null
                                                        ? DateFormat('dd-MMM-yyyy').format(till_Date!)
                                                        : "Select end date",
                                                    style: TextStyle(
                                                      color: till_Date != null ? Colors.black : Colors.grey,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.calendar_today,
                                                    color: Theme.of(context).primaryColor,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (tillDateError != null) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              tillDateError!,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                          SizedBox(height: 20),

                                          // Reason
                                          Text(
                                            "Reason",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          TextFormField(
                                            controller: reasonCon,
                                            maxLines: 4,
                                            validator: (v) {
                                              if (v!.isEmpty) {
                                                return "Please enter a reason";
                                              } else if (v.length < 10) {
                                                return "Reason must be at least 10 characters";
                                              }
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
                                                borderSide: BorderSide(
                                                  color: Theme.of(context).primaryColor,
                                                  width: 1,
                                                ),
                                              ),
                                              contentPadding: EdgeInsets.all(12),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.symmetric(vertical: 16),
                                            ),
                                            onPressed: () => _submitApplication(context),
                                            child: Text(
                                              "Submit Application",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        label: SizedBox(child: Text("Apply")),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          LeaveAcceptanceRecord(approved: 3, pending: 2, rejected: 1),
          SizedBox(height: 20),
          LeaveSelectionCard(leaveApplications: widget.leaveApplications),
        ],
      ),
    );
  }
}
