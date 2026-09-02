import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/services/db_service.dart';

class UpdateAdminPage extends StatefulWidget {
  final Admin admin;
  final InsAdmin insAdmin;
  final Institute institute;
  const UpdateAdminPage({
    super.key,
    required this.admin,
    required this.insAdmin,
    required this.institute,
  });

  @override
  State<UpdateAdminPage> createState() => _UpdateAdminPageState();
}

class _UpdateAdminPageState extends State<UpdateAdminPage> {
  final formKey = GlobalKey<FormState>();

  final List<String> duties = [
    "Timetable",
    "Announcements",
    "Leave_management",
    "student_management",
    "faculty_management",
    "department_management",
    "course_management",
    "session_management",
  ];

  final List<String> duty_detail = [
    "Scheduling lectures & labs",
    "Posting announcements",
    "Approving/Rejecting leave requests",
    "Adding/removing/Editing students records",
    "Managing faculty",
    "Adding/removing departments",
    "Adding/removing courses",
    "Adding/removing sessions & semesters",
  ];

  List<bool> checked = List.generate(8, (_) => false);
  List<String> assigned = [];

  @override
  void initState() {
    super.initState();
    // pre-fill switches from the admin's existing permissions
    assigned = List<String>.from(widget.admin.permissions ?? []);
    for (int i = 0; i < assigned.length; i++) {
      final idx = duties.indexOf(assigned[i]);
      if (idx != -1) checked[idx] = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget? getIcon(int i) {
    switch (i) {
      case 0:
        return Icon(PhosphorIconsBold.clock, color: Theme.of(context).primaryColor);
      case 1:
        return Icon(PhosphorIconsBold.speakerSimpleHigh, color: Theme.of(context).primaryColor);
      case 2:
        return Icon(PhosphorIconsBold.notepad, color: Theme.of(context).primaryColor);
      case 3:
        return Icon(Icons.person_add_alt_1, color: Theme.of(context).primaryColor);
      case 4:
        return Icon(Icons.person_add_alt, color: Theme.of(context).primaryColor);
      case 5:
        return Icon(PhosphorIconsBold.buildingApartment, color: Theme.of(context).primaryColor);
      case 6:
        return Icon(PhosphorIconsBold.books, color: Theme.of(context).primaryColor);
      case 7:
        return Icon(PhosphorIconsBold.desktop, color: Theme.of(context).primaryColor);
    }
    return null;
  }

  void _submit() {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("enter valid values")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Admin"),
        content: const Text("Are you sure to update the admin?"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () {
              assigned.clear();
              for (int i = 0; i < checked.length; i++) {
                if (checked[i]) assigned.add(duties[i]);
              }
              final updated = Admin(
                id: widget.admin.id,
                name: widget.admin.name,
                insAdminId: widget.insAdmin.id!,
                instituteId: widget.institute.id!,
                email: widget.admin.email,
                institute: widget.institute.name,
                role: "admin",
                status: "active",
                permissions: assigned,
              );
              Navigator.pop(context); // close confirm dialog
              Provider.of<DbService>(context, listen: false).updateAdmin(context, updated);
              Navigator.pop(context); // close page, back to ManageAdmins
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Admin")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text("Duties & Permissions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text("Select what admin is allowed to manage",
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 7),
                for (int i = 0; i < duties.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(1),
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                              child: getIcon(i),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(duties[i].split("_").join(" "),
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(duty_detail[i],
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: 40,
                            height: 35,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Switch(
                                activeThumbColor: Theme.of(context).primaryColor,
                                value: checked[i],
                                onChanged: (v) => setState(() => checked[i] = v),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                    ),
                    onPressed: _submit,
                    child: const Text("Update", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}