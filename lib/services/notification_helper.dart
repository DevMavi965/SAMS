import 'dart:io';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotifHelper {
  static FlutterLocalNotificationsPlugin notificationsPlugin=FlutterLocalNotificationsPlugin();
  static Future<void> initialize() async {
    AndroidInitializationSettings android = AndroidInitializationSettings("@mipmap/ic_launcher");
    DarwinInitializationSettings ios = DarwinInitializationSettings();
    WebInitializationSettings web = WebInitializationSettings();
    tz.initializeTimeZones();
    InitializationSettings settings = InitializationSettings(
        android: android, iOS: ios, web: web);
    await notificationsPlugin.initialize(settings: settings);
    if (Platform.isAndroid) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>
        ()?.requestNotificationsPermission();
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>
        ()?.requestExactAlarmsPermission();

    } else if (Platform.isIOS) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>
        ()?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }
  static Future<void> show(String channel,String title,String body)async{
    AndroidNotificationDetails android=AndroidNotificationDetails(
        "channelId",
        priority: Priority.high,
        importance: Importance.max,
        channel);
    DarwinNotificationDetails ios=DarwinNotificationDetails();
    WebNotificationDetails web=WebNotificationDetails();
    NotificationDetails notificationDetails=NotificationDetails(
        android: android,
        iOS: ios
    );

    notificationsPlugin.show(
        id:Random().nextInt(1000),
        title: title,
        body:body,
        notificationDetails: notificationDetails
    );
  }
  static Future<void> scheduledNotification(String channel, String title, String body, DateTime dt,int id) async {
    AndroidNotificationDetails android = AndroidNotificationDetails("channelId", channel);
    DarwinNotificationDetails ios = DarwinNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(android: android, iOS: ios);

    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(dt, tz.local);
    debugPrint("SCHEDULING '$title' at $scheduledTime, now: ${tz.TZDateTime.now(tz.local)}");

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("SKIPPED — time already passed");
      return;
    }

    await notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }}