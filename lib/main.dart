import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:path_provider/path_provider.dart';

// ✅ Import our new organized files
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/motivator_home.dart';
import 'screens/amber_alert_screen.dart';
import 'services/motivator_api.dart';
import 'services/amber_alert_service.dart';
import 'services/notification_manager.dart'; // ✅ ADD THIS IMPORT

// 🚨 Global navigator key for amber alerts
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize Awesome Notifications BEFORE runApp - ENHANCED FOR AMBER ALERTS
  await AwesomeNotifications().initialize(
    null,
    [
      // 🔥 BASIC CHANNEL (Keep existing for fallback)
      NotificationChannel(
        channelKey: 'test_channel',
        channelName: 'Test Notifications',
        channelDescription: 'Channel for testing notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.teal,
        ledColor: Colors.white,
        playSound: true,
        enableVibration: true,
      ),
      
      // 🚨 ENHANCED AMBER ALERT CHANNEL
      NotificationChannel(
      channelKey: 'amber_alert_channel',
      channelName: '🚨 Critical Motivational Alerts',
      channelDescription: 'Emergency-level motivational notifications that bypass silent mode',
      importance: NotificationImportance.Max,
      defaultColor: Colors.red,
      ledColor: Colors.red,
      playSound: true,
      enableVibration: true,
      criticalAlerts: true,
      enableLights: true,
      channelShowBadge: true,
      onlyAlertOnce: false,
      locked: true,
      // 🚨 ADD THESE CRITICAL FLAGS:
      defaultRingtoneType: DefaultRingtoneType.Alarm,
      groupAlertBehavior: GroupAlertBehavior.All,
      groupSort: GroupSort.Desc,
    ),
      
      // 🔔 REGULAR MOTIVATIONAL REMINDERS (Keep existing)
      NotificationChannel(
        channelKey: 'motivator_reminders',
        channelName: 'Motivational Reminders',
        channelDescription: 'Personalized motivational notifications with audio',
        importance: NotificationImportance.Max,
        defaultColor: Colors.tealAccent,
        ledColor: Colors.white,
        playSound: true,
        enableVibration: true,
      ),
    ],
    debug: true,
  );
  print("✅ AwesomeNotifications initialized with Amber Alert support.");
  
  // 🚨 FIX #1: SET UP NOTIFICATION MANAGER WITH NAVIGATOR KEY
  NotificationManager.instance.setNavigatorKey(navigatorKey);
  print("✅ NotificationManager navigator key set.");
  
  // 🚨 FIX #2: SET UP NOTIFICATION LISTENERS  
  NotificationManager.instance.setupNotificationListeners();
  print("✅ NotificationManager listeners set up.");
  
  // Initialize timezone data after AwesomeNotifications
  tz.initializeTimeZones();
  
  // ✅ THEN run the app
  runApp(const MotivatorApp());
}

// ===== ENHANCED PERMISSION HANDLING FOR AMBER ALERTS =====
Future<void> _requestAwesomeNotificationPermissions() async {
  print("🔐 Requesting enhanced notification permissions for Amber Alerts...");
  
  // 1. Basic notification permission
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
  }
  
  if (isAllowed) {
    print('✅ Basic notification permissions granted');
    
    // 2. Request critical alert permissions (iOS specific but doesn't hurt on Android)
    try {
      // This is mainly for iOS critical alerts
      await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'amber_alert_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.CriticalAlert, // 🚨 CRITICAL for amber alerts
          NotificationPermission.FullScreenIntent, // 🚨 CRITICAL for lock screen
        ],
      );
      print('✅ Critical alert permissions requested');
    } catch (e) {
      print('⚠️ Critical alert permission request failed (might not be supported): $e');
    }
    
    // 3. Request additional Android permissions
    if (Platform.isAndroid) {
      try {
        // Request system alert window permission for full screen alerts
        await Permission.systemAlertWindow.request();
        print('✅ System alert window permission requested');
        
        // Request do not disturb access
        await Permission.accessNotificationPolicy.request();
        print('✅ Do not disturb access requested');
        
        // Request schedule exact alarm permission (Android 12+)
        await Permission.scheduleExactAlarm.request();
        print('✅ Exact alarm permission requested');
        
      } catch (e) {
        print('⚠️ Additional Android permissions error: $e');
      }
    }
    
  } else {
    print('❌ Basic notification permissions denied');
  }
}

class MotivatorApp extends StatelessWidget {
  const MotivatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motivator.AI',
      navigatorKey: navigatorKey, // 🚨 Global navigator key for amber alerts
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}