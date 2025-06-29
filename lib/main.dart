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
import 'package:workmanager/workmanager.dart'; // 🚨 NEW: WorkManager import

// ✅ Import our new organized files
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/motivator_home.dart';
import 'screens/amber_alert_screen.dart';
import 'services/motivator_api.dart';
import 'services/amber_alert_service.dart';
import 'services/notification_manager.dart';

// 🚨 Global navigator key for amber alerts
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🚨 NEW: WorkManager callback dispatcher for background amber alerts
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 WorkManager executing background task: $task');
    
    try {
      if (task == 'amberAlert') {
        print('🚨 WorkManager triggering amber alert from background');
        await _triggerBackgroundAmberAlert(inputData);
        return Future.value(true);
      }
      
      if (task == 'precisionAmberAlert') {
        print('🎯 WorkManager triggering precision amber alert');
        await _triggerPrecisionAmberAlert(inputData);
        return Future.value(true);
      }
      
      // Handle other background tasks here
      print('⚠️ Unknown WorkManager task: $task');
      return Future.value(false);
      
    } catch (e) {
      print('❌ WorkManager task failed: $e');
      return Future.value(false);
    }
  });
}

// 🚨 NEW: Background amber alert trigger
Future<void> _triggerBackgroundAmberAlert(Map<String, dynamic>? inputData) async {
  if (inputData == null) {
    print('❌ No input data for background amber alert');
    return;
  }
  
  print('🚨 Triggering background amber alert');
  print('📋 Task: ${inputData['taskDescription']}');
  
  try {
    // Create immediate notification to wake the app
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 2147483647,
        channelKey: 'amber_alert_channel',
        title: '🚨 BACKGROUND EMERGENCY ALERT 🚨',
        body: '${inputData['taskDescription']}\n\nTap to open full alert!',
        payload: {
          'triggerAmberAlert': 'true',
          'taskDescription': inputData['taskDescription'] ?? 'Background Alert',
          'motivationalLine': inputData['motivationalLine'] ?? 'Critical alert!',
          'audioFilePath': inputData['audioPath'] ?? '',
          'backgroundTriggered': 'true',
          'workManagerDelivery': 'true',
        },
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        category: NotificationCategory.Alarm,
        color: Colors.red,
        displayOnForeground: true,
        displayOnBackground: true,
        locked: true,
      ),
    );
    
    print('✅ Background amber alert notification created');
    
    // Try to trigger system vibration if possible
    try {
      // This might not work in background, but worth trying
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('⚠️ Could not trigger haptic feedback from background: $e');
    }
    
  } catch (e) {
    print('❌ Failed to trigger background amber alert: $e');
  }
}

// 🚨 NEW: Precision amber alert trigger (for immediate execution)
Future<void> _triggerPrecisionAmberAlert(Map<String, dynamic>? inputData) async {
  if (inputData == null) {
    print('❌ No input data for precision amber alert');
    return;
  }
  
  print('🎯 Triggering precision amber alert');
  
  try {
    // Create immediate high-priority notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 2147483647,
        channelKey: 'amber_alert_channel',
        title: '🎯 PRECISION EMERGENCY ALERT 🎯',
        body: '${inputData['taskDescription']}\n\nDelivered with precision timing!',
        payload: {
          'triggerAmberAlert': 'true',
          'taskDescription': inputData['taskDescription'] ?? 'Precision Alert',
          'motivationalLine': inputData['motivationalLine'] ?? 'Precision alert!',
          'audioFilePath': inputData['audioPath'] ?? '',
          'precisionDelivery': 'true',
          'deliveredAt': DateTime.now().toIso8601String(),
        },
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        category: NotificationCategory.Alarm,
        color: Colors.orange,
        displayOnForeground: true,
        displayOnBackground: true,
        locked: true,
      ),
    );
    
    print('✅ Precision amber alert delivered successfully');
    
  } catch (e) {
    print('❌ Failed to trigger precision amber alert: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting MotivatorAI with enhanced amber alert system...');
  
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
      
      // 🔔 BASIC CHANNEL
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Standard notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        playSound: true,
        enableVibration: true,
      ),
    ],
    debug: true,
  );
  print("✅ AwesomeNotifications initialized with enhanced amber alert support");
  
  // 🚨 NEW: Initialize WorkManager for background amber alerts
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false for production
    );
    print("✅ WorkManager initialized for background amber alerts");
  } catch (e) {
    print("⚠️ WorkManager initialization failed: $e");
    print("   Continuing without WorkManager support...");
  }
  
  // 🚨 FIX #1: SET UP NOTIFICATION MANAGER WITH NAVIGATOR KEY
  NotificationManager.instance.setNavigatorKey(navigatorKey);
  print("✅ NotificationManager navigator key set");
  
  // 🚨 FIX #2: SET UP NOTIFICATION LISTENERS  
  NotificationManager.instance.setupNotificationListeners();
  print("✅ NotificationManager listeners set up");
  
  // Initialize timezone data after AwesomeNotifications
  tz.initializeTimeZones();
  print("✅ Timezone data initialized");
  
  // 🚨 Request enhanced permissions for amber alerts
  await _requestEnhancedPermissions();
  
  // ✅ THEN run the app
  runApp(const MotivatorApp());
}

// ===== ENHANCED PERMISSION HANDLING FOR AMBER ALERTS =====
Future<void> _requestEnhancedPermissions() async {
  print("🔐 Requesting enhanced permissions for amber alerts...");
  
  try {
    // 1. Basic notification permission
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    
    if (isAllowed) {
      print('✅ Basic notification permissions granted');
      
      // 2. Request critical alert permissions
      try {
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
        print('⚠️ Critical alert permission request failed: $e');
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
          
          // 🔋 Request battery optimization exemption
          await Permission.ignoreBatteryOptimizations.request();
          print('✅ Battery optimization exemption requested');
          
        } catch (e) {
          print('⚠️ Additional Android permissions error: $e');
        }
      }
      
    } else {
      print('❌ Basic notification permissions denied');
    }
  } catch (e) {
    print('❌ Error requesting permissions: $e');
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