import 'dart:io';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotifHelper {
  static const _prefsKey = "notifications_enabled";
  static FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Whether the user has notifications turned on. Defaults to true so
  /// existing installs don't go silent until the user actively toggles it.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  /// Persists the on/off choice, and — when turning notifications off —
  /// cancels everything already scheduled so the toggle takes effect
  /// immediately instead of waiting for each pending one to fire anyway.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    if (!enabled) {
      await notificationsPlugin.cancelAll();
    }
  }

  static Future<void> initialize() async {
    AndroidInitializationSettings android = AndroidInitializationSettings("@mipmap/ic_launcher");
    DarwinInitializationSettings ios = DarwinInitializationSettings();
    WebInitializationSettings web = WebInitializationSettings();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    InitializationSettings settings = InitializationSettings(
        android: android, iOS: ios, web: web);
    await notificationsPlugin.initialize(settings: settings);
    if (Platform.isAndroid) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> show(String channel, String title, String body) async {
    if (!await isEnabled()) return;
    AndroidNotificationDetails android = AndroidNotificationDetails(
        "channelId",
        priority: Priority.high,
        importance: Importance.max,
        channel);
    DarwinNotificationDetails ios = DarwinNotificationDetails();
    WebNotificationDetails web = WebNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(android: android, iOS: ios);

    notificationsPlugin.show(
        id: Random().nextInt(1000),
        title: title,
        body: body,
        notificationDetails: notificationDetails);
  }

  static Future<void> scheduledNotification(String channel, String title, String body, DateTime dt, int id) async {
    if (!await isEnabled()) return;
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
  }
}