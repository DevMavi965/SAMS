import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smas3/widgets/fac_widgets/fac_custom_lineChart.dart';
import 'package:smas3/widgets/fac_widgets/fac_reports_grid.dart';
class FacReportsTab extends StatefulWidget {
  const FacReportsTab({super.key});

  @override
  State<FacReportsTab> createState() => _FacReportsTabState();
}

class _FacReportsTabState extends State<FacReportsTab> {
  List<String> opts=[
    "Weekly","Monthly","Course-wise"
  ];
  int selected_opt=0;
  @override
  Widget build(BuildContext context) {
    return SafeArea(child:
   selected_opt==0?
   ListView(
     children: [
       Text("Reports & Analytics",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
       SizedBox(height: 7,),
       Text("View detailed Attendance insights",style: TextStyle(fontSize: 15,color: Colors.grey),),
       SizedBox(height: 20,),
       // selector panel
       Container(
         margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
         padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
         decoration: BoxDecoration(
             color:Color(0xfff1f5f9) ,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(
                 color: Colors.grey.shade300,
                 width: 0.9
             )
         ),
         child: Row(
           children: [
             for(int i=0;i<opts.length;i++)
               Expanded(
                 child: InkWell(
                   onTap: (){
                     setState(() {
                       selected_opt=i;
                     });
                   },
                   child: Container(
                     margin: EdgeInsets.symmetric(vertical: 2),
                     decoration: BoxDecoration(
                         color:i==selected_opt? Colors.white:Colors.transparent,
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(
                             width:i==selected_opt? 0.1:0,
                             color: i==selected_opt? Colors.grey.shade200:Colors.transparent
                         )
                     ),

                     child: Padding(
                       padding: const EdgeInsets.all(4.0),
                       child: Text(opts[i],textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                     ),
                   ),
                 ),
               )
           ],
         ),
       ),
       SizedBox(height: 20,),
       FacReportsGrid(total_students: 175, lectures_this_week: 5, total_records: 498, avg_attendance: 89),
       SizedBox(height: 15,),
       // week overview bar graph
       Card(
         color: Colors.white,
         child: Padding(
           padding: EdgeInsets.symmetric(
               horizontal: 15,
               vertical: 15
           ),
           child: Column(
             children: [
               Row(
                 children: [
                   Text("This Week Overview",style: TextStyle(fontWeight: FontWeight.w400),textAlign: TextAlign.center,),
                 ],
               ),
               SizedBox(height: 17,),
               SizedBox(

                 height: 250,
                 child: BarChart(
                     BarChartData(
                       gridData: FlGridData(show: false),
                       borderData: FlBorderData(show: true,border: Border(
                         bottom: BorderSide(color: Colors.grey,width: 1),
                         left: BorderSide(color: Colors.grey,width: 0.5),
                       )),
                       backgroundColor: Colors.white,
                       titlesData: FlTitlesData(
                           rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                           topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                           bottomTitles: AxisTitles(
                               sideTitles: SideTitles(
                                   showTitles: true,
                                   getTitlesWidget: (v,meta){
                                     switch(v.toInt()){
                                       case 0:
                                         return Text("Mon");
                                       case 1:
                                         return Text("Tue");
                                       case 2:
                                         return Text("Wed");
                                       case 3:
                                         return Text("Thu");
                                       case 4:
                                         return Text("Fri");
                                       default:
                                         return Text("");
                                     }
                                   }
                               )
                           )
                       ),
                       barGroups: _getBarGroups(),
                     )
                 ),
               ),
             ],
           ),
         ),
       ),
       SizedBox(height: 15,),
       SizedBox(height: 15,),
       //   Pie chart distributiom
       SizedBox(
         height: 250,
         child: Card(
           color: Colors.white,
           child: Padding(
             padding: const EdgeInsets.symmetric(
                 horizontal: 10,
                 vertical: 15
             ),
             child: Column(
               children: [
                 Row(
                   children: [
                     SizedBox(width: 10,),
                     Text("Attendance Distribution",style: TextStyle(fontWeight: FontWeight.w600),textAlign: TextAlign.center,),
                   ],
                 ),
                 Expanded(
                   child: Row(
                     children: [
                       Expanded(
                         flex: 2,
                         child: Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: PieChart(
                               PieChartData(
                                   startDegreeOffset: 50,
                                   sections: [
                                     PieChartSectionData(
                                         showTitle: false,
                                         color: Theme.of(context).primaryColor.withAlpha(210),
                                         value: 428
                                     ),
                                     PieChartSectionData(
                                         showTitle: false,
                                         color: Colors.red.withAlpha(220),
                                         value: 45
                                     ),
                                     PieChartSectionData(
                                         showTitle: false,
                                         color: Colors.brown.withAlpha(230),
                                         value: 18
                                     ),
                                   ]
                               )
                           ),
                         ),
                       ),
                       Expanded(
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.end,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Icon(Icons.circle,color: Theme.of(context).primaryColor,size: 14,),
                                 SizedBox(width: 5,),
                                 Text("Present :428",style: TextStyle(fontSize: 14),),
                               ],
                             ),
                             Row(
                               children: [
                                 Icon(Icons.circle,color:Colors.red,size: 14,),
                                 SizedBox(width: 5,),
                                 Text("Absent :18",style: TextStyle(fontSize: 14),),
                               ],
                             ),
                             Row(
                               children: [
                                 Icon(Icons.circle,color: Colors.brown,size: 14,),
                                 SizedBox(width: 5,),
                                 Text("Late :45",style: TextStyle(fontSize: 14),),
                               ],
                             ),
                           ],
                         ),
                       )
                     ],
                   ),
                 )
               ],
             ),
           ),
         ),
       )
     ],
   )//weekly
       :(selected_opt==1?
   ListView(
      children: [
        Text("Reports & Analytics",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
        SizedBox(height: 7,),
        Text("View detailed Attendance insights",style: TextStyle(fontSize: 15,color: Colors.grey),),
        SizedBox(height: 20,),
        // selector panel
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
          padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
          decoration: BoxDecoration(
            color:Color(0xfff1f5f9) ,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 0.9
            )
          ),
          child: Row(
            children: [
              for(int i=0;i<opts.length;i++)
                Expanded(
                  child: InkWell(
                    onTap: (){
                      setState(() {
                        selected_opt=i;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color:i==selected_opt? Colors.white:Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          width:i==selected_opt? 0.1:0,
                          color: i==selected_opt? Colors.grey.shade200:Colors.transparent
                        )
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(opts[i],textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
        SizedBox(height: 20,),
        FacCustomLinechart(Months: ["Jan","Feb","Mar","Apr","May","Jun"], montly_attendance_percentage: [67,76,83,76,81,74]),


      ],
    ):
   ListView(//lecture-wise
     children: [
       Text("Reports & Analytics",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
       SizedBox(height: 7,),
       Text("View detailed Attendance insights",style: TextStyle(fontSize: 15,color: Colors.grey),),
       SizedBox(height: 20,),
       // selector panel
       Container(
         margin: EdgeInsets.symmetric(horizontal: 5,vertical: 7),
         padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
         decoration: BoxDecoration(
             color:Color(0xfff1f5f9) ,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(
                 color: Colors.grey.shade300,
                 width: 0.9
             )
         ),
         child: Row(
           children: [
             for(int i=0;i<opts.length;i++)
               Expanded(
                 child: InkWell(
                   onTap: (){
                     setState(() {
                       selected_opt=i;
                     });
                   },
                   child: Container(
                     margin: EdgeInsets.symmetric(vertical: 2),
                     decoration: BoxDecoration(
                         color:i==selected_opt? Colors.white:Colors.transparent,
                         borderRadius: BorderRadius.circular(10),
                         border: Border.all(
                             width:i==selected_opt? 0.1:0,
                             color: i==selected_opt? Colors.grey.shade200:Colors.transparent
                         )
                     ),

                     child: Padding(
                       padding: const EdgeInsets.all(4.0),
                       child: Text(opts[i],textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
                     ),
                   ),
                 ),
               )
           ],
         ),
       ),
       SizedBox(height: 20,),
       for(int i=0;i<5;i++)
       Card(
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
           child: Column(
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text("Course-Name"),
                   Badge(label: Text("87%"),backgroundColor: Theme.of(context).primaryColor,)
                 ],
               ),
               SizedBox(height: 7,),
               Row(
                 children: [
                   Text("45 students",style: TextStyle(color: Colors.grey),),
                 ],
               ),
               SizedBox(height: 30,),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text("Average Attendance",style: TextStyle(color: Colors.grey),),
                   Text("87%"),

                 ],
               ),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 2,vertical: 10),
                 child: LinearProgressIndicator(
                   borderRadius: BorderRadius.circular(3),
                   minHeight: 7,
                   value: 0.87,
                   color: Theme.of(context).primaryColor,
                 ),
               ),
               Row(children: [
                 Text("Last Class: 2 hours ago",style: TextStyle(color: Colors.grey),)
               ],),
               SizedBox(height: 20,),
               InkWell(
                 onTap: (){

                 },
                 child: Container(

                   padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                   decoration: BoxDecoration(
                     color: Color(0xfff1f5f9),
                     borderRadius: BorderRadius.circular(15),
                     border: Border.all(
                       color: Colors.grey.shade400,
                       width: 1
                     )
                   ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Padding(
                       padding: const EdgeInsets.all(4.0),
                       child: Text("View Details",style: TextStyle(fontWeight: FontWeight.w600),),
                     ),
                   ],
                 )),
               ),
             ],
           ),
         ),
       )
     ],
   )));//lecture-wise
  }

 _getBarGroups() {
    final _data = [
      [45,7,3],
      [56,6,3],
      [35,17,8],
      [44,9,0],
      [39,12,3],
    ];
   return  List.generate(_data.length, (index){
     return BarChartGroupData(x: index,

     barRods: [
       BarChartRodData(toY: _data[index][0].toDouble(),color: Colors.green,borderRadius: BorderRadius.circular(0),width: 10),
       BarChartRodData(toY: _data[index][1].toDouble(),color: Colors.red,borderRadius: BorderRadius.circular(0),width: 10),
       BarChartRodData(toY: _data[index][2].toDouble(),color: Colors.brown,borderRadius: BorderRadius.circular(0),width: 10),
     ]
     );
   });
  }
}
