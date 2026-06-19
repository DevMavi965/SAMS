import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/session.dart';
import 'package:smas3/screens/management/create_update/Std_ses_mng.dart';
import 'package:smas3/screens/management/create_update/add_update_session.dart';

import '../../maxins/rm_functions.dart';
import '../../models/department.dart';
import '../../services/db_service.dart';

class Std_manage extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const Std_manage({super.key, required this.insAdmin, required this.institute});

  @override
  State<Std_manage> createState() => _Std_manageState();
}

class _Std_manageState extends State<Std_manage> {
  List<Department> departments=[];
  List<Session> sessions=[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Students"),
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
                  return DepartmentCard(department: departments[count],);
                });
          }),
    );
  }
  DepartmentCard({required Department department}){

    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>Std_Sessio_manage(insAdmin:widget.insAdmin,institute: widget.institute,department: department,)));
      },
      child: Card(
        color: Colors.white,
        child: Container(
          padding: EdgeInsets.only(
              top: 10,
              bottom: 15
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: 15,left: 5),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          width: 4
                      )
                  ),
                  child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      radius: 30,
                      child:Text(RMFuncts.getFirstLetters(department.name),style: TextStyle(color: Theme.of(context).primaryColor,fontWeight: FontWeight.w500),)
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(department.name,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                    SizedBox(height: 9,),
                    Row(
                      children: [
                        Text("HOD: ",style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w600),),
                        SizedBox(width: 5,),
                        Icon(CupertinoIcons.profile_circled,color: Colors.grey,size: 18,),
                        SizedBox(width: 2,),
                        Text(department.hod_name,style: TextStyle(color: Colors.grey),),
                      ],
                    ),
                    SizedBox(height: 9,),
                    Text("Created on: ${DateFormat("dd-MM-yyyy").format(department.created_at!)}",style: TextStyle(color: Colors.black54),)
                  ],
                ),
              ),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  StreamBuilder(stream: Provider.of<DbService>(context,listen: false).dbref
                      .collection("ins_admins").doc(widget.insAdmin.id)
                      .collection("institutes").doc(widget.institute.id)
                      .collection("departments").doc(department.id).collection("sessions").snapshots(), builder: (context,snapshot){
                    if(snapshot.connectionState==ConnectionState.waiting){
                      return Text("");
                    }else if(snapshot.hasError){
                      return Text(snapshot.error.toString());
                    }else if(!snapshot.hasData){
                      return Text(" ");
                    }else if(snapshot.data!.docs.isEmpty){
                      return Text(" ");
                    }else{
                      int sessionsCount=0;
                      for(var session in snapshot.data!.docs){
                        sessionsCount++;
                      }
                      return Badge(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.99),
                        label: Padding(
                            padding: EdgeInsetsGeometry.symmetric(horizontal: 5,vertical: 8),
                            child: Text("sessions $sessionsCount")),
                      );
                    }
                  }),


                ],
              ))
            ],
          ),
        ),
      ),
    );
  }
}
