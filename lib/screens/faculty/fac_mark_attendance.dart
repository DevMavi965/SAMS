import 'package:flutter/material.dart';
class FacMarkAttendanceTab extends StatefulWidget {
  const FacMarkAttendanceTab({super.key});

  @override
  State<FacMarkAttendanceTab> createState() => _FacMarkAttendanceTabState();
}

class _FacMarkAttendanceTabState extends State<FacMarkAttendanceTab> {
  List<String> classes=[
    "Data Science",
    "ML",
    "DSA"
  ];
  String selected=" ";
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SafeArea(child: ListView(
        // disabling scroll
        // physics: NeverScrollableScrollPhysics(),
        children: [
          Text("Mark Attendance",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600)),
          SizedBox(height: 7,),
          Text("Manage Your Classes and Attendance",style: TextStyle(fontSize: 15,color: Colors.grey),),
          SizedBox(height: 20,),
          Container(
            margin: EdgeInsets.symmetric(
              vertical: 5
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 5,vertical: 10
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              border: Border.all(
                width: 0.1,
                color: Colors.grey.shade400
              )
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Select class",style: TextStyle(color: Colors.grey),),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  margin: EdgeInsets.symmetric(
                    vertical: 5,horizontal: 10
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      width: 0.5,
                      color: Colors.grey
                    ),

                  ),
                  child: 
                  DropdownButton(


                      hint: Text("Select Class"),
                      borderRadius: BorderRadius.circular(8),
                      icon: Icon(Icons.keyboard_arrow_down_sharp),
                      isExpanded: true,
                      underline: SizedBox(),
                      value:selected==" "?null:selected,
                      items: [
                    for(int i=0;i<classes.length;i++)
                      DropdownMenuItem(value: classes[i],child: Text(classes[i]))
                  ],
                      onChanged: (v){
                    setState(() {
                      selected=v!;
                    });
                      }),
                ),

              ],
            ),
          ),
          SizedBox(height: 20,),
          Container(
            
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),

            ),
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 30,
                itemBuilder: (context,count){
                  return
                    Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 5,vertical: 5
                    ),
                   padding: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                   decoration: BoxDecoration(
                    color: Colors.white,
                     borderRadius: BorderRadius.circular(7),


                   ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(70),
                      radius:28,
                      child: Text('AM',style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text("Ameer Khan",style: TextStyle(fontWeight: FontWeight.w600),),
                      SizedBox(height: 3,),
                      Text("ameer@gmail.com",style: TextStyle(color: Colors.grey),),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Badge(label: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Text("IT",style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black
                            ),),
                          ),backgroundColor: Colors.grey.withAlpha(70),),
                          SizedBox(width: 10,),
                          Badge(label: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Text("2022-26",style: TextStyle(color: Colors.black),),
                          ),backgroundColor: Color(0xfff1f5f9),),

                        ],
                      )
                    ],),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Badge(label: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Text("IT20454",style: TextStyle(color: Colors.black),),
                          ),backgroundColor:Color(0xfff1f5f9),),
                          SizedBox(height: 10,),
                          Icon(Icons.check_circle_outline_sharp),
                        ],
                      )
                  ],),
                  );
                }),
          )
        ],
      )),
    );
  }
}
