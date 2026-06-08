import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smas3/models/lecture.dart';
class UpcomingClassCard extends StatelessWidget {
  final LectureModel lectureModel;
  const UpcomingClassCard({super.key, required this.lectureModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 10,
        bottom: 5
      ),
      height: 130,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 1,
            color: Colors.grey.shade300,
          )
      ),
      child:
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(

              decoration: BoxDecoration(
                  color:Color.fromARGB(35, 0, 153, 136),
                  shape: BoxShape.circle
              ),
              child:
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(PhosphorIconsBold.calendarBlank,color: Theme.of(context).primaryColor,size: 35,),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 10,),
                Text(lectureModel.course!,style: TextStyle(fontSize: 15,fontWeight: FontWeight.w700),),
                SizedBox(height: 10,),
                //lecturaer
                Row(
                  children: [
                    Icon(Icons.person,color: Colors.grey,size: 14,),
                    SizedBox(width: 4,),
                    Text("dr ${lectureModel.course!}",style: TextStyle(fontSize: 13,color: Colors.grey,fontWeight: FontWeight.w600),),
                  ],
                ),
                SizedBox(height: 10,),
                lectureModel.status=="upcoming"?Text("upcoming",style: TextStyle(color: Colors.grey),)
                    :(lectureModel.status=="late"?Text("late",style: TextStyle(color: Colors.grey))
                    :(lectureModel.status=="present"?Text("present",style: TextStyle(color: Colors.grey))
                    :Text("absent",style: TextStyle(color: Colors.grey)))),

              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                lectureModel.status=="upcoming"?Icon(CupertinoIcons.clock,color: Colors.blue,size: 18,fontWeight: FontWeight.bold,)
                    :(lectureModel.status=="late"?Icon(CupertinoIcons.clock,color: Colors.brown,size: 18,fontWeight: FontWeight.bold,)
                    :(lectureModel.status=="present"?Icon(CupertinoIcons.check_mark_circled,color: Theme.of(context).primaryColor,size: 18,fontWeight: FontWeight.bold,)
                    :Icon(CupertinoIcons.xmark_circle,color: Colors.red.shade500,size: 18,fontWeight: FontWeight.bold,))),
                SizedBox(height: 8,),
                Row(
                  children: [
                    Icon(CupertinoIcons.clock,color: Colors.grey,size: 13,),
                    SizedBox(width: 3,),
                    Text("${lectureModel.start_time}-${lectureModel.end_time}",style: TextStyle(fontSize: 13,color: Colors.grey),),
                  ],
                ),
                SizedBox(height: 5,),
                OutlinedButton(
                    style: ButtonStyle(
                      fixedSize: MaterialStateProperty.all(Size(100, 30)),
                      minimumSize: MaterialStateProperty.all(Size(100, 30)),
                      padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),

                      )),
                      side: MaterialStateProperty.all(BorderSide(
                        color: Colors.grey.shade600,
                        width: 0.3,
                      )),
                    ),
                    onPressed: () {

                    }, child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.location_solid,color: Colors.grey,size: 13,),
                        SizedBox(width: 3,),
                        Text(lectureModel.room,style: TextStyle(fontSize: 11,color: Colors.grey),),
                      ],
                    ))

              ],
            )
          ],
        ),
      ),
    );
  }
}
