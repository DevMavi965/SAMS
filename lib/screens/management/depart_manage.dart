import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smas3/maxins/rm_functions.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class DepartManage extends StatefulWidget with RMFuncts {
  final InsAdmin insAdmin;
  final Institute institute;
  const DepartManage({super.key, required this.insAdmin, required this.institute});

  @override
  State<DepartManage> createState() => _DepartManageState();
}

class _DepartManageState extends State<DepartManage> {
  List<Department> departments = [];
  final TextEditingController name = TextEditingController();
  final TextEditingController hod = TextEditingController();
  final fkey = GlobalKey<FormState>();

  // Dispose
  @override
  void dispose() {
    name.dispose();
    hod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Manage Departments"),
        backgroundColor: primary,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: Provider.of<DbService>(context, listen: false)
            .dbref
            .collection("ins_admins")
            .doc(widget.insAdmin.id)
            .collection("institutes")
            .doc(widget.institute.id)
            .collection("departments")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          } else if (snapshot.data!.docs.isEmpty) {
            return _EmptyState(primary: primary);
          }
          departments.clear();
          for (var dep in snapshot.data!.docs) {
            departments.add(
              Department(
                id: dep.id,
                name: dep['name'],
                hod_name: dep['hod_name'],
                created_at: dep['created_at'].toDate(),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: departments.length,
            itemBuilder: (context, count) {
              return DepartmentCard(department: departments[count]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Department", style: TextStyle(color: Colors.white)),
        // Navigate
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DepartAdd(insAdmin: widget.insAdmin, institute: widget.institute),
            ),
          );
        },
      ),
    );
  }

  Widget DepartmentCard({required Department department}) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    RMFuncts.getFirstLetters(department.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(CupertinoIcons.person_crop_circle, color: Colors.grey.shade500, size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              department.hod_name,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, color: Colors.grey.shade400, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat("dd MMM yyyy").format(department.created_at!),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == "edit") {
                      _showEditSheet(department);
                    } else if (value == "delete") {
                      _confirmDelete(department);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: "edit",
                      child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text("Edit")]),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Delete", style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Confirm
  void _confirmDelete(Department department) async {
    final count = await getSessionCount(context, department.id!);
    if (count > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Cannot delete department with sessions"),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete, color: Colors.red, size: 33),
        title: const Text("Delete Department"),
        content: const Text("Are you sure you want to delete this department?"),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.grey.shade200),
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.black87)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<DbService>(context, listen: false).removeDepartment(context, department.id!);
              Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Edit
  void _showEditSheet(Department department) {
    name.text = department.name;
    hod.text = department.hod_name;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: fkey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),
              const Text("Edit Department", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  labelText: "Department Name",
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Department name is required" : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: hod,
                decoration: InputDecoration(
                  labelText: "HOD Name",
                  filled: true,
                  fillColor: const Color(0xFFF6F7FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.isEmpty) ? "HOD name is required" : null,
              ),
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (fkey.currentState!.validate()) {
                    department.name = name.text.trim();
                    department.hod_name = hod.text.trim();
                    Provider.of<DbService>(context, listen: false).updateDepartment(context, department);
                    name.clear();
                    hod.clear();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                  }
                },
                child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Count
  Future<int> getSessionCount(BuildContext context, String departmentId) async {
    try {
      final counter = await Provider.of<DbService>(context, listen: false)
          .dbref
          .collection("ins_admins")
          .doc(widget.insAdmin.id)
          .collection("institutes")
          .doc(widget.institute.id)
          .collection("departments")
          .doc(departmentId)
          .collection("sessions")
          .count()
          .get();
      return counter.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final Color primary;
  const _EmptyState({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.apartment_outlined, size: 64, color: primary.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text("No departments found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class DepartAdd extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const DepartAdd({super.key, required this.insAdmin, required this.institute});

  @override
  State<DepartAdd> createState() => _DepartAddState();
}

class _DepartAddState extends State<DepartAdd> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _hod = TextEditingController();
  bool _saving = false;

  // Dispose
  @override
  void dispose() {
    _name.dispose();
    _hod.dispose();
    super.dispose();
  }

  // Save
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Provider.of<DbService>(context, listen: false).addDepartment(
        context,
        widget.insAdmin.id!,
        widget.institute.id!,
        Department(
          name: _name.text.trim(),
          hod_name: _hod.text.trim(),
          created_at: DateTime.now(),
        ),
      );
      if (context.mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Add Department"),
        backgroundColor: primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Container(//
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withOpacity(0.1),
                  ),
                  child: Icon(Icons.add_business_outlined, color: primary, size: 40),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Department Name",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  hintText: "enter department name",
                  prefixIcon: const Icon(Icons.apartment_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "Department name is required" : null,
              ),
              const SizedBox(height: 20),
              const Text(
                "Head of Department",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hod,
                decoration: InputDecoration(
                  hintText: "enter hod name",
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? "HOD name is required" : null,
              ),
              const SizedBox(height: 36),
              // Submit
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                  )
                      : const Text("Add Department", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}