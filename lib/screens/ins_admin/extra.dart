import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';

import '../../services/db_service.dart';

class RegisterInsAdmin extends StatefulWidget {

  const RegisterInsAdmin({super.key,});

  @override
  State<RegisterInsAdmin> createState() => _RegisterInsAdminState();
}

class _RegisterInsAdminState extends State<RegisterInsAdmin> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { //w8 for build completion/ Check if widget is still mounted
        Provider.of<DbService>(context, listen: false).getData();
      }
    });
  }
  // signUpWithInsAdminEmail()async{
  //   setState(() {
  //     loading=true;
  //   });
  //   try{
  //     await eauth.signInWithEmailAndPassword(email: emailController.text.trim(),
  //         password: passwordController.text.trim()).then((v){
  //       if(eauth.currentUser!=null){
  //         InsAdmin insAdmin=Provider.of<DbService>(context,listen: false).ins_admins.firstWhere((element) => element.email==emailController.text.trim());
  //         print(insAdmin.name);
  //         Navigator.push(context, MaterialPageRoute(builder: (_)=>InsAdminDashboard(insAdmin: insAdmin,)));
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("successfully logging as institute admin"),backgroundColor: Theme.of(context).primaryColor,));
  //       }else{
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));
  //       }
  //     });
  //   }catch(e){
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));
  //   }finally{
  //     setState(() {
  //       loading=false;
  //     });
  //   }
  //
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register Institute Admin"),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(onPressed: (){
            // Provider.of<DbService>(context,listen: false).addFaculty(context, "PmqTC7uOWotY7KPCsw8D", "57kVzKCGMPKznustLOH1",);

          }, icon: Icon(Icons.add)),
          IconButton(onPressed: (){
            Provider.of<DbService>(context,listen: false).getData();
          }, icon: Icon(Icons.refresh)),
        ],
      ),
      body: Consumer<DbService>(
          builder: (context,provider,child) {
            return provider.loading?Center(child: CircularProgressIndicator(),):
            ListView(

              children: [
                Row(
                  children: [
                    Text("institutes"),
                  ],
                ),
                for(var insAdmin in provider.institutes)
                  ListTile(
                    title: Text("${insAdmin.name} :${insAdmin.id}"),
                    subtitle: Text(insAdmin.location["lat"].toString()),
                  ),
                Row(
                  children: [
                    Text("departments"),
                  ],
                ),
                for(var depart in provider.departments)
                  ListTile(
                    title: Text("${depart.name} : ${depart.id}"),
                    subtitle: Text(depart.hod_name.toString()),
                  ),
                Row(
                  children: [
                    Text("students"),
                  ],
                ),
                for(var ins in provider.students)
                  ListTile(
                    title: Text("${ins.name} : ${ins.id}"),
                    subtitle: Text(ins.email.toString()),
                    trailing: Text(ins.semester.toString()),
                    leading: Text(ins.depart.toString()),

                  ),
                for(var admin in provider.sessions)
                  ListTile(
                    title: Text("${admin.start_date} : ${admin.id}"),
                    subtitle: Text(admin.end_date.toString()),
                    trailing: Text(admin.getSession("Comp S").toString()),

                  )
              ],
            );
          }
      ),
      floatingActionButton: FloatingActionButton(onPressed: (){
        Provider.of<DbService>(context,listen: false).getInsAdmins();
      },child: Icon(Icons.person_add_alt_1_outlined),),
    );
  }
}
