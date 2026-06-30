import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_card.dart';
import 'package:smas3/widgets/admin_widgets/admin_ann_grid.dart';
import 'package:smas3/widgets/insAdmin/insAdminAnnCard.dart';

import '../../models/ins_admin.dart';
import '../../models/institute.dart';
import '../../services/db_service.dart';

class AnnManage extends StatefulWidget {
  final InsAdmin insAdmin;
  final Institute institute;
  const AnnManage({super.key, required this.insAdmin, required this.institute});

  @override
  State<AnnManage> createState() => _AnnManageState();
}

class _AnnManageState extends State<AnnManage> {
  TextEditingController title=TextEditingController();
  TextEditingController message=TextEditingController();
 late TextEditingController title1=TextEditingController();
 late TextEditingController message1=TextEditingController();
  final _formKey=GlobalKey<FormState>();
  final _formKey1=GlobalKey<FormState>();
 String? selectedType,selectedTarget;
 String? selectedType1,selectedTarget1;
 List<String> types=["general","urgent","event"];
 List<String> targets=["students","staff","all_users"];
List<Announcement> announcements=[];
@override
  void dispose() {
  selectedTarget=selectedType=null;
  title.dispose();
  message.dispose();
  // TODO: implement dispose
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Announcements",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
      SafeArea(child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 5,
        ),
        child: StreamBuilder(stream:  Provider.of<DbService>(context, listen: false).dbref
            .collection("ins_admins")
            .doc(widget.insAdmin.id)
            .collection("institutes")
            .doc(widget.institute.id).collection("announcements").snapshots(),
            builder: (StreamContext,snapshot){
          if(snapshot.connectionState==ConnectionState.waiting){
            return Center(child: CircularProgressIndicator(),);
          }else if(snapshot.hasError){
            return Center(child: Text(snapshot.error.toString()),);
          }else if(!snapshot.hasData){
            return Center(child: Text("No data found"),);
          }else if(snapshot.hasData){
            if(snapshot.data!.docs.isEmpty){
              return Column(
                children: [
                  SizedBox(height: 20,),
                  AdminAnnGrid(total: 0, urgent:0, events: 0),
                  SizedBox(height: 15,),
                  Center(child: Text("New announcements will appear here...",style: TextStyle(color: Colors.grey),))
                  ]
              );
            }
            announcements.clear();
            for(var doc in snapshot.data!.docs){
              announcements.add(
                Announcement(
                  id: doc.id,
                  an_title: doc['title'],
                  an_message: doc['content'],
                  an_type: doc['type'],
                  target_aud: doc['target'],
                  created_at: doc['created_at'].toDate(),
                )
              );
            }
            int total=announcements.length;
            int urgent=announcements.where((element) => element.an_type=="urgent").length;
            int events=announcements.where((element) => element.an_type=="event").length;
            return ListView(
              children: [
                SizedBox(height: 20,),
                AdminAnnGrid(total: total, urgent:urgent, events: events),
                SizedBox(height: 15,),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: announcements.length,
                    itemBuilder: (tcontext,index)=>InkWell(
                      onTap: (){
                        title1.text=announcements[index].an_title;
                        message1.text=announcements[index].an_message;
                        selectedType1=announcements[index].an_type;
                        selectedTarget1=announcements[index].target_aud;

                        showModalBottomSheet(
                            showDragHandle: true,
                            backgroundColor: Colors.white,
                            isScrollControlled: true,
                            context: context, builder: (rcontext)=>SizedBox(
                          height: MediaQuery.of(context).size.height*0.70,
                          width: MediaQuery.of(context).size.width,
                          child: StatefulBuilder(builder: (context1,set)=>Container(
                            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),

                            child: Form(
                              key: _formKey1,
                              child: ListView(
                                  children: [
                                    const SizedBox(height: 20,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text("Update Announcement",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                                      ],
                                    ),
                                    const SizedBox(height: 10,),
                                    // title
                                    TextFormField(
                                      controller: title1,
                                      decoration: InputDecoration(
                                          label: Text("Title"),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          )
                                      ),
                                      validator: (v){
                                        if(v!.isEmpty){
                                          return "Title is required";
                                        }else if(v.length<4){
                                          return "Title is too short";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10,),
                                    // content
                                    TextFormField(
                                      controller: message1,
                                      decoration: InputDecoration(
                                          label: Text("content"),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          )
                                      ),
                                      validator: (v){
                                        if(v!.isEmpty){
                                          return "content is required";
                                        }else if(v.length<10){
                                          return "content is too short";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10,),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 7),
                                      child: DropdownButton(
                                          isExpanded: true,
                                          hint: Text("Select Type"),
                                          value: selectedType1,
                                          items: types.map((e)=>DropdownMenuItem(
                                              value: e,
                                              child: Text(e))).toList(),
                                          onChanged: (v){
                                            set(()=>selectedType1=v.toString());
                                          }
                                      ),
                                    ),
                                    const SizedBox(height: 10,),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7
                                      ),
                                      child: DropdownButton(
                                          isExpanded: true,
                                          hint: Text("Select Target Audience"),
                                          value: selectedTarget1,
                                          items: targets.map((e)=>DropdownMenuItem(
                                              value: e,
                                              child: Text(e))).toList(),
                                          onChanged: (v){
                                            set(()=>selectedTarget1=v.toString());
                                          }
                                      ),
                                    ),
                                    const SizedBox(height: 10,),
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: (){

                                          if(_formKey1.currentState!.validate()){
                                            if(selectedType1==null||selectedTarget1==null){
                                            }else{
                                              Announcement an1=Announcement(
                                                  id: announcements[index].id,
                                                  an_title: title1.text.trim(),
                                                  an_message: message1.text.trim(),
                                                  an_type: selectedType1!,
                                                  target_aud: selectedTarget1!,
                                                  created_at: announcements[index].created_at??DateTime.now()
                                              );
                                              Provider.of<DbService>(context,listen: false).updateAnnouncement(context,an1);

                                              Navigator.pop(context);
                                            }
                                          }else{
                                            Navigator.pop(context);
                                          }
                                          title.clear();
                                          message.clear();
                                          selectedType=selectedTarget=null;
                                        }, child: Text("Update",style: TextStyle(color: Colors.white),))

                                  ]
                              ),
                            ),
                          )),
                        ));

                      },
                        child: InsAdminAnnCard(adminAnnouncement: announcements[index]))),
              ],
            );
          }
          return SizedBox();
        }),
        
        // child: ListView(
        //   children: [
        //     SizedBox(height: 20,),
        //     AdminAnnGrid(total: 15, urgent:8, events: 7),
        //     SizedBox(height: 10,),
        //     for(int i=0;i<announcements.length;i++)
        //       AdminAnnCard(adminAnnouncement: announcements[i])
        //
        //   ],
        // ),
      )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        onPressed: (){
          final rootContext=context;
          showModalBottomSheet(
            showDragHandle: true,
            backgroundColor: Colors.white,
              isScrollControlled: true,
              context: context, builder: (rcontext)=>SizedBox(
            height: MediaQuery.of(context).size.height*0.70,
            width: MediaQuery.of(context).size.width,
            child: StatefulBuilder(builder: (context1,set)=>Container(
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),

              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                  const SizedBox(height: 20,),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("New Announcement",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
                      ],
                    ),
                  const SizedBox(height: 10,),
                  // title
                  TextFormField(
                    controller: title,
                    decoration: InputDecoration(
                      label: Text("Title"),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      )
                    ),
                    validator: (v){
                      if(v!.isEmpty){
                        return "Title is required";
                      }else if(v.length<4){
                        return "Title is too short";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10,),
                    // content
                  TextFormField(
                      controller: message,
                      decoration: InputDecoration(
                          label: Text("content"),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          )
                      ),
                      validator: (v){
                        if(v!.isEmpty){
                          return "content is required";
                        }else if(v.length<10){
                          return "content is too short";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: DropdownButton(
                      isExpanded: true,
                      hint: Text("Select Type"),
                      value: selectedType,
                        items: types.map((e)=>DropdownMenuItem(
                            value: e,
                            child: Text(e))).toList(),
                        onChanged: (v){
                        set(()=>selectedType=v.toString());
                         }
                    ),
                  ),
                    const SizedBox(height: 10,),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7
                      ),
                      child: DropdownButton(
                        isExpanded: true,
                        hint: Text("Select Target Audience"),
                          value: selectedTarget,
                          items: targets.map((e)=>DropdownMenuItem(
                              value: e,
                              child: Text(e))).toList(),
                          onChanged: (v){
                            set(()=>selectedTarget=v.toString());
                          }
                      ),
                    ),
                    const SizedBox(height: 10,),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (){

                    if(_formKey.currentState!.validate()){
                      if(selectedType==null||selectedTarget==null){
                        ScaffoldMessenger.of(rootContext).showSnackBar(SnackBar(content: Text("select type and target")));
                      }else{
                        Announcement an1=Announcement(
                            an_title: title.text.trim(),
                            an_message: message.text.trim(),
                            an_type: selectedType!,
                            target_aud: selectedTarget!,
                            created_at: DateTime.now()
                        );
                        Provider.of<DbService>(context,listen: false).addAnnouncement(context, widget.insAdmin.id!, widget.institute.id!,an1);

                        Navigator.pop(context);
                      }
                    }else{
                      Navigator.pop(context);
                      ScaffoldMessenger.of(rootContext).showSnackBar(SnackBar(content: Text("All fields are required")));
                    }
                    title.clear();
                    message.clear();
                    selectedType=selectedTarget=null;
                   }, child: Text("Submit",style: TextStyle(color: Colors.white),))

                  ]
                ),
              ),
            )),
          ));

        // Announcement ann=Announcement(
        //   id: "3456789",
        //   an_title: "Annual sports gala",
        //   an_message: "open for all sports",
        //   an_type: "event",
        //   target_aud: "all students",
        //   created_at: DateTime.now(),
        // );
        // Provider.of<DbService>(context,listen: false).addAnnouncement(context, widget.insAdmin.id!, widget.institute.id!,ann);
      },child: Icon(Icons.add,color: Colors.white,),),
    );
  }

}
