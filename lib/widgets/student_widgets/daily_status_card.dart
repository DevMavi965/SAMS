import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class StudentStatusCard extends StatelessWidget {
  final String status,checkin_time;
  final int streak;
  final double attendence_percentage;
  const StudentStatusCard({super.key, required this.status, required this.checkin_time, required this.streak, required this.attendence_percentage});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: status=="late"?Colors.brown:(status=="present"?Colors.green:Colors.red),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Status",style: TextStyle(fontWeight: FontWeight.w600,color: Colors.white),),
                Text("check-in",style: TextStyle(color: Colors.white),)
              ],
            ),
            SizedBox(height: 8,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(CupertinoIcons.clock,size: 25,color:Colors.white ,fontWeight: FontWeight.bold,),
                    SizedBox(width: 4,),
                    Text(status,style: TextStyle(fontSize:23,fontWeight: FontWeight.bold,color: Colors.white),),


                  ],
                ),
                Text(checkin_time,style: TextStyle(color: Colors.white),),

              ],
            ),
            SizedBox(height: 10,),
            Divider(thickness: 0.5,color: Colors.white,),
            SizedBox(height: 20,),
            Row(
              children: [
                Expanded(
                  child:
                  Row(
                    children: [
                       Icon(Icons.local_fire_department_outlined,color: Colors.orange.shade400,),
                      SizedBox(width: 7,),
                      Column(
                        children: [
                          const Text('Streak',style: TextStyle(color: Colors.white,fontSize:10),),
                          const SizedBox(height: 7,),
                          Text("$streak days",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 15)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 60,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Row(

                    children: [
                      Icon(CupertinoIcons.arrow_2_circlepath_circle,color: Colors.lightBlue.shade400,),
                      SizedBox(width: 7,),
                      Column(
                        children: [
                          Text('This Month',style: TextStyle(color: Colors.white,fontSize: 10)),
                          SizedBox(height: 7,),
                          Text("$attendence_percentage %",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w500,fontSize: 15),),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
