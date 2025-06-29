import '../screens/amber_alert_screen.dart';
import '../services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'motivator_api.dart';
import 'notification_manager.dart';

class TaskScheduler {
  // 🎯 NEW: Store active timers to prevent memory leaks
  static final Map<String, Timer> _activeTimers = {};
  
  // 🎯 NEW: Main method for precision amber alert bypass
  Future<void> scheduleAmberAlertWithPrecisionBypass(Map<String, dynamic> taskData) async {
    print('🎯 PRECISION BYPASS: Starting amber alert scheduling');
    
    try {
      final scheduledTime = taskData['dateTime'] as DateTime;
      final timeUntilAlert = scheduledTime.difference(DateTime.now());
      final taskId = taskData['description'].hashCode.abs().toString();
      
      print('⏰ Time until alert: ${timeUntilAlert.inSeconds} seconds');
      
      // For alerts within 10 minutes, use precision Dart Timer
      if (timeUntilAlert.inMinutes <= 10) {
        await _scheduleDartTimerBypass(taskData, timeUntilAlert, taskId);
      } else {
        // For longer delays, fall back to traditional scheduling
        print('⏰ Long delay detected, using traditional scheduling');
        await _scheduleTraditionalAmberAlert(taskData);
      }
      
      print('✅ Precision bypass system activated for: ${taskData['description']}');
      
    } catch (e) {
      print('❌ Error in precision bypass: $e');
      // Fallback to traditional notification
      await _scheduleTraditionalAmberAlert(taskData);
    }
  }
  // 🚀 METHOD: Dart Timer Bypass (0-10 minutes)
  Future<void> _scheduleDartTimerBypass(
    Map<String, dynamic> taskData, 
    Duration timeUntilAlert, 
    String taskId
  ) async {
    print('🚀 Using DART TIMER precision bypass: ${timeUntilAlert.inSeconds}s');
    
    // Cancel any existing timer for this task
    _activeTimers[taskId]?.cancel();
    
    // Create precision timer
    _activeTimers[taskId] = Timer(timeUntilAlert, () async {
      print('⏰ DART TIMER FIRED - Executing amber alert at EXACT time');
      await _triggerAmberAlertDirectly(taskData);
      _activeTimers.remove(taskId);
    });
    
    print('✅ Dart Timer scheduled for ${timeUntilAlert.inSeconds} seconds');
  }
// 🎯 CORE METHOD: Direct Amber Alert Trigger (Bypasses Notifications)
  Future<void> _triggerAmberAlertDirectly(Map<String, dynamic> taskData) async {
    print('🎯 DIRECT AMBER ALERT TRIGGER - Bypassing Android notifications entirely');
    
    try {
      // Create immediate high-priority notification as backup
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch % 2147483647,
          channelKey: 'amber_alert_channel',
          title: '🎯 PRECISION EMERGENCY ALERT 🎯',
          body: '${taskData['description']}\n\nDelivered with precision timing!',
          payload: {
            'triggerAmberAlert': 'true',
            'taskDescription': taskData['description'] ?? 'Precision Alert',
            'motivationalLine': 'Your critical moment has arrived!',
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
      
      // Immediate emergency feedback
      HapticFeedback.heavyImpact();
      
      print('🎯 Precision amber alert delivered with <2 second accuracy');
      
    } catch (e) {
      print('❌ Error in direct amber alert trigger: $e');
    }
  }
// 🔄 FALLBACK: Traditional amber alert scheduling
  Future<void> _scheduleTraditionalAmberAlert(Map<String, dynamic> taskData) async {
    print('🔄 Using traditional amber alert scheduling');
    
    final scheduledTime = taskData['dateTime'] as DateTime;
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: taskData['description'].hashCode.abs() % 2147483647,
        channelKey: 'amber_alert_channel',
        title: '🚨 EMERGENCY MOTIVATIONAL ALERT 🚨',
        body: 'CRITICAL ALERT: ${taskData['description']}\n\nYour immediate attention is required!',
        payload: {
          'taskDescription': taskData['description'] ?? 'Emergency Task',
          'motivationalLine': 'This is a critical motivational alert!',
          'isAmberAlert': 'true',
          'emergency': 'true',
          'fallbackMethod': 'traditional',
        },
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        displayOnForeground: true,
        displayOnBackground: true,
        color: Colors.red,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledTime),
    );
  }
  Future<void> _scheduleRegularTask(
    Map<String, dynamic> taskData,
    BuildContext context, {
    String? currentTaskType,
  }) async {
    // Your existing scheduling logic for regular tasks
    try {
      // Check notification permissions first
      bool isAllowed = await NotificationManager.instance.areNotificationsAllowed();
      
      if (!isAllowed) {
        print('❌ Notification permission not granted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Notification permissions required! Please enable in settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      print('🔔 Scheduling regular notification:');
      print('  📝 Task: ${taskData['description']}');
      print('  📅 DateTime: ${taskData['dateTime']}');
      
      // Generate content and schedule regular notification
      final line = await _api.generateLine(
        taskData['description'],
        toneStyle: taskData['toneStyle'],
        voiceStyle: taskData['backendVoiceStyle'] ?? taskData['voiceStyle'],
        taskType: currentTaskType,
      );
      
      final audioBytes = await _api.generateVoice(
        line,
        voiceStyle: taskData['backendVoiceStyle'] ?? taskData['voiceStyle'],
        toneStyle: taskData['toneStyle'],
      );
      
      final audioFilePath = await _saveAudioToDevice(audioBytes, taskData['description']);
      
      // Use existing scheduling logic for regular notifications
      if (taskData['isRecurring'] == true) {
        await _scheduleRecurringNotifications(taskData, line, audioFilePath);
      } else {
        await _scheduleSingleNotification(taskData, line, audioFilePath);
      }
      
    } catch (e) {
      print('❌ Error scheduling regular task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error scheduling task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
    try {
      // Check notification permissions first
      bool isAllowed = await NotificationManager.instance.areNotificationsAllowed();
      
      if (!isAllowed) {
        print('❌ Notification permission not granted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Notification permissions required! Please enable in settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final isAmberAlert = taskData['isAmberAlert'] == true;
      
      // 🚨 ENHANCED: Create immediate amber alert for urgent tasks (< 2 min away)
      final scheduledTime = taskData['dateTime'] as DateTime;
      final timeUntilScheduled = scheduledTime.difference(DateTime.now());
      final isImmediate = timeUntilScheduled.inMinutes < 2;
      
      if (isAmberAlert) {
        print('🚨 Creating AMBER ALERT task with emergency system integration');
      }
      
      print('🔔 Scheduling ${isAmberAlert ? 'AMBER ALERT' : 'regular'} notification(s):');
      print('  📝 Task: ${taskData['description']}');
      print('  📅 DateTime: ${taskData['dateTime']}');
      print('  🚨 Amber Alert: $isAmberAlert');
      print('  🔄 Recurring: ${taskData['isRecurring']}');
      
      // 1. Generate motivational content using your API
      final line = await _api.generateLine(
        taskData['description'],
        toneStyle: taskData['toneStyle'],
        voiceStyle: taskData['backendVoiceStyle'] ?? taskData['voiceStyle'],
        taskType: currentTaskType,
      );
      
      // 2. Generate voice audio using your API
      final audioBytes = await _api.generateVoice(
        line,
        voiceStyle: taskData['backendVoiceStyle'] ?? taskData['voiceStyle'],
        toneStyle: taskData['toneStyle'],
      );
      
      print('✅ Generated content: $line');
      print('✅ Generated audio: ${audioBytes.length} bytes');
      
      // 3. Save audio to local storage
      final audioFilePath = await _saveAudioToDevice(audioBytes, taskData['description']);
      print('💾 Audio saved to: $audioFilePath');
      
      // 🚨 ENHANCED: Verify audio file was saved correctly
      final audioVerified = await NotificationManager.instance.verifyAudioFile(audioFilePath);
      if (!audioVerified) {
        print('⚠️ Audio file verification failed, but continuing...');
      }
      
      // 4. Handle recurring vs single notifications with amber alert support
      if (taskData['isRecurring'] == true) {
        await _scheduleRecurringNotifications(taskData, line, audioFilePath);
      } else {
        await _scheduleSingleNotification(taskData, line, audioFilePath);
      }
      
      // 🚨 ENHANCED: For amber alerts scheduled soon, create immediate test alert
      // Note: Immediate alerts removed - rely on scheduled notifications only
      if (isAmberAlert) {
        print('🚨 Amber alert scheduled for: ${taskData['dateTime']}');
      }
      
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to schedule reminder: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🚨 NEW: Create immediate amber alert for testing/urgent notifications
  Future<void> _createImmediateAmberAlert(
    Map<String, dynamic> taskData, 
    String motivationalLine, 
    String audioFilePath
  ) async {
    print('🚨 Testing IMMEDIATE amber alert (no scheduling)...');
    
    try {
      await NotificationManager.instance.createNotification(
        id: 994, // Fixed ID for immediate alerts
        channelKey: 'amber_alert_channel',
        title: '🚨 IMMEDIATE AMBER ALERT',
        body: 'Emergency motivational intervention - ${taskData['description']}',
        payload: {
          'taskDescription': taskData['description'] ?? 'Immediate Alert',
          'motivationalLine': motivationalLine,
          'audioFilePath': audioFilePath,
          'voiceStyle': taskData['backendVoiceStyle'] ?? taskData['voiceStyle'] ?? 'Default',
          'toneStyle': taskData['toneStyle'] ?? 'Balanced',
          'isRecurring': 'false',
          'isAmberAlert': 'true',
          'forceOverrideSilent': 'true',
          'emergency': 'true', // 🚨 KEY: This triggers auto-display
        },
        // No schedule = immediate notification
        layout: NotificationLayout.BigText,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        category: NotificationCategory.Alarm,
        color: Colors.red,
      );
      
      print('✅ Immediate amber alert created');
    } catch (e) {
      print('❌ Error creating immediate amber alert: $e');
    }
  }

  // ===== FIXED SINGLE NOTIFICATION SCHEDULING =====
  // ===== FIXED SINGLE NOTIFICATION SCHEDULING =====
Future<void> _scheduleSingleNotification(
  Map<String, dynamic> taskData, 
  String motivationalLine, 
  String audioFilePath
) async {
  final scheduledTime = taskData['dateTime'] as DateTime;
  final isAmberAlert = taskData['isAmberAlert'] == true;
  final notificationId = taskData['description'].hashCode.abs() % 2147483647;
  
  print('🔔 Scheduling ${isAmberAlert ? 'AMBER ALERT' : 'regular'} notification:');
  print('  ID: $notificationId');
  print('  Scheduled time: $scheduledTime');
  
  // 🚨 ENHANCED: For amber alerts, use aggressive wake-up scheduling
  if (isAmberAlert) {
    print('🚨 Using AGGRESSIVE amber alert scheduling for device wake-up');
    
    try {
      // Create the main amber alert with maximum wake flags
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'amber_alert_channel',
          title: '🚨 EMERGENCY MOTIVATIONAL ALERT 🚨',
          body: 'CRITICAL ALERT: ${taskData['description']}\n\nYour immediate attention is required!',
          summary: 'EMERGENCY ALERT SYSTEM',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          locked: false,
          autoDismissible: false,
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
          color: Colors.red,
          backgroundColor: Colors.red,
          payload: {
            'taskDescription': taskData['description'] ?? 'Emergency Task',
            'motivationalLine': motivationalLine,
            'audioFilePath': audioFilePath,
            'alertType': 'direct_amber_alert',
            'emergency': 'true',
            'priority': 'maximum',
            'strategy': 'A',
            'isAmberAlert': 'true',
            'playAudio': 'true',
            'forceWake': 'true',
          },
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledTime),
      );
      
      print('✅ Direct amber alert scheduled for: $scheduledTime');
      return;
    } catch (e) {
      print('❌ Error scheduling aggressive amber alert: $e');
      rethrow;
    }
  }
  
  // For regular notifications, use normal scheduling
  final channelKey = 'motivator_reminders';
  final schedule = NotificationCalendar.fromDate(date: scheduledTime);
  
  try {
    await NotificationManager.instance.createNotification(
      id: notificationId,
      channelKey: channelKey,
      title: '🎯 Time for Action!',
      body: taskData['description'] ?? 'Motivational Reminder',
      payload: {
        'taskDescription': taskData['description'] ?? 'Unknown Task',
        'motivationalLine': motivationalLine,
        'audioFilePath': audioFilePath,
        'voiceStyle': taskData['backendVoiceStyle'] ?? taskData['voiceStyle'] ?? 'Default',
        'toneStyle': taskData['toneStyle'] ?? 'Balanced',
        'isRecurring': 'false',
        'isAmberAlert': 'false',
        'forceOverrideSilent': (taskData['forceOverrideSilent'] ?? false).toString(),
      },
      schedule: schedule,
      layout: NotificationLayout.Default,
      wakeUpScreen: true,
      fullScreenIntent: false,
      criticalAlert: false,
      category: NotificationCategory.Reminder,
      color: Colors.teal,
    );
    
    print('✅ Regular notification scheduled successfully for $scheduledTime');
    
  } catch (e) {
    print('❌ Error scheduling regular notification: $e');
    rethrow;
  }
  // ========== PRECISION AMBER ALERT BYPASS SYSTEM ==========
  
  /// Bypasses Android notification scheduler for precision amber alert delivery
  Future<void> scheduleAmberAlertWithPrecisionBypass(Map<String, dynamic> taskData) async {
    final scheduledTime = DateTime.parse(taskData['scheduledTime']);
    final timeUntilAlert = scheduledTime.difference(DateTime.now());
    
    print('🚨 PRECISION AMBER ALERT - Bypassing Android notification scheduler');
    print('⏱️ Time until alert: ${timeUntilAlert.inSeconds} seconds');
    print('🎯 Target time: $scheduledTime');
    
    // Pre-generate audio for instant delivery
    final taskWithAudio = await _preGenerateAudioForBypass(taskData);
    
    if (timeUntilAlert.inSeconds <= 0) {
      // Immediate alert
      print('⚡ IMMEDIATE AMBER ALERT - Triggering now');
      await _triggerAmberAlertDirectly(taskWithAudio);
      return;
    }
    
    if (timeUntilAlert.inMinutes <= 5) {
      // Use Dart Timer for precision (bypasses Android entirely)
      print('🎯 Using Dart Timer for precision delivery (${timeUntilAlert.inSeconds}s)');
      
      Timer(timeUntilAlert, () async {
        print('⏰ DART TIMER FIRED - Executing amber alert at exact time');
        print('🕐 Actual trigger time: ${DateTime.now()}');
        await _triggerAmberAlertDirectly(taskWithAudio);
      });
      
      // Schedule backup notification 30 seconds later
      final backupTime = scheduledTime.add(Duration(seconds: 30));
      print('🔄 Scheduling backup notification for: $backupTime');
      await _scheduleBackupNotification(taskWithAudio, backupTime);
      
    } else {
      // For longer delays, use WorkManager + backup notification
      print('🔄 Using WorkManager for long-term amber alert');
      
      try {
        await _scheduleWorkManagerAmberAlert(taskWithAudio, timeUntilAlert);
        print('✅ WorkManager amber alert scheduled');
      } catch (e) {
        print('⚠️ WorkManager failed, using backup notification only: $e');
      }
      
      // Always schedule backup notification
      await _scheduleBackupNotification(taskWithAudio, scheduledTime);
    }
    
    print('✅ Precision amber alert bypass system activated');
  }
  
  /// Pre-generates audio and motivational line for instant delivery
  Future<Map<String, dynamic>> _preGenerateAudioForBypass(Map<String, dynamic> taskData) async {
    print('🎵 Pre-generating audio for precision delivery...');
    
    try {
      if (taskData['backendVoiceStyle'] != null || taskData['voiceStyle'] != null) {
        final audioStartTime = DateTime.now();
        
        // Generate motivational line
        final motivationalLine = await _api.generateMotivationalLine(
          taskData['description'] ?? 'Stay motivated!',
          taskData['toneStyle'] ?? 'Balanced',
        );
        
        // Generate voice audio
        final voiceStyle = taskData['backendVoiceStyle'] ?? taskData['voiceStyle'];
        final audioBytes = await _api.generateVoice(
          motivationalLine,
          voiceStyle: voiceStyle,
        );
        
        // Save audio file
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'bypass_audio_${timestamp}.mp3';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(audioBytes);
        
        final audioEndTime = DateTime.now();
        final audioGenerationTime = audioEndTime.difference(audioStartTime);
        
        print('✅ Audio pre-generated in ${audioGenerationTime.inMilliseconds}ms');
        print('📊 Audio file: ${(audioBytes.length / 1024).toStringAsFixed(1)}KB');
        
        // Add to task data
        taskData['preGeneratedAudioPath'] = file.path;
        taskData['motivationalLine'] = motivationalLine;
        taskData['audioGenerationTime'] = audioGenerationTime.inMilliseconds;
        taskData['audioSize'] = audioBytes.length;
      }
      
      return taskData;
    } catch (e) {
      print('❌ Error pre-generating audio: $e');
      return taskData;
    }
  }
  
  /// Triggers amber alert directly without using Android notifications
  Future<void> _triggerAmberAlertDirectly(Map<String, dynamic> taskData) async {
    print('🚨 DIRECT AMBER ALERT TRIGGER - BYPASSING ALL ANDROID SYSTEMS');
    print('🕐 Triggered at: ${DateTime.now()}');
    
    try {
      final audioPath = taskData['preGeneratedAudioPath'] ?? '';
      final motivationalLine = taskData['motivationalLine'] ?? 'Critical alert!';
      
      // Emergency vibration pattern
      for (int i = 0; i < 5; i++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(Duration(milliseconds: 150));
      }
      
      // Direct navigation to amber alert screen
      final navigatorKey = NotificationManager.instance._navigatorKey;
      if (navigatorKey?.currentContext != null) {
        
        Navigator.of(navigatorKey!.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => AmberAlertScreen(
              title: '🎯 PRECISION EMERGENCY ALERT 🎯',
              message: motivationalLine,
              taskDescription: taskData['description'] ?? 'Critical Task',
              audioPath: audioPath,
              payload: {
                'bypassedAndroid': 'true',
                'precisionTiming': 'true',
                'deliveredAt': DateTime.now().toIso8601String(),
                'originalScheduled': taskData['scheduledTime'],
                'timerDelivery': 'true',
              },
            ),
          ),
        );
        
        print('✅ Direct amber alert screen launched with precision timing');
        
      } else {
        print('❌ No navigator context - creating emergency notification');
        // Fallback: Create immediate notification
        await _createEmergencyFallbackNotification(taskData);
      }
      
    } catch (e) {
      print('❌ Direct amber alert failed: $e');
      await _createEmergencyFallbackNotification(taskData);
    }
  }
  
  /// Schedules WorkManager task for background execution
  Future<void> _scheduleWorkManagerAmberAlert(
    Map<String, dynamic> taskData, 
    Duration delay
  ) async {
    try {
      final uniqueTaskId = 'amber_alert_${DateTime.now().millisecondsSinceEpoch}';
      
      await Workmanager().registerOneOffTask(
        uniqueTaskId,
        'precisionAmberAlert',
        initialDelay: delay,
        inputData: {
          'taskDescription': taskData['description'] ?? 'WorkManager Alert',
          'motivationalLine': taskData['motivationalLine'] ?? 'Critical alert!',
          'audioPath': taskData['preGeneratedAudioPath'] ?? '',
          'scheduledTime': taskData['scheduledTime'],
          'taskId': uniqueTaskId,
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      
      print('✅ WorkManager precision amber alert scheduled: $uniqueTaskId');
    } catch (e) {
      print('❌ WorkManager scheduling failed: $e');
      rethrow;
    }
  }
  
  /// Schedules backup notification (traditional Android notification)
  Future<void> _scheduleBackupNotification(
    Map<String, dynamic> taskData,
    DateTime scheduledTime,
  ) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'amber_alert_channel',
          title: '🔄 BACKUP EMERGENCY ALERT 🔄',
          body: '${taskData['description']} - Backup delivery system',
          payload: {
            'isBackup': 'true',
            'originalScheduled': scheduledTime.toIso8601String(),
            'taskDescription': taskData['description'] ?? 'Backup Alert',
            'motivationalLine': taskData['motivationalLine'] ?? 'Backup alert!',
            'audioFilePath': taskData['preGeneratedAudioPath'] ?? '',
            'triggerAmberAlert': 'true',
          },
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Alarm,
          color: Colors.orange, // Different color to indicate backup
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledTime),
      );
      
      print('✅ Backup notification scheduled for: $scheduledTime');
    } catch (e) {
      print('❌ Backup notification failed: $e');
    }
  }
  
  /// Emergency fallback notification when direct trigger fails
  Future<void> _createEmergencyFallbackNotification(Map<String, dynamic> taskData) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'amber_alert_channel',
          title: '🆘 EMERGENCY FALLBACK ALERT 🆘',
          body: '${taskData['description']} - Emergency fallback triggered',
          payload: {
            'emergencyFallback': 'true',
            'taskDescription': taskData['description'] ?? 'Emergency Alert',
            'motivationalLine': taskData['motivationalLine'] ?? 'Emergency alert!',
            'audioFilePath': taskData['preGeneratedAudioPath'] ?? '',
            'triggerAmberAlert': 'true',
          },
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          category: NotificationCategory.Alarm,
          color: Colors.red,
        ),
        // No schedule = immediate notification
      );
      
      print('✅ Emergency fallback notification created');
    } catch (e) {
      print('❌ Emergency fallback notification failed: $e');
    }
  }
}

  // 🚨 NEW METHOD: Amber Alert with Multiple Strategies (like your working "ALL" button)
  Future<void> _scheduleAmberAlertWithMultipleStrategies(
    Map<String, dynamic> taskData,
    String motivationalLine,
    String audioFilePath,
    DateTime scheduledTime,
    int baseNotificationId,
  ) async {
    print('🚨 Creating AMBER ALERT with multiple strategies for: $scheduledTime');
    
    final timeUntilScheduled = scheduledTime.difference(DateTime.now());
    
    // 🚨 Always use scheduled notifications - no immediate alerts
    print('🚨 FUTURE AMBER ALERT - Scheduling helper notification for: $scheduledTime');
    
    // 🚨 For future amber alerts, schedule a helper notification that will trigger the strategies
    print('🚨 FUTURE AMBER ALERT - Scheduling helper notification for: $scheduledTime');
    
    try {
      // Create a special "trigger" notification that will fire the amber alert strategies
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseNotificationId,
          channelKey: 'amber_alert_channel',
          title: '🚨 AMBER ALERT TRIGGER',
          body: 'This will trigger the amber alert system...',
          payload: {
            'triggerAmberAlert': 'true',
            'taskDescription': taskData['description'] ?? 'Unknown Task',
            'motivationalLine': motivationalLine,
            'audioFilePath': audioFilePath,
            'emergency': 'true',
            'isAmberAlert': 'true',
          },
          // Use minimal flags for the trigger - the real amber alert happens in the listener
          wakeUpScreen: true,
          category: NotificationCategory.Alarm,
          displayOnForeground: false,  // Hide this trigger notification
          displayOnBackground: true,
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledTime),
      );
      
      print('✅ Amber alert trigger scheduled for: $scheduledTime');
      
    } catch (e) {
      print('❌ Error scheduling amber alert trigger: $e');
      rethrow;
    }
  }

  // 🚨 NEW METHOD: Create immediate amber alert with multiple strategies (copy of working "ALL" button)
  Future<void> _createImmediateAmberAlertStrategies(
    Map<String, dynamic> taskData,
    String motivationalLine,
    String audioFilePath,
    int baseId,
  ) async {
    print('🚨 DEPLOYING IMMEDIATE AMBER ALERT WITH MULTIPLE STRATEGIES...');
    
    final taskDescription = taskData['description'] ?? 'Emergency Task';
    
    try {
      // 🚨 STRATEGY 1: Enhanced Full-Screen Intent (ID: baseId + 1)
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId + 1,
          channelKey: 'amber_alert_channel',
          title: '🚨 EMERGENCY MOTIVATIONAL ALERT 🚨',
          body: 'CRITICAL ALERT: $taskDescription\n\nYour immediate attention is required!',
          summary: 'EMERGENCY ALERT SYSTEM',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          locked: false,
          autoDismissible: false,
          showWhen: true,
          displayOnForeground: true,
          displayOnBackground: true,
          color: Colors.red,
          backgroundColor: Colors.red,
          payload: {
            'taskDescription': taskDescription,
            'motivationalLine': motivationalLine,
            'audioFilePath': audioFilePath,
            'alertType': 'full_screen_intent',
            'emergency': 'true',
            'priority': 'maximum',
            'strategy': 'A',
            'isAmberAlert': 'true',
          },
        ),
        // No schedule = immediate
      );
      
      // Wait 1 second between strategies
      await Future.delayed(const Duration(seconds: 1));
      
      // 🚨 STRATEGY 2: System Overlay Alert (ID: baseId + 2)
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId + 2,
          channelKey: 'amber_alert_channel',
          title: '🔴 SYSTEM EMERGENCY ALERT 🔴',
          body: 'CRITICAL SYSTEM NOTIFICATION\n\n$taskDescription requires immediate attention.',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          locked: true,
          autoDismissible: false,
          color: Colors.red,
          payload: {
            'taskDescription': taskDescription,
            'motivationalLine': motivationalLine,
            'audioFilePath': audioFilePath,
            'alertType': 'system_overlay',
            'emergency': 'true',
            'strategy': 'B',
            'persistent': 'true',
            'isAmberAlert': 'true',
          },
        ),
      );
      
      // Wait 1 second between strategies
      await Future.delayed(const Duration(seconds: 1));
      
      // 🚨 STRATEGY 3: Continuous Alarm (ID: baseId + 3)
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: baseId + 3,
          channelKey: 'amber_alert_channel',
          title: '🔴 CONTINUOUS EMERGENCY ALERT 🔴',
          body: '$taskDescription\n\nThis alert will persist until you respond!',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          locked: true,
          autoDismissible: false,
          showWhen: true,
          color: Colors.red,
          payload: {
            'taskDescription': taskDescription,
            'motivationalLine': motivationalLine,
            'audioFilePath': audioFilePath,
            'alertType': 'continuous_alarm',
            'requires_response': 'true',
            'emergency_level': 'maximum',
            'emergency': 'true',
            'isAmberAlert': 'true',
          },
        ),
      );
      
      print('🚨 All 3 amber alert strategies deployed successfully!');
      
    } catch (e) {
      print('❌ Error deploying amber alert strategies: $e');
      rethrow;
    }
  }

  // ===== ENHANCED RECURRING NOTIFICATION SCHEDULING =====
  Future<void> _scheduleRecurringNotifications(
    Map<String, dynamic> taskData, 
    String motivationalLine, 
    String audioFilePath
  ) async {
    final frequency = taskData['recurringFrequency'] as String;
    final selectedDays = (taskData['selectedDays'] as List<dynamic>?)?.cast<int>() ?? [];
    final endDate = taskData['recurringEndDate'] as DateTime?;
    final neverEnds = taskData['neverEnds'] as bool? ?? true;
    final startTime = taskData['dateTime'] as DateTime;
    final isAmberAlert = taskData['isAmberAlert'] == true;
    
    List<DateTime> scheduleDates = [];
    
    switch (frequency) {
      case 'Daily':
        scheduleDates = generateDailyDates(startTime, endDate, neverEnds);
        break;
      case 'Weekly':
        scheduleDates = generateWeeklyDates(startTime, selectedDays, endDate, neverEnds);
        break;
      case 'Monthly':
        scheduleDates = generateMonthlyDates(startTime, endDate, neverEnds);
        break;
    }
    
    // Limit to prevent too many notifications (max 50 for awesome_notifications)
    if (scheduleDates.length > 50) {
      scheduleDates = scheduleDates.take(50).toList();
    }
    
    // 🚨 Choose channel based on amber alert status
    final channelKey = isAmberAlert ? 'amber_alert_channel' : 'motivator_reminders';
    
    // Schedule each notification with enhanced precision for amber alerts
    for (int i = 0; i < scheduleDates.length; i++) {
      final scheduleDate = scheduleDates[i];
      final notificationId = (taskData['description'].hashCode.abs() + i) % 2147483647;
      
      // 🚨 ENHANCED: For recurring amber alerts, use trigger system too
      if (isAmberAlert) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: channelKey,
            title: '🚨 RECURRING AMBER TRIGGER',
            body: 'Recurring amber alert trigger...',
            payload: {
              'triggerAmberAlert': 'true',
              'taskDescription': taskData['description'] ?? 'Unknown Task',
              'motivationalLine': motivationalLine,
              'audioFilePath': audioFilePath,
              'isRecurring': 'true',
              'isAmberAlert': 'true',
              'recurringFrequency': taskData['recurringFrequency'] ?? 'Weekly',
              'emergency': 'true',
            },
            wakeUpScreen: true,
            category: NotificationCategory.Alarm,
            displayOnForeground: false,
            displayOnBackground: true,
          ),
          schedule: NotificationCalendar.fromDate(date: scheduleDate),
        );
      } else {
        // Regular recurring notification
        await NotificationManager.instance.createNotification(
          id: notificationId,
          channelKey: channelKey,
          title: '🎯 Time for Action!',
          body: '${taskData['description'] ?? 'Motivational Reminder'} (${taskData['recurringFrequency'] ?? 'Weekly'})',
          payload: {
            'taskDescription': taskData['description'] ?? 'Unknown Task',
            'motivationalLine': motivationalLine,
            'audioFilePath': audioFilePath,
            'isRecurring': 'true',
            'isAmberAlert': 'false',
            'recurringFrequency': taskData['recurringFrequency'] ?? 'Weekly',
          },
          schedule: NotificationCalendar.fromDate(date: scheduleDate),
          layout: NotificationLayout.Default,
          wakeUpScreen: true,
          fullScreenIntent: false,
          criticalAlert: false,
          category: NotificationCategory.Reminder,
          color: Colors.teal,
        );
      }
    }
    
    print('✅ Scheduled ${scheduleDates.length} ${isAmberAlert ? 'AMBER ALERT' : 'regular'} recurring notifications');
  }

  // ===== DATE GENERATION METHODS =====
  
  // Generate daily recurring dates
  List<DateTime> generateDailyDates(DateTime startTime, DateTime? endDate, bool neverEnds) {
    List<DateTime> dates = [];
    DateTime current = startTime;
    final maxDate = neverEnds ? DateTime.now().add(const Duration(days: 365)) : endDate!;
    
    while (current.isBefore(maxDate) && dates.length < 365) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  // Generate weekly recurring dates
  List<DateTime> generateWeeklyDates(DateTime startTime, List<int> selectedDays, DateTime? endDate, bool neverEnds) {
    List<DateTime> dates = [];
    DateTime current = startTime;
    final maxDate = neverEnds ? DateTime.now().add(const Duration(days: 365)) : endDate!;
    
    while (current.isBefore(maxDate) && dates.length < 200) {
      // Check if current day is in selected days
      if (selectedDays.contains(current.weekday)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  // Generate monthly recurring dates
  List<DateTime> generateMonthlyDates(DateTime startTime, DateTime? endDate, bool neverEnds) {
    List<DateTime> dates = [];
    DateTime current = startTime;
    final maxDate = neverEnds ? DateTime.now().add(const Duration(days: 365)) : endDate!;
    
    while (current.isBefore(maxDate) && dates.length < 24) {
      dates.add(current);
      // Add one month
      current = DateTime(current.year, current.month + 1, current.day, current.hour, current.minute);
    }
    
    return dates;
  }

  // ===== HELPER METHODS =====
  
  // Get day name from weekday number
  String getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Save audio to device storage
  Future<String> _saveAudioToDevice(Uint8List audioBytes, String taskDescription) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      
      // Create audio directory if it doesn't exist
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      // Create unique filename based on task and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeTaskName = taskDescription.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final fileName = '${safeTaskName}_$timestamp.mp3';
      final filePath = '${audioDir.path}/$fileName';
      
      // Write audio bytes to file
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);
      
      print('💾 Audio file saved: $filePath (${audioBytes.length} bytes)');
      return filePath;
      
    } catch (e) {
      print('❌ Error saving audio file: $e');
      rethrow;
    }
  }

  // ===== PUBLIC UTILITY METHODS =====
  
  // Cancel all scheduled notifications for a task
  Future<void> cancelTaskNotifications(String taskDescription) async {
    try {
      final scheduledNotifications = await NotificationManager.instance.getScheduledNotifications();
      
      for (final notification in scheduledNotifications) {
        final payload = notification.content?.payload;
        if (payload != null && payload['taskDescription'] == taskDescription) {
          await NotificationManager.instance.cancelNotification(notification.content!.id!);
          print('🗑️ Cancelled notification for task: $taskDescription');
        }
      }
    } catch (e) {
      print('❌ Error cancelling task notifications: $e');
    }
  }

  // Get count of scheduled notifications
  Future<int> getScheduledNotificationCount() async {
    try {
      final notifications = await NotificationManager.instance.getScheduledNotifications();
      return notifications.length;
    } catch (e) {
      print('❌ Error getting notification count: $e');
      return 0;
    }
  }

  // Get all scheduled notifications for display
  Future<List<Map<String, dynamic>>> getScheduledNotificationsInfo() async {
    try {
      final notifications = await NotificationManager.instance.getScheduledNotifications();
      
      return notifications.map((notification) {
        return {
          'id': notification.content?.id,
          'title': notification.content?.title,
          'body': notification.content?.body,
          'scheduledDate': notification.schedule?.toString(),
          'isAmberAlert': notification.content?.channelKey == 'amber_alert_channel',
          'payload': notification.content?.payload,
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting notifications info: $e');
      return [];
    }
  }
}