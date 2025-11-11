import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class CustomeLineChart extends StatelessWidget {
  final List<String> Months ;
  final List<double> StudentPersetage;

  const CustomeLineChart({super.key, required this.Months, required this.StudentPersetage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 20,),
            Text("Monthly Attendance ",textAlign: TextAlign.left,style: TextStyle(color: Theme.of(context).primaryColor,fontWeight: FontWeight.w700,fontSize: 14),),
          ],
        ),
        SizedBox(height: 10,),
        Container(
          height: 220,
          margin: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
            top: 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.shade400,
            //     spreadRadius: 5,
            //     blurRadius: 7,
            //     offset: Offset(2, 2), // changes position of shadow
            //
            //   ),
            //   BoxShadow(
            //     color: Colors.grey.shade400,
            //     spreadRadius: 5,
            //     blurRadius: 7,
            //     offset: Offset(-2, -2), // changes position of shadow
            //
            //   )
            // ],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey,width: 0.2,),

          ),

          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: LineChart(

              LineChartData(
                  borderData: FlBorderData(
                      show: true,
                      // only bottom  and left border
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        left: BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      )
                  ),
                  gridData: FlGridData(
                    show: false,
                    // drawHorizontalLine: true,
                    //   drawVerticalLine: true
                  ),
                  minX: 0,
                  minY: 0,
                  maxX:StudentPersetage.length-1,
                  maxY: 100,
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),

                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),

                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (v,meta){
                            return Text(Months[v.toInt()]);
                          }
                      ),
                      axisNameWidget:Text("Last ${StudentPersetage.length-1} Months"),

                    ),
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          minIncluded: true,
                          reservedSize:35,//
                          //reserved size is used to hide the title

                          interval: 25,
                        ),
                        axisNameWidget: Text("Attendence %")
                    ),

                  ),
                  lineBarsData: [
                    LineChartBarData(
                      color: Color.fromARGB(255, 0, 153, 136),
                        isCurved: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                              begin:AlignmentGeometry.topCenter,
                              end: AlignmentGeometry.bottomCenter,
                              colors:[
                                Color.fromARGB(120, 0, 153, 136),
                                Color.fromARGB(60, 0, 153, 136),

                              ]),
                        ),
                        spots: [
                          for(int i=0;i<StudentPersetage.length;i++)
                            FlSpot(i.toDouble(),StudentPersetage[i]),
                        ]
                    )
                  ]

              ),

            ),
          ),
          // child:,
        ),
      ],
    );
  }
}
