import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/department.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/screens/management/fac_manage.dart';

import '../../services/db_service.dart';
import '../../widgets/insAdmin/dep_card.dart';

class DepartSelect extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const DepartSelect({super.key, required this.insAdmin, required this.institute});

  @override
  State<DepartSelect> createState() => _DepartSelectState();
}

class _DepartSelectState extends State<DepartSelect> {
  List<Department> departments=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Department"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
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
                        Navigator.push(context, MaterialPageRoute(builder: (_)=>FacManage(insAdmin: widget.insAdmin, institute: widget.institute, department: departments[count])));
                      },
                      child: DepartmentCard(department: departments[count],));
                });
          }),
    );
  }
}
