import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/admin_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/screens/ins_admin/update_admin.dart';
import 'package:smas3/services/db_service.dart';

import 'add_admin.dart';
class ManageAdmins extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const ManageAdmins({super.key, required this.insAdmin, required this.institute});

  @override
  State<ManageAdmins> createState() => _ManageAdminsState();
}

class _ManageAdminsState extends State<ManageAdmins> {
  List<Admin> admins = [];

  void _openAddAdminPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAdminPage(insAdmin: widget.insAdmin, institute: widget.institute),
      ),
    );
  }

  void _openUpdateAdminPage(Admin admin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateAdminPage(
          admin: admin,
          insAdmin: widget.insAdmin,
          institute: widget.institute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Text("Manage Admins", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 7),
          Text("Admin Management & Permissions",
              style: TextStyle(fontSize: 15, color: Colors.grey)),
          SizedBox(height: 20),
          StreamBuilder(
              stream: Provider.of<DbService>(context)
                  .dbref
                  .collection("ins_admins")
                  .doc(widget.insAdmin.id)
                  .collection("institutes")
                  .doc(widget.institute.id)
                  .collection("admins")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                        width: 70, height: 70, child: Lottie.asset("assets/anims/an1.json")),
                  );
                } else if (snapshot.hasData) {
                  admins.clear();
                  for (var admin in snapshot.data!.docs) {
                    Admin admin1 = Admin(
                      id: admin.id,
                      insAdminId: admin['ins_admin_id'],
                      instituteId: admin['institute_id'],
                      name: admin['name'],
                      email: admin['email'],
                      institute: admin['institute'],
                      role: admin['role'],
                      permissions: List<String>.from(admin['permissions']),
                      status: admin['status'],
                    );
                    admins.add(admin1);
                  }
                  if (admins.isEmpty) {
                    return Center(child: Text("No admins found"));
                  } else {
                    return Column(
                      children: [
                        for (int i = 0; i < admins.length; i++) ...[
                          AdminListCard(admins[i]),
                          SizedBox(height: 10)
                        ],
                        SizedBox(height: 20),
                      ],
                    );
                  }
                } else if (snapshot.hasError) {
                  return Center(child: Text("Something went wrong"));
                }
                return SizedBox();
              }),
          SizedBox(height: 10),
          ElevatedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: _openAddAdminPage,
            label: Text(
              "add admin",
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
            icon: Icon(Icons.person_add_alt_rounded, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget AdminListCard(Admin admin) {
    return InkWell(
      onDoubleTap: () => _openUpdateAdminPage(admin),
      child: Container(
        padding: EdgeInsets.only(left: 15, top: 12, bottom: 5, right: 12),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                offset: Offset(-1, -1), blurRadius: 2, color: Colors.grey.shade200),
            BoxShadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.grey.shade200)
          ],
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(70),
                  radius: 28,
                  child: Text(
                    getFirstLetters(admin.name),
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin.name, style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 3),
                    Text(admin.email, style: TextStyle(color: Colors.grey)),
                  ],
                ),
                SizedBox(),
                Badge(
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(240),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                      child: Text(admin.permissions == null
                          ? "no duties"
                          : (admin.permissions!.isEmpty
                          ? "no duties"
                          : "${admin.permissions!.length} duties")),
                    ))
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                for (int i = 0; i < admin.permissions!.length && i < 3; i++) ...[
                  Badge(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                        child: Text(
                          getFirstWord(admin.permissions![i]),
                          style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor),
                        ),
                      )),
                  SizedBox(width: 5)
                ],
                admin.permissions!.length > 3
                    ? Badge(
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                      child: Text(
                        "${admin.permissions!.length - 3} More",
                        style:
                        TextStyle(fontSize: 10, color: Theme.of(context).primaryColor),
                      ),
                    ))
                    : SizedBox()
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "created at : ${DateFormat("dd/MM/yyyy").format(admin.created_at)}",
                  style: TextStyle(color: Colors.grey),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text("Delete Admin"),
                          icon: Icon(Icons.delete,
                              size: 32, color: Theme.of(context).primaryColor),
                          content: Text("Are you sure you want to delete this admin?"),
                          actions: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child:
                              Text("No", style: TextStyle(color: Colors.white)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor),
                              onPressed: () {
                                setState(() {
                                  admins.remove(admin);
                                });
                                Provider.of<DbService>(context, listen: false)
                                    .removeAdmin(context, admin.id!);
                                Navigator.pop(context);
                              },
                              child:
                              Text("Yes", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ));
                  },
                  icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  String getFirstLetters(String name) {
    if (name.isEmpty) return '';
    List<String> words = name.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length == 1) {
      String singleWord = words[0];
      if (singleWord.length == 1) return singleWord.toUpperCase();
      return singleWord.substring(0, 2).toUpperCase();
    }
    return words.map((word) => word[0]).join().toUpperCase();
  }

  String getFirstWord(String s) {
    return s.split("_")[0];
  }
}