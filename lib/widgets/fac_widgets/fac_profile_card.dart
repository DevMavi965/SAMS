import 'package:flutter/material.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/student_model.dart';
class Fac_profile_Card extends StatefulWidget {
  final Lecturer lecturer;
  const Fac_profile_Card({super.key, required this.lecturer});

  @override
  State<Fac_profile_Card> createState() => _Fac_profile_CardState();
}

class _Fac_profile_CardState extends State<Fac_profile_Card> {
  String getLogo(String name) {
    name = name.trim();
    List<String> parts = name.split(' ');
    return parts.first[0].toUpperCase() +
        (parts.length > 1 ? parts.last[0].toUpperCase() : '');
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,

      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        // color: Colors.green,
          gradient: LinearGradient(
              end: AlignmentGeometry.topLeft,
              begin: AlignmentGeometry.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey,
            width: 0.2,
          )

      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 4,
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).primaryColor,

                  // backgroundImage: AssetImage("assets/images/img.png"),
                  child: Text(getLogo(widget.lecturer.name),style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
                ),
              ),
              SizedBox(width: 20,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.lecturer.name,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
                  Text(widget.lecturer.designation,style: TextStyle(color: Colors.white,fontWeight: FontWeight.w400,fontSize: 14),),
                ],

              )
            ],
          ),
          SizedBox(height: 20,),
          Row(
            children: [
              OutlinedButton(
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all(Size(130, 35)),
                    minimumSize: MaterialStateProperty.all(Size(120, 35)),
                    maximumSize: MaterialStateProperty.all(Size(150, 35)),
                    padding: MaterialStateProperty.all(EdgeInsets.all(0)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),

                    )),
                    side: MaterialStateProperty.all(BorderSide(
                      color: Colors.white,
                      width:1,
                    )),
                  ),
                  onPressed: () {

                  }, child: Text(widget.lecturer.deprt,style: TextStyle(fontSize: 11,color: Colors.white),)),
              SizedBox(width: 20,),
              OutlinedButton(
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all(Size(100, 35)),
                    minimumSize: MaterialStateProperty.all(Size(100, 35)),
                    padding: MaterialStateProperty.all(EdgeInsets.all(5)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),

                    )),
                    side: MaterialStateProperty.all(BorderSide(
                      color: Colors.white,
                      width: 1,
                    )),
                  ),
                  onPressed: () {

                  }, child: Text("Active",style: TextStyle(fontSize: 11,color: Colors.white),))
            ],
          )
        ],
      ),

    );
  }
}
