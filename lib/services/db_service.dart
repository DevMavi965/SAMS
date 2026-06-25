import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smas3/models/Leave_Application_Model.dart';
import 'package:smas3/models/announcement_model.dart';
import 'package:smas3/models/fac_model.dart';
import 'package:smas3/models/ins_admin.dart';
import 'package:smas3/models/institute.dart';
import 'package:smas3/models/lecture.dart';
import 'package:smas3/models/student_model.dart';
import 'package:smas3/models/course.dart';
import 'package:smas3/screens/admin/admin_deshboard.dart';
import 'package:smas3/screens/auth_screens/login_screen.dart';
import 'package:smas3/screens/faculty/fac_deshboard.dart';
import 'package:smas3/screens/ins_admin/ins_selection.dart';
import 'package:smas3/screens/student/stdudent_deshboard.dart';

import '../models/admin_model.dart';
import '../models/department.dart';
import '../models/semester.dart';
import '../models/session.dart';

class DbService with ChangeNotifier{


  // List<InsAdmin> ins_admins=[];
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
  final dbref=FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB");
  final indexDoc=FirebaseFirestore.instance.collection("SAMS").doc("SAMS_DB").collection("index");
  bool loading=false;
  int count=0;
  final eauth=FirebaseAuth.instance;
 void setIndx(int v){
   count=v;
   notifyListeners();
 }
  loginWithInsAdminEmail(String _email,String _password,BuildContext context)async{
    try{
      loading=true;
      notifyListeners();
     final userCred= await eauth.signInWithEmailAndPassword(email: _email,
          password: _password);
      if(userCred.user!=null) {
        final v =await dbref.collection("ins_admins").doc(
            userCred.user!.uid).get();
        if(!v.exists){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("not registered as institute admin"),));
          eauth.signOut();
          return;
        }

          InsAdmin insAdmin = InsAdmin(
              id: v.id,
              role: v['role'],
              name: v["name"],
              email: v["email"],
              created_at: v["created_at"].toDate(),
              last_login: v["last_login"].toDate(),
              status: v["status"]);
             Provider.of<DbService>(context,listen: false).getData1(insAdmin.id!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("successfully logged-in as institute admin"),
              backgroundColor: Theme
                  .of(context)
                  .primaryColor,));
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                builder: (_) => InsSelection(insAdmin: insAdmin)), (
                r) => false);

          }

      }
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));
      }
    }finally{

        loading=false;
     notifyListeners();
    }

  }
  signUpWithInsAdminEmail(InsAdmin _insAdmin,String password,BuildContext context)async{
      loading=true;
    notifyListeners();
    try{
      await eauth.createUserWithEmailAndPassword(email: _insAdmin.email,
          password: password).then((v) async{
        if(eauth.currentUser!=null){

        _insAdmin.id=eauth.currentUser!.uid;
         await addInsAdmin(context,_insAdmin);
        getData1(_insAdmin.id!);
        if(context.mounted){
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>InsSelection(insAdmin: _insAdmin,)),(r)=>false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("successfully registered as institute admin"),backgroundColor: Theme.of(context).primaryColor,));
        }
        }else{
          if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));}
        }
      });
    }catch(e){
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()),));
      }
    }finally{

        loading=false;
      notifyListeners();
    }

  }

  registerAdmin(String _insAdminId, String instituteId, Admin admin, String password, BuildContext context) async {
    // iCreated a secondary app instence to avoid disrupting current_auth session
    FirebaseApp secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
    } catch (e) {
      secondaryApp = Firebase.app('SecondaryApp');
    }

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential uc = await secondaryAuth.createUserWithEmailAndPassword(
        email: admin.email,
        password: password,
      );

      if (uc.user != null) {
        admin.id = uc.user!.uid;
        await addAdmin(context, _insAdminId, instituteId, admin);
        await indexDoc.doc(admin.id).set({
          "ins_admin_id": _insAdminId,
          "institute_id": instituteId,
          "password":password,
          "role":admin.role
        });
      } else {
        print("invalid email or password for admin");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),),
        );
      }
      print(e.toString());
    } finally {
      // Sign0ut from secondary and delete the tempOrary app
      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();
    }
  }
  deleteAuthUser(String email, String password) async {
    FirebaseApp secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'TempDeleteApp',
        options: Firebase.app().options,
      );
    } catch (e) {
      secondaryApp = Firebase.app('TempDeleteApp');
    }

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final uc = await secondaryAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await uc.user?.delete();
    } catch (e) {
      print("Auth delete error: $e");
    } finally {
      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();
    }
  }
  loginWithAdminEmail(String _email,String _password,BuildContext context)async{
    try{
      loading=true;
      notifyListeners();
      await eauth.signInWithEmailAndPassword(email: _email,
          password: _password).then((v) async {
        if(eauth.currentUser!=null){
          final dox=await indexDoc.doc(eauth.currentUser!.uid).get();
          if(dox.exists==false){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));
            eauth.signOut();
            return;
          }

          final insAdminId=dox['ins_admin_id'];
          final instituteId=dox['institute_id'];
         print(dox.data());
          final doc=dbref.collection("ins_admins").doc(insAdminId);
          final v=await dbref
              .collection("ins_admins").doc(insAdminId).
               collection("institutes").doc(instituteId)
              .collection("admins").doc(eauth.currentUser!.uid).get();
          if(!v.exists){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("not registered as admin"),));
            eauth.signOut();
            return;
          }
          print(v.data());
          Admin _admin=Admin(
            id: v.id,
            insAdminId: v['ins_admin_id'],
            instituteId: v['institute_id'],
            name: v['name'],
            email: v['email'],
            institute: v['institute'],
            role: v['role'],
            permissions:List<String>.from( v['permissions']),
            status: v['status'],
          );
          if(context.mounted){
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                builder: (_) => AdminDeshboard(admin: _admin)), (
                r) => false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("successfully logging as admin"),
              backgroundColor: Theme
                  .of(context)
                  .primaryColor,));
          }
          await getData1(insAdminId);

        }else{
          if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));}
        }
      });
    }catch(e){
      print(e.toString());
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));}
    }finally{

      loading=false;
      notifyListeners();
    }

  }


  registerFac(String _insAdminId,String instituteId,String departmentId,Lecturer lecturer,String password,BuildContext context)async{
    FirebaseApp secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
    } catch (e) {
      secondaryApp = Firebase.app('SecondaryApp');
    }

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential uc = await secondaryAuth.createUserWithEmailAndPassword(
        email: lecturer.email,
        password: password,
      );

      if (uc.user != null) {
        lecturer.id = uc.user!.uid;
        await addFaculty(context, _insAdminId, instituteId,departmentId, lecturer);
        await indexDoc.doc(lecturer.id).set({
          "ins_admin_id": _insAdminId,
          "institute_id": instituteId,
          "department_id":lecturer.departmentId,
          "password":password,
          "role":lecturer.role
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("successfully ${lecturer.name} registered as faculty"),backgroundColor: Theme.of(context).primaryColor,));
        print("successfully ${lecturer.name} registered as faculty");
      } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));

        print("invalid email or password for admin");
      }
    } catch (e) {
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));
      }
      print(e.toString());
    } finally {
      // Sign0ut from secondary and delete the tempOrary app
      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();
    }
  }
  loginWithFacEmail(String _email,String _password,BuildContext context)async{
    try{
      loading=true;
      notifyListeners();
      await eauth.signInWithEmailAndPassword(email: _email,
          password: _password).then((v) async {
        if(eauth.currentUser!=null){
          final dox=await indexDoc.doc(eauth.currentUser!.uid).get();
          if(dox.exists==false){
            if(context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));}
            eauth.signOut();
            return;
          }
          final insAdminId=dox['ins_admin_id'];
          final instituteId=dox['institute_id'];
          final departmentId=dox['department_id'];
          print(dox.data());
          final doc=dbref.collection("ins_admins").doc(insAdminId);
          final v=await dbref
              .collection("ins_admins").doc(insAdminId).
          collection("institutes").doc(instituteId)
              .collection("departments").doc(departmentId)
              .collection("faculty").doc(eauth.currentUser!.uid).get();
          if(!v.exists){
            if(context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("not registered as faculty"),));}
            eauth.signOut();
            return;
          }
          print(v.data());
          Lecturer faculty=Lecturer(
              id: v.id,
              name: v['name'],
              deprt: v['depart'],
              role: v['role'],
              instituteId: instituteId,
              insAdminId: insAdminId,
              departmentId: departmentId,
              designation: v['designation'],
              status: v['status'],
              email: v['email'],
              semesters: List<int>.from(v['semester']),
              courses: List<String>.from(v['courses']),
              created_at: v['created_at'].toDate(),
              phone: v['phone'],);
          if(context.mounted){
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                builder: (_) => FacDeshboard(lecturer: faculty)), (
                r) => false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("successfully logging as faculty"),
              backgroundColor: Theme
                  .of(context)
                  .primaryColor,));
          }
          await getData1(insAdminId);

        }else{
          if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));}
        }
      });
    }catch(e){
      print(e.toString());
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));}
    }finally{

      loading=false;
      notifyListeners();
    }

  }


  registerStudent(String _insAdminId,String instituteId,Student student,String password,BuildContext context)async{
    FirebaseApp secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
    } catch (e) {
      secondaryApp = Firebase.app('SecondaryApp');
    }

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential uc = await secondaryAuth.createUserWithEmailAndPassword(
        email: student.email,
        password: password,
      );

      if (uc.user != null) {
        student.id = uc.user!.uid;
        await addStudent(context, _insAdminId, instituteId, student);
        await indexDoc.doc(student.id).set({
          "ins_admin_id": _insAdminId,
          "institute_id": instituteId,
          "department_id":student.departId,
          "session_id":student.sessionId,
          "semester_id":student.semesterId,
          "password":password,
          "role":student.role
        });
        print("successfully ${student.name} registered as student");
      } else {
        print("invalid email or password for student");
      }
    } catch (e) {
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));}
      print(e.toString());
    } finally {
      // Sign0ut from secondary and delete the tempOrary app
      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();
    }
  }
  loginWithStudentEmail(String _email,String _password,BuildContext context)async{
    try{
      loading=true;
      notifyListeners();
      await eauth.signInWithEmailAndPassword(email: _email,
          password: _password).then((v) async {
        if(eauth.currentUser!=null){
          final dox=await indexDoc.doc(eauth.currentUser!.uid).get();
          if(dox.exists==false){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));
            eauth.signOut();
            return;
          }
          final insAdminId=dox['ins_admin_id'];
          final instituteId=dox['institute_id'];
          final departmentId=dox['department_id'];
          final sessionId=dox['session_id'];
          final semesterId=dox['semester_id'];
          print(dox.data());
          final v=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departmentId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("students").doc(eauth.currentUser!.uid).get();
          print(v.data());
          if(!v.exists){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("not registered as student"),));
            eauth.signOut();
            return;
          }
          Student student=Student(
              id: v.id,
              role: v['role'],
              name: v['name'],
              insAdminId: insAdminId,
              instituteId: instituteId,
              departId: v['department_id'],
              sessionId: v['session_id'],
              semesterId: v['semester_id'],
              email: v['email'],
              created_at: v['created_at'].toDate(),
          );
          if(context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("successfully logged-in as ${student.name}"),
              backgroundColor: Theme
                  .of(context)
                  .primaryColor,));
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                builder: (_) => StudentDeshboard(student: student)), (
                r) => false);

          }
          await getData1(insAdminId);

        }else{
          if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("invalid email or password"),));}
        }
      });
    }catch(e){
      print(e.toString());
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));}
    }finally{

      loading=false;
      notifyListeners();
    }

  }
  signOut(BuildContext context)async{
    try{
      loading=true;
      notifyListeners();
      await eauth.signOut();
      if(context.mounted){
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>LoginScreen()),(r)=>false);
      }
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),));}
    }
    finally {
      loading = false;
      notifyListeners();
    }
  }


  // adding data to db
  clearAll(){
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
  getData1(String insAdminId)async{
    {
      loading = true;
      notifyListeners();
    }
    try{
      clearAll();
        final institutesList=await dbref.collection("ins_admins").doc(insAdminId).collection("institutes").get();
        for(var ins in institutesList.docs) {
          institutes.add(
              Institute(
                  id: ins.id,
                  insAdminId: insAdminId,
                  name: ins["name"],
                  address: ins['address'],
                  contact: ins['contact'],
                  logo: ins['logo'],
                  created_at: ins['created_at'].toDate(),
                  location: ins['location']) //
          );
          print("ins : 000000000000000000000000000000000000000000000000000000000000000000");
          final departs=await dbref
              .collection("ins_admins").doc(insAdminId)
              .collection("institutes").doc(ins.id)
              .collection("departments").get();
          for(var depart in departs.docs){
            departments.add(Department(
                id: depart.id,
                name: depart['name'],
                hod_name: depart['hod_name']));
            final facultySnap=await dbref
                .collection("ins_admins").doc(insAdminId)
                .collection("institutes").doc(ins.id)
                .collection("departments").doc(depart.id)
                .collection("faculty").get();
            for(var faculty in facultySnap.docs){
              lecturers.add(Lecturer(
                  id: faculty.id,
                  instituteId: ins.id,
                  insAdminId: insAdminId,
                  departmentId: depart.id,
                  role: faculty['role'],
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
            final sessionsSnap=await dbref
                .collection("ins_admins").doc(insAdminId)
                .collection("institutes").doc(ins.id)
                .collection("departments").doc(depart.id)
                .collection("sessions").get();
            for(var sSnap in sessionsSnap.docs){
              sessions.add(Session(
                  id: sSnap.id,
                  name: sSnap['name'],
                  start_date: sSnap['start_date'].toDate(),
                  end_date: sSnap['end_date'].toDate()));
              final semesterSnap=await dbref
                  .collection("ins_admins").doc(insAdminId)
                  .collection("institutes").doc(ins.id)
                  .collection("departments").doc(depart.id)
                  .collection("sessions").doc(sSnap.id).collection("semesters").get();
              for(var semSnap in semesterSnap.docs){
                semesters.add(Semester(
                    id: semSnap.id,
                    ins_admin_id: insAdminId,
                    institute_id: ins.id,
                    department_id: depart.id,
                    session_id: sSnap.id,
                    start_date: semSnap['start_date'].toDate(),
                    end_date: semSnap['end_date'].toDate(),
                    semester_no: semSnap['semester_no']));
                final studentSnap=await dbref
                    .collection("ins_admins").doc(insAdminId)
                    .collection("institutes").doc(ins.id)
                    .collection("departments").doc(depart.id)
                    .collection("sessions").doc(sSnap.id)
                    .collection("semesters").doc(semSnap.id)
                    .collection("students").get();
                for(var student in studentSnap.docs){
                  students.add(Student(
                      id: student.id,
                      insAdminId: insAdminId,
                      instituteId: ins.id,
                      role: student['role'],
                      name: student['name'],
                      email: student['email'],
                      departId: depart.id,
                      sessionId: sSnap.id,
                      semesterId: semSnap.id,
                      created_at: student['created_at'].toDate()));
                  final leaveSnap=await dbref.collection("ins_admins").doc(insAdminId)
                      .collection("institutes").doc(ins.id)
                      .collection("departments").doc(depart.id)
                      .collection("sessions").doc(sSnap.id)
                      .collection("semesters").doc(semSnap.id)
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
                final courseSnap=await dbref
                    .collection("ins_admins").doc(insAdminId)
                    .collection("institutes").doc(ins.id)
                    .collection("departments").doc(depart.id)
                    .collection("sessions").doc(sSnap.id)
                    .collection("semesters").doc(semSnap.id)
                    .collection("courses").get();
                for(var course1 in courseSnap.docs){
                  courses.add(
                    Course(
                      id: course1.id,
                      name: course1['name'],
                      course_code: course1['course_code'],
                      credit_hours: course1['credit_hours'],
                      no_of_lectures: course1['no_of_lectures'],
                      type: course1['type'],
                      lecturer_id: course1['lecturer_id'],
                      lecturer_name: course1['lecturer_name'],
                      created_at: course1['created_at'].toDate(),
                      insAdminId: course1['ins_admin_id'],
                      institute_id: course1['institute_id'],
                      department_id: course1['department_id'],
                      session_id: course1['session_id'],
                      semester_id: course1['semester_id'],
                    )
                  );

                }
              }
            }
          }


          final adminSnap=await dbref
              .collection("ins_admins").doc(insAdminId)
              .collection("institutes").doc(ins.id)
              .collection("admins").get();
          for(var admin in adminSnap.docs){
            admins.add(Admin(
              id: admin.id,
                insAdminId: insAdminId,
                instituteId: ins.id,
                name: admin['name'],
                email: admin['email'],
                institute: admin['institute'],
                role: admin['role'],
                permissions: admin['permissions'],
                status: admin['status'],));
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
 getInstitutesList(String insAdminId){
    List<Institute> institutes_list=[];
    try{

        for(var ins in institutes){
          institutes_list.add(
              Institute(
                  id: ins.id,
                  insAdminId: insAdminId,
                  name: ins.name,
                  address: ins.address,
                  contact: ins.contact,
                  logo: ins.logo,
                  created_at: ins.created_at,
                  location: ins.location )//
          );
        }

     print("${institutes_list.length} institutes ............;;;;;..........");
      return institutes_list;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));

    }catch(e){
      print(e.toString());
    }
  }
  getStudentsList(String insAdminId,String instituteId){
    try{
      dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId)
          .collection("students")
          .snapshots().listen((qsnapShot){
        students.clear();
        if(qsnapShot.docs.isEmpty){
          return null;
        }
        for(var student in qsnapShot.docs){
          students.add(Student(
              id: student.id,
              instituteId: instituteId,
              insAdminId: insAdminId,
              role: student['role'],
              name: student['name'],
              email: student['email'],
              departId: student['depart_id'],
              sessionId: student['session_id'],
              semesterId: student['semester_id'],
              created_at: student['created_at'].toDate()));
        }
      });

      return students;
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("name :${ins_admins[0].name},email:${ins_admins[0].email},id:${ins_admins[0].institute_id},created_at:${ins_admins[0].created_at},last_login:${ins_admins[0].last_login} ")));

    }catch(e){
      print(e.toString());
    }
  }

  addInsAdmin(BuildContext context,InsAdmin _insAdmin)async{
    try{
      // InsAdmin insAdmin=InsAdmin(name: "Ameer Muawiya", email: "ameermuawiya34@gmail.com", created_at: DateTime.now(), last_login: DateTime.now(), status: "active");
      final insAdminsRef=await dbref.collection("ins_admins").doc(_insAdmin.id).set({
        "name":_insAdmin.name,
        "email":_insAdmin.email,
        "role":_insAdmin.role,
        "created_at":Timestamp.fromDate(_insAdmin.created_at!),//datetime to timestamp
        "last_login":Timestamp.fromDate(_insAdmin.last_login!),
        "status":_insAdmin.status
      });
      await indexDoc.doc(_insAdmin.id).set({
        "role":_insAdmin.role,
      });
      print("insAdmin Added Successfully");
      // if(context.mounted){
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ins Admin Added Successfully")));}
    }catch(e){
      print(e.toString());
      // if(context.mounted){
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
    }finally{

    }
  }
  addInstitute(BuildContext context,String insAdminId,Institute institute)async{
    try{
      // Institute institute1=Institute(name: "MPT", address: address, contact: contact, logo: logo, created_at: created_at, location: location)
      final insRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").add({
        "name":institute.name,
        "ins_admin_id":insAdminId,
        "address":institute.address,
        "contact":institute.contact,
        "logo":institute.logo,
        "created_at":Timestamp.fromDate(institute.created_at),//datetime to timestamp
        "location":{"lat":institute.location["lat"],"long":institute.location["long"]}
      });
      institute.id=insRef.id;
      await indexDoc.doc(institute.id).set({
        "ins_admin_id":insAdminId,
      });
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Institute Added Successfully")));}
    }catch(e){
      // print(e.toString());
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
    }finally{

    }
  }
  addDepartment(BuildContext context,String insAdminId,String instituteId,Department department)async{
    try{
      final depRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").add({
        "name":department.name,
        "created_at":Timestamp.fromDate(department.created_at!),//datetime to timestamp
        "hod_name":department.hod_name,
      });
      department.id=depRef.id;
      await indexDoc.doc(department.id).set({
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
      });
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("department Added Successfully")));}
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
    }finally{

    }
  }
  addAnnouncement(BuildContext context,String insAdminId,String instituteId,Announcement an1)async{
    try{
      final announceRef=await dbref
          .collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("announcements")
          .add({
        // Announcement(an_title: an_title, an_message: an_message, an_type: an_type, target_aud: target_aud)
           "title":an1.an_title,
           "content":an1.an_message,
           "type":an1.an_type,
           "target":an1.target_aud,
           "created_at":Timestamp.fromDate(an1.created_at!),//datetime to timestamp
          });
      an1.id=announceRef.id;
      await indexDoc.doc(an1.id).set({
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
      });
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("announcement Added Successfully")));}
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
    }finally{

    }
  }
  addSession(BuildContext context,String insAdminId,String instituteId,String departId,Session session)async{
    try{
      final sessionRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).collection("departments").
      doc(departId).collection("sessions").add({
        "name":session.name,
        "start_date":Timestamp.fromDate(session.start_date),//datetime to timestamp
        "end_date":Timestamp.fromDate(session.end_date),//datetime to timestamp
      });
      session.id=sessionRef.id;
      await indexDoc.doc(session.id).set({
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "department_id":departId,
      });
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("session Added Successfully")));}
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
    }finally{

    }
  }
  addSemester(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,Semester semester)async{
    try{
      final semesterRef=await dbref.
      collection("ins_admins").doc(insAdminId)
      .collection("institutes").doc(instituteId)
      .collection("departments").doc(departId)
      .collection("sessions").doc(sessionId)
      .collection("semesters").add({
        "start_date":Timestamp.fromDate(semester.start_date),//datetime to timestamp",
        "end_date":Timestamp.fromDate(semester.end_date),//datetime to timestamp",
        "semester_no":semester.semester_no,
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "department_id":departId,
        "session_id":sessionId,
      });
      semester.id=semesterRef.id;
      await indexDoc.doc(semester.id).set({
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "department_id":departId,
        "session_id":sessionId,
      });
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester Added Successfully")));}
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
    }finally{

    }
  }
  addCourse(BuildContext context,String insAdminId,String instituteId,String departId,String sessionId,String semesterId,Course course)async{
    try{
      final courseRef=await dbref.
      collection("ins_admins").doc(insAdminId)
      .collection("institutes").doc(instituteId)
      .collection("departments").doc(departId)
      .collection("sessions").doc(sessionId)
      .collection("semesters").doc(semesterId)
      .collection("courses")
      .add({
        // Subject(name: name, course_code: course_code, lecturer: lecturer, credit_hours: credit_hours, no_of_lectures: no_of_lectures, type: type)
       "name":course.name,
        "course_code":course.course_code,
        "lecturer_id":course.lecturer_id,
        "lecturer_name":course.lecturer_name,
        "credit_hours":course.credit_hours,
        "no_of_lectures":course.no_of_lectures,
        "type":course.type,
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "department_id":departId,
        "session_id":sessionId,
        "semester_id":semesterId,
        "created_at":Timestamp.fromDate(course.created_at!),//datetime to timestamp",
      });

      course.id=courseRef.id;
      await indexDoc.doc(course.id).set({
        "type":"course",
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "department_id":departId,
        "session_id":sessionId,
        "semester_id":semesterId,
        "lecturer_id":course.lecturer_id,
        "lecturer_name":course.lecturer_name,
      });
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Course Added Successfully")));}
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
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
      final lectureRef=await dbref.
      collection("ins_admins").doc(insAdminId)
          .collection("institutes").doc(instituteId)
          .collection("departments").doc(departId)
          .collection("sessions").doc(sessionId)
          .collection("semesters").doc(semesterId)
          .collection("courses")
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
         lectureModel.id=lectureRef.id;
         await indexDoc.doc(lectureModel.id).set({
           "ins_admin_id":insAdminId,
           "institute_id":instituteId,
           "department_id":departId,
           "session_id":sessionId,
           "semester_id":semesterId,
           "course_id":courseId,
         });
         if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture Added Successfully")));}
    }catch(e){
      if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));}
    }finally{

    }
  }
  addFaculty(BuildContext context,String insAdminId,String instituteId,String departId,Lecturer lecturer)async{
    try{
      final facRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      collection("departments").doc(departId).
      collection("faculty").doc(lecturer.id).set({
        // Lecturer(name: name, deprt: deprt, designation: designation, status: status, email: email, phone: phone)
        "name":lecturer.name,
        "email":lecturer.email,
        "depart":lecturer.deprt,
        "role":lecturer.role,
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "department_id":lecturer.departmentId,
        "designation":lecturer.designation,
        "status":lecturer.status,
        "created_at":Timestamp.fromDate(DateTime.now()),//datetime to timestamp",
        "semester":lecturer.semesters,
        "courses":lecturer.courses,
        "phone":lecturer.phone,
      });
      // Lecturer(name: name, deprt: deprt, role: role, insAdminId: insAdminId, instituteId: instituteId, departmentId: departmentId, designation: designation, status: status, email: email, phone: phone)
      print("faculty added.............................${lecturer.id}");
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("faculty Added Successfully")));
    }catch(e){print(e.toString());
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addStudent(BuildContext context,String insAdminId,String instituteId,Student student)async{
    try{
      final stdRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId)
      .collection("departments").doc(student.departId).
      collection("sessions").doc(student.sessionId).
      collection("semesters").doc(student.semesterId).
      collection("students").doc(student.id).set({
      // Student(role: '', insAdminId: '', instituteId: '', name: '', depart: '', semester: null, email: '')
        "name":student.name,
        "email":student.email,
        "department_id":student.departId,
        "session_id":student.sessionId,
        "semester_id":student.semesterId,
        "role":student.role,
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "created_at":Timestamp.fromDate(student.created_at!),//datetime to timestamp",
      });
      print("student added.............................${student.id}");
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student Added Successfully")));
    }catch(e){
      print(e.toString());
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addAdmin(BuildContext context,String insAdminId,String instituteId,Admin admin)async{
    try{
      final adminRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(admin.id).set({
        // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
        "name":admin.name,
        "institute_id":instituteId,
        "ins_admin_id":insAdminId,
        "email":admin.email,
        "institute":admin.institute,
        "role":admin.role,
        "status":admin.status,
        "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
        "permissions":admin.permissions//["student_management","department_management","lecture_management"] etc

      });
      print("admin added.............................");
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin Added Successfully")));
    }catch(e){
      print(e.toString());
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  addStudentLeaveApplication(BuildContext context,String insAdminId,String instituteId,LeaveApplication leaveApplication)async{
    try{
      final docRef = dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId)
          .collection("leave_applications").doc(); // generatting iD 1st
//used_batch cause of concurrnet write operations
      final batch = FirebaseFirestore.instance.batch();

      batch.set(docRef, {
        "start_date":Timestamp.fromDate(leaveApplication.fromDate),
        "end_date":Timestamp.fromDate(leaveApplication.tillDate),
        "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),
        "student_name":leaveApplication.std_name,
        "student_id":leaveApplication.std_id,
        "type":leaveApplication.type,
        "reason":leaveApplication.reason,
        "status":leaveApplication.status,
        "approved_by":leaveApplication.approvedby
      });

      batch.set(indexDoc.doc(docRef.id), {
        "ins_admin_id":insAdminId,
        "institute_id":instituteId,
        "student_id":leaveApplication.std_id,
      });

      await batch.commit(); // both writes succed, or neither does

      leaveApplication.id=docRef.id;
      notifyListeners();
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave applied Successfully")));
      }
    }catch(e){
      print(e.toString());
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
  //removing data from db
  removeInsAdmin(BuildContext context,String insAdminId)async{
    try{
      // InsAdmin insAdmin=InsAdmin(name: "Ameer Muawiya", email: "ameermuawiya34@gmail.com", created_at: DateTime.now(), last_login: DateTime.now(), status: "active");
      final insAdminsRef=await dbref.collection("ins_admins").doc(insAdminId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ins Admin deleted Successfully")));
      await indexDoc.doc(insAdminId).delete();
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeInstitute(BuildContext context,String instituteId)async{
    try{
      String insAdminId=await indexDoc.doc(instituteId).get().then((value) => value.get("ins_admin_id"));
      final insRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(instituteId).delete();
     await indexDoc.doc(instituteId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Institute deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeDepartment(BuildContext context,String departmentId)async{
    try{
      final dox=await indexDoc.doc(departmentId).get();
      final depRef=await dbref
          .collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(departmentId).delete();
      await indexDoc.doc(departmentId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("department deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeAnnouncement(BuildContext context,String announcementId)async{
    try{
      final dox=await indexDoc.doc(announcementId).get();
      final annRef=await dbref
          .collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("announcements")
          .doc(announcementId).delete();
      await indexDoc.doc(announcementId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("announcement deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeSession(BuildContext context,String sessionId)async{
    try{
      final dox=await indexDoc.doc(sessionId).get();
      final sessionRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").
      doc(dox.get("department_id")).collection("sessions").doc(sessionId).delete();
      await indexDoc.doc(sessionId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("session deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeSemester(BuildContext context,String semesterId)async{
    try{
      final dox=await indexDoc.doc(semesterId).get();
      final semRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes")
          .doc(dox.get("institute_id")).collection("departments").
           doc(dox.get("department_id")).collection("sessions")
          .doc(dox.get("session_id")).collection("semesters")
          .doc(semesterId).delete();
      await indexDoc.doc(semesterId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeCourse(BuildContext context,String courseId)async{
    try{
      final dox=await indexDoc.doc(courseId).get();
      final courseRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("courses")
          .doc(courseId).delete();
      await indexDoc.doc(courseId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Course deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeLecture(BuildContext context,String lectureModelId)async{
    try{

      final dox=await indexDoc.doc(lectureModelId).get();
      final LecRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("lectures")
          .doc(dox.get("course_id")).collection("lectures")
          .doc(lectureModelId).delete();
      await indexDoc.doc(lectureModelId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeFaculty(BuildContext context,String lecturerId)async{
    try{
      final dox=await indexDoc.doc(lecturerId).get();
      final facRefdoc=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).collection("departments")
      .doc(dox.get("department_id")).
      collection("faculty").doc(lecturerId).get();

      String email_d=await facRefdoc["email"];
      String password_d=await dox["password"];
      await deleteAuthUser(email_d, password_d);
      final facRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).collection("departments")
          .doc(dox.get("department_id")).
      collection("faculty").doc(lecturerId).delete();
      await indexDoc.doc(lecturerId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeStudent(BuildContext context,String studentId)async{
   try{
    final dox=await indexDoc.doc(studentId).get();
    final stdRefdoc=await dbref.collection("ins_admins")
        .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id"))
        .collection("departments").doc(dox.get("department_id"))
        .collection("sessions").doc(dox.get("session_id"))
        .collection("semesters").doc(dox.get("semester_id")).
    collection("students").doc(studentId).get();

    String email_d=await stdRefdoc["email"];
    String password_d=await dox["password"];
    await deleteAuthUser(email_d, password_d);
    final stdRef=await dbref.collection("ins_admins")
        .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id"))
        .collection("departments").doc(dox.get("department_id"))
        .collection("sessions").doc(dox.get("session_id"))
        .collection("semesters").doc(dox.get("semester_id")).
    collection("students").doc(studentId).delete();
    await indexDoc.doc(studentId).delete();
    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Student deleted Successfully")));
  }catch(e){
  if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }finally{

  }
  }
  removeAdmin(BuildContext context,String adminId)async{
    try{
      final dox=await indexDoc.doc(adminId).get();
      final adminRefdoc=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      collection("admins").doc(adminId).get();

      String email_d=await adminRefdoc["email"];
      String password_d=await dox["password"];
      await deleteAuthUser(email_d, password_d);
      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      collection("admins").doc(adminId).delete();
      await indexDoc.doc(adminId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  removeStudentLeaveApplication(BuildContext context,String leaveApplicationId)async{
    try{
      final dox=await indexDoc.doc(leaveApplicationId).get();
      final stdAppLevRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id"))
          .collection("leave_applications")
          .doc(leaveApplicationId).delete();
      await indexDoc.doc(leaveApplicationId).delete();
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leaveApplication deleted Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ins Admin updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateInstitute(BuildContext context,Institute institute)async{
    try{
      final dox=await indexDoc.doc(institute.id).get();
      String insAdminId=dox.get("ins_admin_id");
      // Institute institute1=Institute(name: "MPT", address: address, contact: contact, logo: logo, created_at: created_at, location: location)
      final insRef=await dbref.collection("ins_admins")
          .doc(insAdminId).collection("institutes").doc(institute.id).update({
        "name":institute.name,
        "ins_admin_id":insAdminId,
        "address":institute.address,
        "contact":institute.contact,
        "logo":institute.logo,
        "created_at":Timestamp.fromDate(institute.created_at),//datetime to timestamp
        "location":{
          "lat":institute.location["lat"],
          "long":institute.location["long"]}
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Institute updated Successfully")));
    }catch(e){
      print(e.toString());

      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateDepartment(BuildContext context,Department department)async{
    try{
      final dox=await indexDoc.doc(department.id).get();
      final depRef=await dbref
          .collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(department.id).update({
        "name":department.name,
        "created_at":Timestamp.fromDate(department.created_at!),//datetime to timestamp
        "hod_name":department.hod_name,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("department updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateAnnouncement(BuildContext context,Announcement announcement)async{
    try{
      final dox=await indexDoc.doc(announcement.id).get();
      final annRef=await dbref
          .collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("announcements")
          .doc(announcement.id).update({
        // Announcement(an_title: an_title, an_message: an_message, an_type: an_type, target_aud: target_aud)
        "title":announcement.an_title,
        "content":announcement.an_message,
        "type":announcement.an_type,
        "target":announcement.target_aud,
        "created_at":Timestamp.fromDate(announcement.created_at!),//datetime to timestamp
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("announcement updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateSession(BuildContext context,Session session)async{
    try{
      final dox=await indexDoc.doc(session.id).get();
      final sessionRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").
      doc(dox.get("department_id")).collection("sessions").doc(session.id).update({
        "name":session.name,
        "start_date":Timestamp.fromDate(session.start_date),//datetime to timestamp
        "end_date":Timestamp.fromDate(session.end_date),//datetime to timestamp
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("session updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateSemester(BuildContext context,Semester semester)async{
    try{
      final dox=await indexDoc.doc(semester.id).get();
      final semRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes")
          .doc(dox.get("institute_id")).collection("departments").
      doc(dox.get("department_id")).collection("sessions")
          .doc(dox.get("session_id")).collection("semesters").doc(semester.id).update({
        "start_date":Timestamp.fromDate(semester.start_date),//datetime to timestamp",
        "end_date":Timestamp.fromDate(semester.end_date),//datetime to timestamp",
        "semester_no":semester.semester_no
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("semester updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateCourse(BuildContext context,Course course)async{
    try{
      final dox=await indexDoc.doc(course.id).get();
      final courseRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("courses")
          .doc(course.id).update({
        "name":course.name,
        "ins_admin_id":course.insAdminId,
        "institute_id":course.institute_id,
        "department_id":course.department_id,
        "session_id":course.session_id,
        "course_code":course.course_code,
        "lecturer_id":course.lecturer_id,
        "lecturer_name":course.lecturer_name,
        "credit_hours":course.credit_hours,
        "no_of_lectures":course.no_of_lectures,
        "type":course.type,
        "created_at":Timestamp.fromDate(course.created_at!),//datetime to timestamp",
      });
      await indexDoc.doc(course.id).update({
        "lecturer_id":course.lecturer_id,
        "lecturer_name":course.lecturer_name,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Course updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateLecture(BuildContext context,LectureModel lectureModel)async{
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
      final dox=await indexDoc.doc(lectureModel.id).get();
      final lecRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("lectures")
          .doc(dox.get("course_id")).collection("lectures")
          .doc(lectureModel.id).update({
        "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        "students":lectureModel.students,
        "present":lectureModel.present,
        "absent":lectureModel.absent,
        "room":lectureModel.room,
        "course_name":lectureModel.course,//will take course_name using id back in ui
        "status":lectureModel.status,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendancePresent(BuildContext context,LectureModel lectureModel,String studentId)async{
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
      final dox=await indexDoc.doc(lectureModel.id).get();
      final lecRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("lectures")
          .doc(dox.get("course_id")).collection("lectures")
          .doc(lectureModel.id).update({
        "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        "students":lectureModel.students,
        "present":students_,
        "absent":lectureModel.absent,
        "room":lectureModel.room,
        "course_name":lectureModel.course,//will take course_name using id back in ui
        "status":lectureModel.status,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendancePresentGroup(BuildContext context,LectureModel lectureModel,List<String> studentIds)async{
    try{
      final dox=await indexDoc.doc(lectureModel.id).get();
      List<String> students_p=lectureModel.present!;
      for(int i=0;i<studentIds.length;i++){
        students_p.add(studentIds[i]);
      }
      // DateTime start_time_date=DateTime(
      //   lectureModel.dated.year,
      //   lectureModel.dated.month,
      //   lectureModel.dated.day,
      //   lectureModel.start_time.hour,
      //   lectureModel.start_time.minute,
      //
      // );
      // DateTime end_time_date=DateTime(
      //   lectureModel.dated.year,
      //   lectureModel.dated.month,
      //   lectureModel.dated.day,
      //   lectureModel.end_time.hour,
      //   lectureModel.end_time.minute,
      //
      // );
      final lecRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("lectures")
          .doc(dox.get("course_id")).collection("lectures")
          .doc(lectureModel.id).update({
        "present":students_p,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("lecture updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendanceAbsentGroup(BuildContext context,LectureModel lectureModel,List<String> studentIds)async{
    try{
      final dox=await indexDoc.doc(lectureModel.id).get();
      List<String> students_ab=lectureModel.absent!;
      for(int i=0;i<studentIds.length;i++){
        students_ab.add(studentIds[i]);
      }
      // DateTime start_time_date=DateTime(
      //   lectureModel.dated.year,
      //   lectureModel.dated.month,
      //   lectureModel.dated.day,
      //   lectureModel.start_time.hour,
      //   lectureModel.start_time.minute,
      //
      // );
      // DateTime end_time_date=DateTime(
      //   lectureModel.dated.year,
      //   lectureModel.dated.month,
      //   lectureModel.dated.day,
      //   lectureModel.end_time.hour,
      //   lectureModel.end_time.minute,
      //
      // );
      final lecRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("lectures")
          .doc(dox.get("course_id")).collection("lectures")
          .doc(lectureModel.id).update({
        "absent":students_ab,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("group attendance marked absent Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  markAttendanceAbsent(BuildContext context,LectureModel lectureModel,String studentId)async{
    try{
      final dox=await indexDoc.doc(lectureModel.id).get();
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
      final lecRef=await dbref.
      collection("ins_admins").doc(dox.get("ins_admin_id"))
          .collection("institutes").doc(dox.get("institute_id"))
          .collection("departments").doc(dox.get("department_id"))
          .collection("sessions").doc(dox.get("session_id"))
          .collection("semesters").doc(dox.get("semester_id"))
          .collection("lectures")
          .doc(dox.get("course_id")).collection("lectures")
          .doc(lectureModel.id).update({
        // "dated":Timestamp.fromDate(lectureModel.dated),//datetime to timestamp",
        // "start_time":Timestamp.fromDate(start_time_date),//datetime to timestamp",
        // "end_time":Timestamp.fromDate(end_time_date),//datetime to timestamp",
        // "students":lectureModel.students,
        // "present":lectureModel.present,
        "absent":students_abs,
        // "room":lectureModel.room,
        // "course_name":lectureModel.course,//will take course_name using id back in ui
        // "status":lectureModel.status,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("attendance marked Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateFaculty(BuildContext context,Lecturer lecturer)async{
    try{
      final dox=await indexDoc.doc(lecturer.id).get();
      final facRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes")
          .doc(dox.get("institute_id")).
      collection("departments").doc(dox.get("department_id")).
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
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("faculty updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateStudent(BuildContext context,Student student)async{
    try{
      final dox=await indexDoc.doc(student.id).get();
      final stfRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
          collection("departments").doc(dox.get("department_id")).
          collection("sessions").doc(dox.get("session_id")).
          collection("semesters").doc(dox.get("semester_id")).
      collection("students").doc(student.id).update({
        // Student(name: name, depart: depart, semester: semester, email: email)
        "name":student.name,
        "created_at":Timestamp.fromDate(student.created_at!),//datetime to timestamp",
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student data updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateAdmin(BuildContext context,Admin admin)async{
    try{
      final dox=await indexDoc.doc(admin.id).get();
      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
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
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Admin data added Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  assignPermissionsAdmin(BuildContext context,Admin admin,String permission)async{
    try{
      final dox=await indexDoc.doc(admin.id).get();
      List<String> permissions_=admin.permissions!;
      if(permissions_.contains(permission)){
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("permission already assigned")));
      return;
      }
        permissions_.add(permission);

      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(admin.id).update({
        // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
        // "name":admin.name,
        // "email":admin.email,
        // "institute":admin.institute,
        // "role":admin.role,
        // "status":admin.status,
        // "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
        "permissions":permissions_//["student_management","department_management","lecture_management"] etc

      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("permission assigned Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  revokePermissionsAdmin(BuildContext context,Admin admin,String permission)async{
    try{
      final dox=await indexDoc.doc(admin.id).get();
      List<String> permissions_=admin.permissions!;
      if(permissions_.isEmpty){
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("no permissions found")));
      return;
      }else if(permissions_.contains(permission)){
        permissions_.remove(permission);
      }else{
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("permission not found")));
        return;
      }

      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(admin.id).update({
        // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
        // "name":admin.name,
        // "email":admin.email,
        // "institute":admin.institute,
        // "role":admin.role,
        // "status":admin.status,
        // "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
        "permissions":permissions_//["student_management","department_management","lecture_management"] etc

      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("permission revoked Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  revokeAllPermissionsAdmin(BuildContext context,Admin admin)async{
    try{
      final dox=await indexDoc.doc(admin.id).get();
      List<String> permissions_=admin.permissions!;
      if(permissions_.isEmpty){
        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("no permissions found")));
       return;
      }
      permissions_.clear();
      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      collection("admins").doc(admin.id).update({
        // Admin(name: name, email: email, institute: institute, role: role, status: status,permissions: )
        // "name":admin.name,
        // "email":admin.email,
        // "institute":admin.institute,
        // "role":admin.role,
        // "status":admin.status,
        // "created_at":Timestamp.fromDate(admin.created_at),//datetime to timestamp",
        "permissions":permissions_//["student_management","department_management","lecture_management"] etc

      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Revoked all permissions Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  updateStudentLeaveApplication(BuildContext context,LeaveApplication leaveApplication)async{
    try{
      final dox=await indexDoc.doc(leaveApplication.id).get();
      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      // collection("students").doc(dox.get("student_id")).
      collection("leave_applications")
          .doc(leaveApplication.id).update({
        // LeaveApplication(appliedDate: appliedDate, type: type, fromDate: fromDate,
        // tillDate: tillDate, reason: reason, status: status, std_name: std_name, std_id: std_id)
        "start_date":Timestamp.fromDate(leaveApplication.fromDate),//datetime to timestamp",
        "end_date":Timestamp.fromDate(leaveApplication.tillDate),//datetime to timestamp",
        "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),//datetime to timestamp","
        "student_name":leaveApplication.std_name,
        "student_id":leaveApplication.std_id,
        "type":leaveApplication.type,
        "reason":leaveApplication.reason,
        "status":leaveApplication.status,
        "approved_by":leaveApplication.approvedby,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave updated Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  approveStudentLeaveApplication(BuildContext context,LeaveApplication leaveApplication,String adminName)async{
    try{
      final dox=await indexDoc.doc(leaveApplication.id).get();
      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      // collection("students").doc(dox.get("student_id")).
      collection("leave_applications")
          .doc(leaveApplication.id).update({
        // LeaveApplication(appliedDate: appliedDate, type: type, fromDate: fromDate,
        // tillDate: tillDate, reason: reason, status: status, std_name: std_name, std_id: std_id)
        // "start_date":Timestamp.fromDate(leaveApplication.fromDate),//datetime to timestamp",
        // "end_date":Timestamp.fromDate(leaveApplication.tillDate),//datetime to timestamp",
        // "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),//datetime to timestamp","
        // "std_name":leaveApplication.std_name,
        // "std_id":leaveApplication.std_id,
        // "type":leaveApplication.type,
        // "reason":leaveApplication.reason,
        "status":"approved",
        "approved_by":adminName,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave approved Successfully")));
    }catch(e){
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }
  rejectStudentLeaveApplication(BuildContext context,LeaveApplication leaveApplication,String adminName)async{
    try{
      final dox=await indexDoc.doc(leaveApplication.id).get();
      final adminRef=await dbref.collection("ins_admins")
          .doc(dox.get("ins_admin_id")).collection("institutes").doc(dox.get("institute_id")).
      // collection("departments").doc(departId).
      // collection("sessions").doc(sessionId).
      // collection("semesters").doc(semesterId).
      // collection("students").doc(dox.get("student_id")).
      collection("leave_applications")
          .doc(leaveApplication.id).update({
        // LeaveApplication(appliedDate: appliedDate, type: type, fromDate: fromDate,
        // tillDate: tillDate, reason: reason, status: status, std_name: std_name, std_id: std_id)
        // "start_date":Timestamp.fromDate(leaveApplication.fromDate),//datetime to timestamp",
        // "end_date":Timestamp.fromDate(leaveApplication.tillDate),//datetime to timestamp",
        // "applied_date":Timestamp.fromDate(leaveApplication.appliedDate),//datetime to timestamp","
        // "std_name":leaveApplication.std_name,
        // "std_id":leaveApplication.std_id,
        // "type":leaveApplication.type,
        // "reason":leaveApplication.reason,
        "status":"rejected",
        "approved_by":adminName,
      });
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("student leave rejected")));
    }catch(e){
      print(e.toString());
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }finally{

    }
  }

}