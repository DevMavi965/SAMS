import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/screens/management/Course_session.dart';
import 'package:smas3/screens/management/create_update/add_update_session.dart';

import '../../maxins/rm_functions.dart';
import '../../models/department.dart';
import '../../services/db_service.dart';
import '../../widgets/insAdmin/dep_card.dart';

class CourseManage extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const CourseManage({super.key, required this.insAdmin, required this.institute});

  @override
  State<CourseManage> createState() => _CourseManageState();
}

class _CourseManageState extends State<CourseManage> {
  List<Department> departments=[];
  List<Session> sessions=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Department",style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
          .collection("ins_admins").doc(widget.insAdmin.id)
          .collection("institutes").doc(widget.institute.id)
          .collection("departments").snapshots(),
          builder: (context,snapshot){
            if(snapshot.connectionState==ConnectionState.waiting){
              return Center(child: CircularProgressIndicator(),);
            }else if(snapshot.hasError){
              return Center(child: Text(snapshot.error.toString()),);
            }else if(!snapshot.hasData){
              return Center(child: Text("No data found"),);
            }else if(snapshot.data!.docs.isEmpty){
              return Center(child: Text("No departments found"),);
            }
            departments.clear();
            for(var dep in snapshot.data!.docs){
              departments.add(
                  Department(
                      id: dep.id,
                      name: dep['name'],
                      hod_name: dep['hod_name'],
                      created_at: dep['created_at'].toDate()
                  )
              );
            }
            return ListView.builder(
                itemCount: departments.length,
                itemBuilder: (context,count){
                  return InkWell(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (_)=>CourseSession(insAdmin:widget.insAdmin,institute: widget.institute,department: departments[count],)));
                      },
                      child: DepartmentCard(department: departments[count],context: context));
                });
          }),
    );
  }
}
