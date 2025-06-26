import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class AmberAlertService {
  
  // ===== BASIC NOTIFICATION TESTS =====
  
  static Future<void> testNotificationWithoutPayload(BuildContext context) async {
    print("🧪 Testing basic notification WITHOUT payload...");
    
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10)); // Reduced to 10 seconds for testing
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'test_channel', // Using basic channel
        title: '🧪 Basic Test',
        body: 'Simple test - no payload',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
    
    print("✅ Scheduled basic test notification for $scheduledTime");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Basic notification scheduled for 10 seconds'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  static Future<void> testNotificationWithSimplePayload(BuildContext context) async {
    print("🧪 Testing enhanced notification WITH simple payload...");
    
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10));
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 998,
        channelKey: 'motivator_reminders', // Using enhanced channel
        title: '🧪 Enhanced Test',
        body: 'Enhanced test - basic payload',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        payload: {'data': 'simple_string_test'},
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
    
    print("✅ Scheduled enhanced test notification with simple payload");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Enhanced payload test scheduled for 10 seconds'),
        backgroundColor: Colors.green,
      ),
    );
  }

  static Future<void> testNotificationWithJsonPayload(BuildContext context) async {
    print("🧪 Testing full payload notification...");
    
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10));
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 997,
        channelKey: 'motivator_reminders',
        title: '🧪 Full Test',
        body: 'Full payload data test with wake up',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: true,
        payload: {
          'taskDescription': 'Test Task with Full Features',
          'motivationalLine': 'You can do this! This is a full test!',
          'audioFilePath': '/test/path/full_audio.mp3',
          'forceOverrideSilent': 'true',
        },
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
    
    print("✅ Scheduled full test notification with payload data");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Full payload test scheduled for 10 seconds'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ===== AMBER ALERT TESTS =====
  
  // 🚨 ENHANCED TRUE AMBER ALERT TEST
  static Future<void> testAmberAlertNotification(BuildContext context) async {
    print("🚨 Starting TRUE AMBER ALERT test...");
    
    // 1. Check all permissions first
    await checkAllPermissions(context);
    
    // 2. Check if notifications are actually allowed
    final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    print("🔐 Notification permission status: $isAllowed");
    
    if (!isAllowed) {
      print("❌ Notifications not allowed - requesting permission");
      final granted = await AwesomeNotifications().requestPermissionToSendNotifications();
      print("🔐 Permission request result: $granted");
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Notification permissions denied! Cannot test amber alerts.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // 3. Check battery optimization
    await checkBatteryOptimization(context);
    
    // 4. Schedule with IMMEDIATE delivery (2 seconds)
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 2));
    
    print("🚨 Scheduling TRUE AMBER ALERT for: $scheduledTime");
    print("🚨 ALERT SCREEN WILL AUTO-APPEAR (NO TAP REQUIRED)");
    
    try {
      // 5. Create with MAXIMUM URGENCY and FULL SCREEN TAKEOVER
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 995,
          channelKey: 'amber_alert_channel',
          
          // 🚨 AMBER ALERT STYLING
          title: '🚨 EMERGENCY ALERT 🚨',
          body: 'CRITICAL MOTIVATIONAL EMERGENCY\nScreen will hijack automatically!',
          summary: 'EMERGENCY ALERT SYSTEM',
          
          // 🚨 FULL SCREEN LAYOUT
          notificationLayout: NotificationLayout.BigText,
          
          // 🚨 MAXIMUM URGENCY FLAGS
          category: NotificationCategory.Alarm, // Critical for full screen
          wakeUpScreen: true,
          fullScreenIntent: true, // KEY: Forces full screen
          locked: false, // Allow dismissal for testing
          criticalAlert: true,
          autoDismissible: false,
          
          // 🚨 VISIBILITY FLAGS
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
          
          // 🚨 VISUAL STYLING
          color: Colors.red,
          
          payload: {
            'taskDescription': 'CRITICAL: Test the auto-hijack amber alert system',
            'motivationalLine': 'This alert should automatically take over your screen without requiring any taps!',
            'audioFilePath': '/test/path/emergency_audio.mp3',
            'forceOverrideSilent': 'true',
            'isAmberAlert': 'true',
            'testMode': 'full_screen',
            'emergency': 'true', // 🚨 KEY: This triggers auto-display
          },
        ),
        
        // 🚨 IMMEDIATE SCHEDULING
        schedule: NotificationCalendar.fromDate(date: scheduledTime),
      );
      
      print("✅ TRUE Amber alert scheduled successfully");
      print("📱 INSTRUCTIONS: Turn off screen NOW and wait 2 seconds");
      print("🚨 Expected: AUTOMATIC SCREEN HIJACK (NO TAP REQUIRED)");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚨 AUTO-HIJACK AMBER ALERT scheduled for 2 seconds'),
              const Text('📱 Turn off screen NOW - will AUTO-APPEAR!'),
              const Text('🚨 NO TAPPING REQUIRED - AUTOMATIC TAKEOVER!'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => openDeviceSettings(context),
                child: const Text('Open Settings if Needed'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      
    } catch (e) {
      print("❌ Error scheduling TRUE amber alert: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🆕 ALTERNATIVE TEST: Immediate notification (no scheduling)
  static Future<void> testImmediateAmberAlert(BuildContext context) async {
    print("🚨 Testing IMMEDIATE amber alert (no scheduling)...");
    
    try {
      // Create notification immediately without scheduling
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 994,
          channelKey: 'amber_alert_channel',
          title: '🚨 IMMEDIATE AMBER ALERT',
          body: 'This should appear instantly!',
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          displayOnForeground: true,
          displayOnBackground: true,
          payload: {
            'emergency': 'true', // 🚨 IMPORTANT: Include this
            'isAmberAlert': 'true',
            'taskDescription': 'Immediate amber alert test',
            'motivationalLine': 'This is an immediate amber alert test!',
          },
        ),
        // No schedule = immediate delivery
      );
      
      print("✅ Immediate amber alert created");
      
    } catch (e) {
      print("❌ Error creating immediate amber alert: $e");
    }
  }

  // 🆕 NEW: Test Immediate Auto-Hijack Alert
  static Future<void> testImmediateAutoHijackAlert(BuildContext context) async {
    print("🚨 Testing IMMEDIATE AUTO-HIJACK amber alert...");
    
    try {
      // Create notification that will auto-hijack immediately
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 989,
          channelKey: 'amber_alert_channel',
          title: '🚨 IMMEDIATE AUTO-HIJACK TEST',
          body: 'Screen should hijack NOW without any delay!',
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          displayOnForeground: true,
          displayOnBackground: true,
          payload: {
            'taskDescription': 'IMMEDIATE TEST: Auto-hijack verification',
            'motivationalLine': 'This alert hijacked your screen immediately with no delay!',
            'emergency': 'true', // 🚨 KEY: Triggers auto-display
            'isAmberAlert': 'true',
            'testMode': 'immediate_hijack',
          },
        ),
        // No schedule = immediate delivery and auto-hijack
      );
      
      print("✅ Immediate auto-hijack alert created - should appear NOW");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Immediate auto-hijack triggered - screen should takeover NOW!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print("❌ Error creating immediate auto-hijack alert: $e");
    }
  }

  // 🆕 ALTERNATIVE TEST: Native Android Alarm Alert
  static Future<void> testNativeAlarmAlert(BuildContext context) async {
    print("🚨 Testing NATIVE ANDROID ALARM alert...");
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 993,
          channelKey: 'amber_alert_channel',
          
          // 🚨 NATIVE ALARM STYLING
          title: '⚠️ SYSTEM ALARM ⚠️',
          body: 'EMERGENCY SYSTEM NOTIFICATION\nThis should take over your screen!',
          
          // 🚨 NATIVE ALARM CATEGORY
          category: NotificationCategory.Alarm,
          notificationLayout: NotificationLayout.BigText,
          
          // 🚨 MAXIMUM OVERRIDE FLAGS
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          locked: false,
          autoDismissible: false,
          
          // 🚨 ALARM SPECIFIC SETTINGS
          showWhen: true,
          
          // 🚨 VISUAL IMPACT
          color: Colors.red,
          actionType: ActionType.Default,
          
          payload: {
            'alertType': 'native_alarm',
            'priority': 'maximum',
            'override': 'all_settings',
            'emergency': 'true', // 🚨 IMPORTANT: Include this
            'isAmberAlert': 'true',
          },
        ),
        // No schedule = immediate
      );
      
      print("✅ Native alarm alert created immediately");
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Native alarm alert triggered immediately!'),
          backgroundColor: Colors.orange,
        ),
      );
      
    } catch (e) {
      print("❌ Error creating native alarm: $e");
    }
  }

  // 🆕 ULTIMATE TEST: Continuous alarm-style notification
  static Future<void> testContinuousAlarm(BuildContext context) async {
    print("🚨 Testing CONTINUOUS ALARM style notification...");
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 992,
          channelKey: 'amber_alert_channel',
          
          // 🚨 CONTINUOUS ALARM
          title: '🔴 CONTINUOUS EMERGENCY ALERT 🔴',
          body: 'This alert will persist until you respond!\nSwipe to dismiss.',
          
          // 🚨 PERSISTENT ALARM SETTINGS
          category: NotificationCategory.Alarm,
          notificationLayout: NotificationLayout.BigText,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          
          // 🚨 PERSISTENT FLAGS
          locked: true, // Harder to dismiss
          autoDismissible: false,
          showWhen: true,
          
          // 🚨 MAXIMUM VISUAL IMPACT
          color: Colors.red,
          
          // 🚨 ACTION BUTTONS FOR RESPONSE
          actionType: ActionType.Default,
          
          payload: {
            'alertType': 'continuous_alarm',
            'requires_response': 'true',
            'emergency_level': 'maximum',
            'emergency': 'true', // 🚨 IMPORTANT: Include this
            'isAmberAlert': 'true',
            'strategy': 'C', // Add strategy field
          },
        ),
        // Immediate delivery
      );
      
      print("✅ Continuous alarm created - should be persistent");
      
      // Start vibration pattern for continuous alarm
      startContinuousVibration();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔴 Continuous alarm with vibration started!'),
          backgroundColor: Colors.red,
        ),
      );
      
    } catch (e) {
      print("❌ Error creating continuous alarm: $e");
    }
  }

  // 🆕 Helper: Continuous vibration for true emergency feel
  static void startContinuousVibration() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      HapticFeedback.heavyImpact();
      
      // Stop after 10 vibrations (for testing)
      if (timer.tick >= 10) {
        timer.cancel();
        print("🚨 Continuous vibration stopped after 10 cycles");
      }
    });
  }

  // ===== ULTIMATE AMBER ALERT TESTS =====

  // 🚨 ULTIMATE TEST: True Full Screen Amber Alert
  static Future<void> testTrueFullScreenAmberAlert(BuildContext context) async {
    print("🚨 Testing ULTIMATE FULL SCREEN amber alert...");
    
    // 1. Request special permissions first
    await requestFullScreenPermissions(context);
    
    // 2. Test Strategy A: Enhanced Full Screen Intent
    await createFullScreenIntentNotification(context);
    
    // 3. Wait 3 seconds, then try Strategy B if needed
    await Future.delayed(const Duration(seconds: 3));
    await createSystemOverlayAlert(context);
  }

  // 🔐 Request full-screen specific permissions
  static Future<void> requestFullScreenPermissions(BuildContext context) async {
    print("🔐 Requesting full-screen permissions...");
    
    try {
      // Request system alert window (overlay) permission
      final overlayStatus = await Permission.systemAlertWindow.request();
      print("🔐 System overlay permission: $overlayStatus");
      
      // Request ignore battery optimizations
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      print("🔐 Battery optimization permission: $batteryStatus");
      
      // Show user instructions if permissions denied
      if (overlayStatus.isDenied) {
        showPermissionInstructions(context);
      }
      
    } catch (e) {
      print("⚠️ Error requesting full-screen permissions: $e");
    }
  }

  // 🚨 Strategy A: Enhanced Full Screen Intent Notification
  static Future<void> createFullScreenIntentNotification(BuildContext context) async {
    print("🚨 Creating enhanced full-screen intent notification...");
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 991,
          channelKey: 'amber_alert_channel',
          
          // 🚨 EMERGENCY STYLING
          title: '🚨 EMERGENCY MOTIVATIONAL ALERT 🚨',
          body: 'CRITICAL ALERT: Your immediate attention is required!\n\nTap to respond to this emergency notification.',
          summary: 'EMERGENCY ALERT SYSTEM',
          
          // 🚨 MAXIMUM VISIBILITY SETTINGS
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Alarm,
          
          // 🚨 FULL SCREEN SETTINGS
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          
          // 🚨 PERSISTENCE SETTINGS
          locked: false, // Allow dismissal for testing
          autoDismissible: false,
          
          // 🚨 VISIBILITY FLAGS
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
          
          // 🚨 VISUAL IMPACT
          color: Colors.red,
          backgroundColor: Colors.red,
          actionType: ActionType.Default,
          
          payload: {
            'alertType': 'full_screen_intent',
            'emergency': 'true',
            'priority': 'maximum',
            'strategy': 'A',
            'isAmberAlert': 'true',
            'taskDescription': 'Full screen intent test',
            'motivationalLine': 'This is a full screen intent amber alert test!',
          },
        ),
        // No schedule = immediate
      );
      
      print("✅ Enhanced full-screen intent notification created");
      
    } catch (e) {
      print("❌ Error creating full-screen intent: $e");
    }
  }

  // 🚨 Strategy B: System Overlay Alert (Alternative approach)
  static Future<void> createSystemOverlayAlert(BuildContext context) async {
    print("🚨 Creating system overlay alert as fallback...");
    
    try {
      // Check if we have overlay permission
      final hasOverlayPermission = await Permission.systemAlertWindow.isGranted;
      
      if (hasOverlayPermission) {
        // Create a persistent, high-priority notification
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 990,
            channelKey: 'amber_alert_channel',
            
            // 🚨 SYSTEM-LEVEL EMERGENCY
            title: '🔴 SYSTEM EMERGENCY ALERT 🔴',
            body: 'CRITICAL SYSTEM NOTIFICATION\n\nThis is a high-priority emergency alert that requires immediate attention.',
            
            // 🚨 SYSTEM ALARM LAYOUT
            notificationLayout: NotificationLayout.BigText,
            category: NotificationCategory.Alarm,
            
            // 🚨 SYSTEM OVERRIDE SETTINGS
            wakeUpScreen: true,
            fullScreenIntent: true,
            criticalAlert: true,
            locked: true, // Make it harder to dismiss
            autoDismissible: false,
            
            // 🚨 EMERGENCY COLORS
            color: Colors.red,
            
            payload: {
              'alertType': 'system_overlay',
              'emergency': 'true',
              'strategy': 'B',
              'persistent': 'true',
              'isAmberAlert': 'true',
              'taskDescription': 'System overlay test',
              'motivationalLine': 'This is a system overlay amber alert test!',
            },
          ),
        );
        
        print("✅ System overlay alert created");
        
        // Trigger continuous vibration for emergency feel
        startEmergencyVibrationPattern();
        
      } else {
        print("⚠️ No overlay permission - showing permission request");
        showPermissionInstructions(context);
      }
      
    } catch (e) {
      print("❌ Error creating system overlay alert: $e");
    }
  }

  // 🚨 Emergency vibration pattern (more intense)
  static void startEmergencyVibrationPattern() {
    print("🚨 Starting emergency vibration pattern...");
    
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      HapticFeedback.heavyImpact();
      
      // Emergency pattern: 3 short bursts
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
      
      // Stop after 20 cycles (10 seconds)
      if (timer.tick >= 20) {
        timer.cancel();
        print("🚨 Emergency vibration pattern completed");
      }
    });
  }

  // 📱 Show permission instructions to user
  static void showPermissionInstructions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚨 FULL SCREEN SETUP REQUIRED',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text('For true amber alerts, enable:'),
            const Text('1. "Display over other apps"'),
            const Text('2. "Ignore battery optimization"'),
            const Text('3. "Critical alerts" in notification settings'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => openDeviceSettings(context),
              child: const Text('Open Settings'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
      ),
    );
  }

  // 🚨 COMBINED TEST: Only Strategy A (B & C Commented Out)
  static Future<void> testAllAmberStrategies(BuildContext context) async {
    print("🚨 TESTING STRATEGY A ONLY (B & C COMMENTED OUT)...");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Launching STRATEGY A ONLY in 3 seconds...'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    
    // Wait 3 seconds, then launch only Strategy A
    await Future.delayed(const Duration(seconds: 3));
    
    // Strategy 1: Enhanced notification (ONLY THIS ONE)
    await createFullScreenIntentNotification(context);
    
    // 🧪 TEMPORARILY COMMENT OUT STRATEGIES B & C FOR TESTING
    // // Strategy 2: Wait 1 second, then overlay
    // await Future.delayed(const Duration(seconds: 1));
    // await createSystemOverlayAlert(context);
    
    // // Strategy 3: Wait 1 second, then continuous
    // await Future.delayed(const Duration(seconds: 1));
    // await testContinuousAlarm(context);
    
    print("🚨 Strategy A only deployed for testing!");
  }

  // ===== PERMISSION AND DIAGNOSTIC FUNCTIONS =====

  // 🔍 NEW: Check all permissions method
  static Future<void> checkAllPermissions(BuildContext context) async {
    print("🔍 Checking all permissions...");
    
    // Check basic notification permission
    final notificationAllowed = await AwesomeNotifications().isNotificationAllowed();
    print("📱 Basic notifications: $notificationAllowed");
    
    // Check individual permissions
    try {
      final permissions = [
        Permission.notification,
        Permission.systemAlertWindow,
        Permission.ignoreBatteryOptimizations,
        Permission.scheduleExactAlarm,
      ];
      
      for (final permission in permissions) {
        final status = await permission.status;
        print("🔐 ${permission.toString()}: ${status.toString()}");
        
        if (status.isDenied) {
          print("⚠️ Requesting ${permission.toString()}...");
          await permission.request();
        }
      }
    } catch (e) {
      print("⚠️ Error checking permissions: $e");
    }
  }

  // 🔋 NEW: Check battery optimization
  static Future<void> checkBatteryOptimization(BuildContext context) async {
    try {
      final batteryOptimized = await Permission.ignoreBatteryOptimizations.status;
      print("🔋 Battery optimization status: $batteryOptimized");
      
      if (batteryOptimized.isDenied) {
        print("⚠️ App may be battery optimized - requesting exemption");
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      print("⚠️ Could not check battery optimization: $e");
    }
  }

  // 📱 NEW: Open device settings for manual configuration
  static Future<void> openDeviceSettings(BuildContext context) async {
    try {
      await AwesomeNotifications().showNotificationConfigPage();
    } catch (e) {
      print("Could not open notification settings: $e");
    }
  }

  // 📊 NEW: Check notification status
  static Future<void> checkScheduledNotifications(BuildContext context) async {
    try {
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();
      print("📋 Scheduled notifications count: ${scheduledNotifications.length}");
      
      for (final notification in scheduledNotifications) {
        print("📅 Scheduled: ID=${notification.content!.id}, Title=${notification.content!.title}");
      }
      
      if (scheduledNotifications.isEmpty) {
        print("⚠️ No notifications are scheduled!");
      }
    } catch (e) {
      print("❌ Error checking scheduled notifications: $e");
    }
  }
}