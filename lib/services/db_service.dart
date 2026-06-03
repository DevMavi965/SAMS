import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smas3/models/Leave_Application_Model.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/models/course.dart';

import '../models/admin_model.dart';
import '../models/department.dart';
import '../models/semester.dart';
import '../models/session.dart';

class DbService with ChangeNotifier{
  List<InsAdmin> ins_admins=[];
  List<Institute> institutes=[];
  List<Department> departments=[];
  List<Student> students=[];
  List<Admin> admins=[];
  List<Announcement> announcements=[];
  List<Session> sessions=[];
  List<Semester> semesters=[];
  List<Course> courses=[];
  List<Lecturer> lecturers=[];
  List<LectureModel> lectures=[];

  List<LeaveApplication> leaveApplications=[];

bool loading=false;

  final dbref=FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB");
  DbService(BuildContext context){
    getData2();
  }
  // adding data to db
  clearAll(){
    ins_admins.clear();
    institutes.clear();
    departments.clear();
    students.clear();
    admins.clear();
    announcements.clear();
    sessions.clear();
    semesters.clear();
    courses.clear();
    lecturers.clear();
    lectures.clear();
    leaveApplications.clear();
  }
  getData()async{
    {
      loading = true;
      notifyListeners();
    }
    try{
      clearAll();

      final insAdmins=await dbref.collection("ins_admins").get();
      for(var insAdmin in insAdmins.docs){
        ins_admins.add(
          InsAdmin(
               id: insAdmin.id,
              name: insAdmin["name"],
              email: insAdmin["email"],
              created_at: insAdmin["created_at"].toDate(),
              last_login: insAdmin["last_login"].toDate(),
              status: insAdmin["status"])
        );
        final institutesList=await dbref.collection("ins_admins").doc(insAdmin.id).collection("institutes").get();
        for(var ins in institutesList.docs) {
          institutes.add(
              Institute(
                  id: ins.id,
                  name: ins["name"],
                  address: ins['address'],
                  contact: ins['contact'],
                  logo: ins['logo'],
                  created_at: ins['created_at'].toDate(),
                  location: ins.get('location') )//
          );
          final departs=await dbref
              .collection("ins_admins").doc(insAdmin.id)
              .collection("institutes").doc(ins.id)
              .collection("departments").get();
          for(var depart in departs.docs){
            departments.add(Department(
                id: depart.id,
                name: depart['name'],
                hod_name: depart['hod_name']));
            final sessionsSnap=await dbref
                .collection("ins_admins").doc(insAdmin.id)
                .collection("institutes").doc(ins.id)
                .collection("departments").doc(depart.id)
                .collection("sessions").get();
            for(var sSnap in sessionsSnap.docs){
              sessions.add(Session(
                  id: sSnap.id,
                  start_date: sSnap['start_date'].toDate(),
                  end_date: sSnap['end_date'].toDate()));
              final semesterSnap=await dbref
                  .collection("ins_admins").doc(insAdmin.id)
                  .collection("institutes").doc(ins.id)
                  .collection("departments").doc(depart.id)
                  .collection("sessions").doc(sSnap.id).collection("semesters").get();
              for(var semSnap in semesterSnap.docs){
                semesters.add(Semester(
                    id: semSnap.id,
                    start_date: semSnap['start_date'].toDate(),
                    end_date: semSnap['end_date'].toDate(),
                    semester_no: semSnap['semester_no']));

              }
            }
          }
          final studentSnap=await dbref
              .collection("ins_admins").doc(insAdmin.id)
              .collection("institutes").doc(ins.id)
              .collection("students").get();
          for(var student in studentSnap.docs){
            students.add(Student(
                id: student.id,
                name: student['name'],
                email: student['email'],
                depart: student['depart'],
                semester: student['semester'],
                created_at: student['created_at'].toDate()));
            final leaveSnap=await dbref.collection("ins_admins").doc(insAdmin.id)
                .collection("institutes").doc(ins.id)
                .collection("students").doc(student.id)
                .collection("leave_applications").get();
            for(var leave in leaveSnap.docs){
              leaveApplications.add(LeaveApplication(
                  appliedDate: leave['applied_date'].toDate(),
                  type: leave['type'],
                  fromDate: leave['start_date'].toDate(),
                  tillDate: leave['end_date'].toDate(),
                  reason: leave['reason'],
                  status: leave['status'],
                  std_name: leave['std_name'],
                  std_id: leave['std_id'],
                  approvedby: leave['approvedby'],
              ));
            }
          }
          final facultySnap=await dbref
              .collection("ins_admins").doc(insAdmin.id)
              .collection("institutes").doc(ins.id)
              .collection("faculty").get();
          for(var faculty in facultySnap.docs){
            lecturers.add(Lecturer(
                id: faculty.id,
                name: faculty['name'],
                email: faculty['email'],
                deprt: faculty['depart'],
                designation: faculty['designation'],
                status: faculty['status'],
                phone: faculty['phone'],
                created_at: faculty['created_at'].toDate(),
                semesters: faculty['semester'],
                courses: faculty['courses']
            ));
          }
          final adminSnap=await dbref
              .collection("ins_admins").doc(insAdmin.id)
              .collection("institutes").doc(ins.id)
              .collection("admins").get();
          for(var admin in adminSnap.docs){
            admins.add(Admin(
              id: admin.id,
                name: admin['name'],
                email: admin['email'],
                institute: admin['institute'],
                role: admin['role'],
                permissions: admin['permissions'],
                status: admin['status'],));
          }
        }
      }

    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Column(
    //   children: [
    //     Text(departments[0].id!),
    //   ],
    // )));
     }catch(e){
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{
     loading=false;
     notifyListeners();
    }
  }
  //get data from db
  getData2(){
    try{
      loading=true;
      notifyListeners();
      clearAll();
      getInsAdmins();
      for(var insAdmin in ins_admins){
        getInstitutes(insAdmin.id!);
        for(var institute in institutes){
          getStudents(insAdmin.id!,institute.id!);
          getFaculty(insAdmin.id!,institute.id!);
          getAdmins(insAdmin.id!,institute.id!);
        }
      }
    }catch(e){
     debugPrint(e.toString());
    }finally{
      loading=false;
      notifyListeners();
    }
  }
  getInsAdmins(){
    try{
     dbref.collection("ins_admins").snapshots().listen((qsnapShot){
        ins_admins.clear();
        for(var insAdmin in qsnapShot.docs){
          ins_admins.add(
              InsAdmin(
                  name: insAdmin["name"],
                  email: insAdmin["email"],
                  created_at: insAdmin["created_at"].toDate(),//timestamp to datetime
                  last_login: insAdmin["last_login"].toDate(),
                  status: insAdmin["status"]
              ));
        }
      });

      notifyListeners();
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));

    }catch(e){
      print(e.toString());
    }
 }
  getInstitutes(String insAdminId){
    try{
      dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes")
          .snapshots().listen((qsnapShot){
        institutes.clear();
        for(var ins in qsnapShot.docs){
          institutes.add(
              Institute(
                  id: ins.id,
                  name: ins["name"],
                  address: ins['address'],
                  contact: ins['contact'],
                  logo: ins['logo'],
                  created_at: ins['created_at'].toDate(),
                  location: ins.get('location') )//
          );
        }
      });

      notifyListeners();
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));

    }catch(e){
      print(e.toString());
    }
 }
  getStudents(String insAdminId,String instituteId){
    try{
      dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId)
          .collection("students")
          .snapshots().listen((qsnapShot){
        students.clear();
        for(var student in qsnapShot.docs){
          students.add(Student(
              id: student.id,
              name: student['name'],
              email: student['email'],
              depart: student['depart'],
              semester: student['semester'],
              created_at: student['created_at'].toDate()));
        }
      });

      notifyListeners();
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));

    }catch(e){
      print(e.toString());
    }
 }
  getFaculty(String insAdminId,String instituteId){
    try{
      dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId)
          .collection("faculty")
          .snapshots().listen((qsnapShot){
        lecturers.clear();
        for(var faculty in qsnapShot.docs){
          lecturers.add(Lecturer(
              id: faculty.id,
              name: faculty['name'],
              email: faculty['email'],
              deprt: faculty['depart'],
              designation: faculty['designation'],
              status: faculty['status'],
              phone: faculty['phone'],
              created_at: faculty['created_at'].toDate(),
              semesters: faculty['semester'],
              courses: faculty['courses']
          ));
        }
      });

      notifyListeners();
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));

    }catch(e){
     print(e.toString());
    }
 }
  getAdmins(String insAdminId,String instituteId){
    try{
      dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId)
          .collection("admins")
          .snapshots().listen((qSnapShot){
        admins.clear();
        for(var admin in qSnapShot.docs){
          admins.add(Admin(
            id: admin.id,
            name: admin['name'],
            email: admin['email'],
            institute: admin['institute'],
            role: admin['role'],
            permissions: admin['permissions'],
            status: admin['status'],));
        }
      });

      notifyListeners();
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));

    }catch(e){
      print(e.toString());
    }
 }

// getInsAdmins(BuildContext context)async{
  //   try{
  //     ins_admins.clear();
  //     final insAdmins=await dbref.collection("ins_admins").get();
  //     for(var insAdmin in insAdmins.docs){
  //       ins_admins.add(
  //           InsAdmin(
  //               name: insAdmin["name"],
  //               email: insAdmin["email"],
  //               created_at: insAdmin["created_at"].toDate(),//timestamp to datetime
  //               last_login: insAdmin["last_login"].toDate(),
  //               status: insAdmin["status"]
  //           ));
  //     }
  //     notifyListeners();
  //     // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));
  //
  //   }catch(e){
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }
  // create operation
  addInsAdmin(BuildContext context,InsAdmin _insAdmin)async{
    try{
      // InsAdmin insAdmin=InsAdmin(name: "Ameer Muawiya", email: "ameermuawiya34@gmail.com", created_at: DateTime.now(), last_login: DateTime.now(), status: "active");
      final insAdminsRef=await dbref.collection("ins_admins").doc(_insAdmin.id).set({
        "name":_insAdmin.name,
        "email":_insAdmin.email,
        "created_at":Timestamp.fromDate(_insAdmin.created_at!),//datetime to timestamp
        "last_login":Timestamp.fromDate(_insAdmin.last_login!),
        "status":_insAdmin.status
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ins Admin Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addInstitute(BuildContext context,String insAdminId,Institute institute)async{
    try{
      // Institute institute1=Institute(name: "MPT", address: address, contact: contact, logo: logo, created_at: created_at, location: location)
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").add({
        "name":institute.name,
        "address":institute.address,
        "contact":institute.contact,
        "logo":institute.logo,
        "created_at":Timestamp.fromDate(institute.created_at),//datetime to timestamp
        "location":GeoPoint(institute.location["lat"],institute.location["long"])
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Institute Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addDepartment(BuildContext context,String insAdminId,String instituteId,Department department)async{
    try{
      final insAdminsRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").add({
        "name":department.name,
        "created_at":Timestamp.fromDate(department.created_at!),//datetime to timestamp
        "hod_name":department.hod_name,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("department Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addAnnouncement(BuildContext context,String insAdminId,String instituteId,Announcement announcement)async{
    try{
      final insAdminsRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("announcements")
          .add({
        // Announcement(an_title: an_title, an_message: an_message, an_type: an_type, target_aud: target_aud)
           "an_title":announcement.an_title,
           "an_message":announcement.an_message,
           "an_type":announcement.an_type,
           "target_aud":announcement.target_aud,
           "created_at":Timestamp.fromDate(announcement.created_at!),//datetime to timestamp
          });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("announcement Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addSession(BuildContext context,String insAdminId,String instituteId,String departId,Session session)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).collection("departments").
      doc(departId).collection("sessions").add({
        "start_date":Timestamp.fromDate(session.start_date),//datetime to timestamp
        "end_date":Timestamp.fromDate(session.end_date),//datetime to timestamp
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("session Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addSemester(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,Semester semester)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).collection("departments").
      doc(departId).collection("sessions").doc(sessionId).collection("semesters").add({
        "start_date":Timestamp.fromDate(semester.start_date),//datetime to timestamp",
        "end_date":Timestamp.fromDate(semester.end_date),//datetime to timestamp",
        "semester_no":semester.semester_no
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addCourse(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,Course course)async{
    try{
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
      .collection("institutes").doc(instituteId)
      .collection("departments").doc(departId)
      .collection("sessions").doc(sessionId)
      .collection("semesters").doc(semesterId)
      .collection("subjects")
      .add({
        // Subject(name: name, course_code: course_code, lecturer: lecturer, credit_hours: credit_hours, no_of_lectures: no_of_lectures, type: type)
       "name":course.name,
        "course_code":course.course_code,
        "lecturer":course.lecturer,
        "credit_hours":course.credit_hours,
        "no_of_lectures":course.no_of_lectures,
        "type":course.type,
        "created_at":Timestamp.fromDate(course.created_at!),//datetime to timestamp",
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Course Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addLecture(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId,LectureModel lectureModel)async{
    try{
 DateTime start_time_date=DateTime(
   lectureModel.dated.year,
   lectureModel.dated.month,
   lectureModel.dated.day,
   lectureModel.start_time.hour,
   lectureModel.start_time.minute,

 );
 DateTime end_time_date=DateTime(
   lectureModel.dated.year,
   lectureModel.dated.month,
   lectureModel.dated.day,
   lectureModel.end_time.hour,
   lectureModel.end_time.minute,

 );
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).collection("lectures")
          .add({
            "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
            "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
            "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
            "students":lectureModel.students,
            "present":lectureModel.present,
            "absent":lectureModel.absent,
            "room":lectureModel.room,
            "course_name":courseId,//will take course_name using id back in ui
            "status":lectureModel.status,
          });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addFaculty(BuildContext context,String insAdminId,String instituteId,Lecturer lecturer)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("faculty").add({
        // Lecturer(name: name, deprt: deprt, designation: designation, status: status, email: email, phone: phone)
        "name":lecturer.name,
        "email":lecturer.email,
        "depart":lecturer.deprt,
        "designation":lecturer.designation,
        "status":lecturer.status,
        "created_at":Timestamp.fromDate(lecturer.created_at!),//datetime to timestamp",
        "semester":lecturer.semesters,
        "courses":lecturer.courses,
        "phone":lecturer.phone,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("faculty Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addStudent(BuildContext context,String insAdminId,String instituteId,Student student)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").add({
      // Student(name: name, depart: depart, semester: semester, email: email)
        "name":student.name,
        "email":student.email,
        "depart":student.depart,
        "semester":student.semester,
        "created_at":Timestamp.fromDate(student.created_at!),//datetime to timestamp",
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addAdmin(BuildContext context,String insAdminId,String instituteId,Admin admin)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").add({
      // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
      "name":admin.name,
      "email":admin.email,
      "institute":admin.institute,
      "role":admin.role,
      "status":admin.status,
      "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
      "permissions":admin.permissions//["student_management","department_management","lecture_management"] etc

      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addStudentLeaveApplication(BuildContext context,String insAdminId,String instituteId,String studentId,LeaveApplication leaveApplication)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").doc(studentId).collection("leave_applications")
      .add({
        // LeaveApplication(appliedDate: appliedDate, type: type, fromDate: fromDate,
        // tillDate: tillDate, reason: reason, status: status, std_name: std_name, std_id: std_id)
        "start_date":Timestamp.fromDate(leaveApplication.fromDate),//datetime to timestamp",
        "end_date":Timestamp.fromDate(leaveApplication.tillDate),//datetime to timestamp",
        "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),//datetime to timestamp","
        "std_name":leaveApplication.std_name,
        "std_id":leaveApplication.std_id,
        "type":leaveApplication.type,
        "reason":leaveApplication.reason,
        "status":leaveApplication.status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave applied Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  //removing data from db
  removeInsAdmin(BuildContext context,String insAdminId)async{
    try{
      // InsAdmin insAdmin=InsAdmin(name: "Ameer Muawiya", email: "ameermuawiya34@gmail.com", created_at: DateTime.now(), last_login: DateTime.now(), status: "active");
      final insAdminsRef=await dbref.collection("ins_admins").doc(insAdminId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ins Admin deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeInstitute(BuildContext context,String insAdminId,String instituteId)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Institute deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeDepartment(BuildContext context,String insAdminId,String instituteId,String departmentId)async{
    try{
      final insAdminsRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departmentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("department deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeAnnouncement(BuildContext context,String insAdminId,String instituteId,String announcementId)async{
    try{
      final insAdminsRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("announcements")
          .doc(announcementId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("announcement deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeSession(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).collection("departments").
      doc(departId).collection("sessions").doc(sessionId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("session deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeSemester(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).collection("departments").
      doc(departId).collection("sessions").doc(sessionId).collection("semesters").doc(semesterId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeCourse(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId)async{
    try{
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Course deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeLecture(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId,String lectureModelId)async{
    try{


      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).collection("lectures")
          .doc(lectureModelId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeFaculty(BuildContext context,String insAdminId,String instituteId,String lecturerId)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("faculty").doc(lecturerId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("faculty deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeStudent(BuildContext context,String insAdminId,String instituteId,String studentId)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").doc(studentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeAdmin(BuildContext context,String insAdminId,String instituteId,String adminId)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(adminId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeStudentLeaveApplication(BuildContext context,String insAdminId,String instituteId,String studentId,String leaveApplicationId)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").doc(studentId).collection("leave_applications")
          .doc(leaveApplicationId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leaveApplication deleted Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }

//updating data in db
  updateInsAdmin(BuildContext context,InsAdmin insAdmin)async{
    try{
      // InsAdmin insAdmin=InsAdmin(name: "Ameer Muawiya", email: "ameermuawiya34@gmail.com", created_at: DateTime.now(), last_login: DateTime.now(), status: "active");
      final insAdminsRef=await dbref.collection("ins_admins").doc(insAdmin.id)
          .update({
        "name":insAdmin.name,
        "email":insAdmin.email,
        "created_at":Timestamp.fromDate(insAdmin.created_at!),//datetime to timestamp
        "last_login":Timestamp.fromDate(insAdmin.last_login!),
        "status":insAdmin.status
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ins Admin updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateInstitute(BuildContext context,String insAdminId,Institute institute)async{
    try{
      // Institute institute1=Institute(name: "MPT", address: address, contact: contact, logo: logo, created_at: created_at, location: location)
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(institute.id).update({
        "name":institute.name,
        "address":institute.address,
        "contact":institute.contact,
        "logo":institute.logo,
        "created_at":Timestamp.fromDate(institute.created_at),//datetime to timestamp
        "location":GeoPoint(institute.location["lat"],institute.location["long"])
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Institute updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateDepartment(BuildContext context,String insAdminId,String instituteId,Department department)async{
    try{
      final insAdminsRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(department.id).update({
        "name":department.name,
        "created_at":Timestamp.fromDate(department.created_at!),//datetime to timestamp
        "hod_name":department.hod_name,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("department updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateAnnouncement(BuildContext context,String insAdminId,String instituteId,Announcement announcement)async{
    try{
      final insAdminsRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("announcements")
          .doc(announcement.id).update({
        // Announcement(an_title: an_title, an_message: an_message, an_type: an_type, target_aud: target_aud)
        "an_title":announcement.an_title,
        "an_message":announcement.an_message,
        "an_type":announcement.an_type,
        "target_aud":announcement.target_aud,
        "created_at":Timestamp.fromDate(announcement.created_at!),//datetime to timestamp
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("announcement updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateSession(BuildContext context,String insAdminId,String instituteId,String departId,Session session)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).collection("departments").
      doc(departId).collection("sessions").doc(session.id).update({
        "start_date":Timestamp.fromDate(session.start_date),//datetime to timestamp
        "end_date":Timestamp.fromDate(session.end_date),//datetime to timestamp
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("session updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateSemester(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,Semester semester)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).collection("departments").
      doc(departId).collection("sessions").doc(sessionId).collection("semesters").doc(semester.id).update({
        "start_date":Timestamp.fromDate(semester.start_date),//datetime to timestamp",
        "end_date":Timestamp.fromDate(semester.end_date),//datetime to timestamp",
        "semester_no":semester.semester_no
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateCourse(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,Course course)async{
    try{
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(course.id).update({
        // Subject(name: name, course_code: course_code, lecturer: lecturer, credit_hours: credit_hours, no_of_lectures: no_of_lectures, type: type)
        "name":course.name,
        "course_code":course.course_code,
        "lecturer":course.lecturer,
        "credit_hours":course.credit_hours,
        "no_of_lectures":course.no_of_lectures,
        "type":course.type,
        "created_at":Timestamp.fromDate(course.created_at!),//datetime to timestamp",
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Course updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateLecture(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId,LectureModel lectureModel)async{
    try{
      DateTime start_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.start_time.hour,
        lectureModel.start_time.minute,

      );
      DateTime end_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.end_time.hour,
        lectureModel.end_time.minute,

      );
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).collection("lectures")
          .doc(lectureModel.id).update({
        "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        "students":lectureModel.students,
        "present":lectureModel.present,
        "absent":lectureModel.absent,
        "room":lectureModel.room,
        "course_name":courseId,//will take course_name using id back in ui
        "status":lectureModel.status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendancePresent(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId,LectureModel lectureModel,String studentId)async{
    try{
      List<String> students_=lectureModel.present!;
      students_.add(studentId);
      DateTime start_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.start_time.hour,
        lectureModel.start_time.minute,

      );
      DateTime end_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.end_time.hour,
        lectureModel.end_time.minute,

      );
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).collection("lectures")
          .doc(lectureModel.id).update({
        "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        "students":lectureModel.students,
        "present":students_,
        "absent":lectureModel.absent,
        "room":lectureModel.room,
        "course_name":courseId,//will take course_name using id back in ui
        "status":lectureModel.status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendancePresentGroup(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId,LectureModel lectureModel,List<String> studentIds)async{
    try{
      List<String> students_p=lectureModel.present!;
      for(int i=0;i<studentIds.length;i++){
        students_p.add(studentIds[i]);
      }
      DateTime start_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.start_time.hour,
        lectureModel.start_time.minute,

      );
      DateTime end_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.end_time.hour,
        lectureModel.end_time.minute,

      );
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).collection("lectures")
          .doc(lectureModel.id).update({
        "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        "students":lectureModel.students,
        "present":students_p,
        "absent":lectureModel.absent,
        "room":lectureModel.room,
        "course_name":courseId,//will take course_name using id back in ui
        "status":lectureModel.status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendanceAbsentGroup(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId,LectureModel lectureModel,List<String> studentIds)async{
    try{
      List<String> students_ab=lectureModel.absent!;
      for(int i=0;i<studentIds.length;i++){
        students_ab.add(studentIds[i]);
      }
      DateTime start_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.start_time.hour,
        lectureModel.start_time.minute,

      );
      DateTime end_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.end_time.hour,
        lectureModel.end_time.minute,

      );
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).collection("lectures")
          .doc(lectureModel.id).update({
        "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        "students":lectureModel.students,
        "present":lectureModel.present,
        "absent":students_ab,
        "room":lectureModel.room,
        "course_name":courseId,//will take course_name using id back in ui
        "status":lectureModel.status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendanceAbsent(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,String courseId,LectureModel lectureModel,String studentId)async{
    try{
      List<String> students_abs=lectureModel.absent!;
      students_abs.add(studentId);
      DateTime start_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.start_time.hour,
        lectureModel.start_time.minute,

      );
      DateTime end_time_date=DateTime(
        lectureModel.dated.year,
        lectureModel.dated.month,
        lectureModel.dated.day,
        lectureModel.end_time.hour,
        lectureModel.end_time.minute,

      );
      final insAdminsRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("subjects")
          .doc(courseId).collection("lectures")
          .doc(lectureModel.id).update({
        "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        "students":lectureModel.students,
        "present":lectureModel.present,
        "absent":students_abs,
        "room":lectureModel.room,
        "course_name":courseId,//will take course_name using id back in ui
        "status":lectureModel.status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateFaculty(BuildContext context,String insAdminId,String instituteId,Lecturer lecturer)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("faculty").doc(lecturer.id).update({
        // Lecturer(name: name, deprt: deprt, designation: designation, status: status, email: email, phone: phone)
        "name":lecturer.name,
        "email":lecturer.email,
        "depart":lecturer.deprt,
        "designation":lecturer.designation,
        "status":lecturer.status,
        "created_at":Timestamp.fromDate(lecturer.created_at!),//datetime to timestamp",
        "semester":lecturer.semesters,
        "courses":lecturer.courses,
        "phone":lecturer.phone,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("faculty Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateStudent(BuildContext context,String insAdminId,String instituteId,Student student)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").doc(student.id).update({
        // Student(name: name, depart: depart, semester: semester, email: email)
        "name":student.name,
        "email":student.email,
        "depart":student.depart,
        "semester":student.semester,
        "created_at":Timestamp.fromDate(student.created_at!),//datetime to timestamp",
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateAdmin(BuildContext context,String insAdminId,String instituteId,Admin admin)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(admin.id).update({
        // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
        "name":admin.name,
        "email":admin.email,
        "institute":admin.institute,
        "role":admin.role,
        "status":admin.status,
        "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
        "permissions":admin.permissions//["student_management","department_management","lecture_management"] etc

      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  assignPermissionsAdmin(BuildContext context,String insAdminId,String instituteId,Admin admin,String permission)async{
    try{
      List<String> permissions_=admin.permissions!;
      permissions_.add(permission);
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(admin.id).update({
        // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
        "name":admin.name,
        "email":admin.email,
        "institute":admin.institute,
        "role":admin.role,
        "status":admin.status,
        "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
        "permissions":permissions_//["student_management","department_management","lecture_management"] etc

      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  revokePermissionsAdmin(BuildContext context,String insAdminId,String instituteId,Admin admin,String permission)async{
    try{
      List<String> permissions_=admin.permissions!;
      permissions_.remove(permission);
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(admin.id).update({
        // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
        "name":admin.name,
        "email":admin.email,
        "institute":admin.institute,
        "role":admin.role,
        "status":admin.status,
        "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
        "permissions":permissions_//["student_management","department_management","lecture_management"] etc

      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin Added Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateStudentLeaveApplication(BuildContext context,String insAdminId,String instituteId,String studentId,LeaveApplication leaveApplication)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").doc(studentId).collection("leave_applications")
          .doc(leaveApplication.id).update({
        // LeaveApplication(appliedDate: appliedDate, type: type, fromDate: fromDate,
        // tillDate: tillDate, reason: reason, status: status, std_name: std_name, std_id: std_id)
        "start_date":Timestamp.fromDate(leaveApplication.fromDate),//datetime to timestamp",
        "end_date":Timestamp.fromDate(leaveApplication.tillDate),//datetime to timestamp",
        "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),//datetime to timestamp","
        "std_name":leaveApplication.std_name,
        "std_id":leaveApplication.std_id,
        "type":leaveApplication.type,
        "reason":leaveApplication.reason,
        "status":leaveApplication.status,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave applied Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  approveStudentLeaveApplication(BuildContext context,String insAdminId,String instituteId,String studentId,LeaveApplication leaveApplication,String adminName)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").doc(studentId).collection("leave_applications")
          .doc(leaveApplication.id).update({
        // LeaveApplication(appliedDate: appliedDate, type: type, fromDate: fromDate,
        // tillDate: tillDate, reason: reason, status: status, std_name: std_name, std_id: std_id)
        "start_date":Timestamp.fromDate(leaveApplication.fromDate),//datetime to timestamp",
        "end_date":Timestamp.fromDate(leaveApplication.tillDate),//datetime to timestamp",
        "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),//datetime to timestamp","
        "std_name":leaveApplication.std_name,
        "std_id":leaveApplication.std_id,
        "type":leaveApplication.type,
        "reason":leaveApplication.reason,
        "status":"approved",
        "approvedby":adminName,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave applied Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  rejectStudentLeaveApplication(BuildContext context,String insAdminId,String instituteId,String studentId,LeaveApplication leaveApplication,String adminName)async{
    try{
      final insAdminsRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("students").doc(studentId).collection("leave_applications")
          .doc(leaveApplication.id).update({
        // LeaveApplication(appliedDate: appliedDate, type: type, fromDate: fromDate,
        // tillDate: tillDate, reason: reason, status: status, std_name: std_name, std_id: std_id)
        "start_date":Timestamp.fromDate(leaveApplication.fromDate),//datetime to timestamp",
        "end_date":Timestamp.fromDate(leaveApplication.tillDate),//datetime to timestamp",
        "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),//datetime to timestamp","
        "std_name":leaveApplication.std_name,
        "std_id":leaveApplication.std_id,
        "type":leaveApplication.type,
        "reason":leaveApplication.reason,
        "status":"rejected",
        "approvedby":adminName,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave applied Successfully")));
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }

}