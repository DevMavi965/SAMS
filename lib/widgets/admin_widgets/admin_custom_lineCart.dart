import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class AdminCustomLinechart extends StatelessWidget {
  final List<String> days ;
  final List<double> daily_attendance_percentage;

  const AdminCustomLinechart({super.key, required this.days, required this.daily_attendance_percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Card(
        child: Column(
          children: [
            SizedBox(height: 10,),
            Row(
              children: [
                SizedBox(width: 20,),
                Text("Weekly Attendance Trend",textAlign: TextAlign.left,style: TextStyle(color: Colors.black,fontWeight: FontWeight.w400,fontSize: 14),),
              ],
            ),
            SizedBox(height: 15,),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20,vertical: 15),
                child: LineChart(

                  LineChartData(
                      minY: 0,
                      maxY: 100,
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
                                return Text(days[v.toInt()]);
                              }
                          ),
                          // axisNameWidget:Text("Last ${daily_attendance_percentage.length-1} days"),

                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            minIncluded: true,
                            reservedSize:35,//
                            //reserved size is used to hide the title

                            interval: 25,
                          ),
                          // axisNameWidget: Text("Attendence %")
                        ),

                      ),
                      lineBarsData: [
                        LineChartBarData(
                            color: Color.fromARGB(255, 0, 153, 136),
                            isCurved: false,
                            belowBarData: BarAreaData(
                              show: false,
                              gradient: LinearGradient(
                                  begin:AlignmentGeometry.topCenter,
                                  end: AlignmentGeometry.bottomCenter,
                                  colors:[
                                    Color.fromARGB(120, 0, 153, 136),
                                    Color.fromARGB(60, 0, 153, 136),

                                  ]),
                            ),
                            spots: [
                              for(int i=0;i<daily_attendance_percentage.length;i++)
                                FlSpot(i.toDouble(),daily_attendance_percentage[i]),
                            ]
                        )
                      ]

                  ),

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
