import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/Lecture_model.dart';
import 'package:smas3/models/fac_Lecture_model.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/widgets/fac_widgets/fac_class_card.dart';
import 'package:smas3/widgets/fac_widgets/fac_home_grid.dart';
class FacHomeTab extends StatefulWidget {
  final Lecturer lecturer;
  const FacHomeTab({super.key, required this.lecturer});

  @override
  State<FacHomeTab> createState() => _FacHomeTabState();
}

class _FacHomeTabState extends State<FacHomeTab> {
  List<Lecture> lectures=[
    Lecture(
        course: Course(name: "DSA", lecturer:"Dr Abdulallah", room:"13C", time: DateTime.now(), status: "upcoming"),
        total_std:50,
        absent_std:2,
        late_std: 2,
        present_std: 48,
        status: "upcoming"),
    Lecture(
        course: Course(name: "DSA", lecturer:"Mrs Aina", room:"13C", time: DateTime.now(), status: "upcoming"),
        total_std:50,
        absent_std:2,
        late_std: 2,
        present_std: 48,
        status: "upcoming"),
    Lecture(
        course: Course(name: "DSA", lecturer:"Dr Asif", room:"13C", time: DateTime.now(), status: "upcoming"),
        total_std:50,
        absent_std:2,
        late_std: 2,
        present_std: 48,
        status: "completed"),

  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
    ListView(
      children: [
        Text("Welcome ${widget.lecturer.name}!",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
        SizedBox(height: 7,),
        Text("Manage Your Classes and Attendance",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        FacHomeGrid(total: 210, present: 183, pending_classes: 3, avg_attendance: 81.3),
        SizedBox(height: 10,),
        _MarkAttendanceCard(context),
        SizedBox(height: 25,),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's classes",style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500),),
           Container(
             padding: EdgeInsets.all(6),
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(14),
               border: Border.all(
                 width: 0.5,
                 color: Colors.grey
               )
             ),
             child: Text("3 classes",style: TextStyle(fontSize: 11,fontWeight: FontWeight.w700),),
           )
          ],
        ),
        SizedBox(height: 7,),
        //classes (completed or pending)
        for(int i=0;i<lectures.length;i++)
          FacClassCard(lecture:lectures[i]),
        SizedBox(height: 15,),
        Container(
           padding: EdgeInsets.all(13),
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 0.5,
              color: Colors.grey
            )
          ),
          child: Column(
            children: [
              Text("${widget.lecturer.deprt}-This Week",style: TextStyle(fontSize: 17,fontWeight: FontWeight.w400),),
              SizedBox(height: 25,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("classes conducted"),
                  Text("12/15")
                ],
              ),
              SizedBox(height: 5,),
              LinearProgressIndicator(
                value: 12/15,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                minHeight: 7,
                borderRadius: BorderRadius.circular(10),

              ),
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Avg Attendance"),
                  Text("87%")
                ],
              ),
              SizedBox(height: 5,),
              LinearProgressIndicator(
                value: 0.87,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                minHeight: 7,
                borderRadius: BorderRadius.circular(10),

              ),
              SizedBox(height: 7,),
              Divider(
                thickness: 0.5,
                color: Colors.grey,
              ),
              SizedBox(height: 7,),
              Flex(direction: Axis.horizontal,
                children: [
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(CupertinoIcons.check_mark_circled,color: Theme.of(context).primaryColor,size: 30,),
                      Text("421",style: TextStyle(fontWeight: FontWeight.w600,),),
                      Text("Present",style: TextStyle(color: Colors.grey),)
                    ],
                  )),
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(CupertinoIcons.clock,color: Colors.brown,size: 30,),
                      Text("43",style: TextStyle(fontWeight: FontWeight.w600,),),
                      Text("Late",style: TextStyle(color: Colors.grey),)
                    ],
                  )),
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(CupertinoIcons.xmark_circle,color: Colors.red,size: 30,),
                      Text("24",style: TextStyle(fontWeight: FontWeight.w600,),),
                      Text("Absent",style: TextStyle(color: Colors.grey),)
                    ],
                  ))
                ],
              )

            ],
          ),
        )
      ],
    ));
  }
  Widget _MarkAttendanceCard(BuildContext context){
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 10
      ),
      height: 140,
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ListTile(
            title: Text("Mark Attendance",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400,color: Colors.white),),
            subtitle: Text("Use Facial recognition or QR Code",style: TextStyle(fontSize: 13,color: Colors.white),),
            trailing: Icon(Icons.filter_center_focus,color: Colors.white60,size: 48,),
          ),
          ElevatedButton(

              style: ElevatedButton.styleFrom(
                  fixedSize: Size(MediaQuery.of(context).size.width, 40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  )
              )

              ,onPressed:(){
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Attendance Marked"),
                  duration: Duration(seconds: 1),
                  backgroundColor: Theme.of(context).primaryColor,));
          },
              child: Text("Mark Attendance",style: TextStyle(color: Theme.of(context).primaryColor))
          ),
        ],
      ),
    );
  }
}
