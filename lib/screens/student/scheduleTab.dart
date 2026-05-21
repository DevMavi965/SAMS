import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/course.dart';

import '../../widgets/student_widgets/upcoming_class_card.dart';
class Scheduletab extends StatefulWidget {
  final List<LectureModel> lectures;
  const Scheduletab({super.key, required this.lectures});

  @override
  State<Scheduletab> createState() => _ScheduletabState();
}

class _ScheduletabState extends State<Scheduletab> {
  List<String> days = ["Mon","Tue","Wed","Thu","Fri"];
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(

        margin: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 20
        ),
        child: ListView(
          children: [
            Text("Class Schedule",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 20),),
            SizedBox(height: 3,),
            Text("Your Weekly timeTable",style: TextStyle(color: Colors.grey),),
            SizedBox(height: 20,),
            Container(
              padding: EdgeInsets.only(top: 9),
              height: 100,
              decoration: BoxDecoration(
               gradient: LinearGradient(colors: [
                 Theme.of(context).primaryColorDark,
                 Theme.of(context).primaryColor
               ],
               end: Alignment.topRight,
                 begin: Alignment.bottomLeft
               ),
                borderRadius: BorderRadius.circular(10),

              ),
              child: ListTile(
                title: Text("Today",style: TextStyle(color: Colors.white,fontSize: 15),),
                subtitle: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(DateFormat("dd MMMM, yyyy").format(DateTime.now()),style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500,color: Colors.white),),
                ),
                trailing: Icon(PhosphorIconsBold.calendarBlank,color: Colors.white70,size: 39,),
              ),
            ),
            SizedBox(height: 20,),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.shade300
                )
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for(int i=0;i<5;i++)
                   InkWell(
                     onTap: (){
                       setState(() {
                         selected=i;
                       });
                     },
                     child:  Container(
                       margin: EdgeInsets.all(3),
                       padding: EdgeInsets.symmetric(
                         horizontal: 15,
                         vertical: 5
                       ),
                       decoration: BoxDecoration(
                           color:selected==i?Theme.of(context).primaryColor.withOpacity(0.8): Colors.white,
                           borderRadius: BorderRadius.circular(15),
                           border: Border.all(
                               color:selected==i? Colors.grey.shade300:Colors.white
                           )
                       ),
                       child: Text(days[i],style: TextStyle(color: selected==i?Colors.white:Colors.black),),
                     ),
                   ),

                ],
              ),
              ),
            SizedBox(height: 20,),
            if(widget.lectures.isNotEmpty)
              for(var lecture in widget.lectures)
                // if(lecture.dated.weekday - 1 == selected)
                  UpcomingClassCard(lectureModel: lecture)
              // UpcomingClassCard(lectureModel: lecture,)

          ],
        ),
      ),
    );
  }
}
