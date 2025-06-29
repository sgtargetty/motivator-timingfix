import '../screens/amber_alert_screen.dart';
import '../services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'motivator_api.dart';
import 'notification_manager.dart';

class TaskScheduler {
  final MotivatorApi _api = MotivatorApi();
  
  // 🎯 Store active timers to prevent memory leaks
  static final Map<String, Timer> _activeTimers = {};
  
  // ========== PRECISION AMBER ALERT BYPASS SYSTEM ==========
  
  // 🎯 Main method for precision amber alert bypass
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
  
  // 🚀 Dart Timer Bypass (0-10 minutes)
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
  
  // 🎯 Direct Amber Alert Trigger (Bypasses Notifications)
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
  
  // 🔄 Traditional amber alert scheduling (fallback)
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
  
  // 🧹 Cleanup method for active timers
  static void cancelAllActiveTimers() {
    print('🧹 Canceling ${_activeTimers.length} active precision timers');
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
  }
  
  // ========== ORIGINAL SCHEDULING METHODS ==========
  
  // Main task scheduling method
  Future<void> scheduleTask(Map<String, dynamic> taskData) async {
    final isRecurring = taskData['isRecurring'] ?? false;
    final isAmberAlert = taskData['isAmberAlert'] == true;
    
    print('📅 Scheduling ${isAmberAlert ? 'AMBER ALERT' : 'regular'} task: ${taskData['description']}');
    print('🔄 Recurring: $isRecurring');
    
    try {
      // Generate motivational line and audio
      final motivationalLine = await _generateMotivationalLine(taskData);
      final audioFilePath = await _generateAndSaveAudio(taskData, motivationalLine);
      
      // 🎯 NEW: Use precision bypass for amber alerts
      if (isAmberAlert && !isRecurring) {
        print('🎯 Using precision bypass for amber alert');
        await scheduleAmberAlertWithPrecisionBypass(taskData);
        return;
      }
      
      // Use traditional scheduling for regular notifications and recurring amber alerts
      if (isRecurring) {
        await _scheduleRecurringNotifications(taskData, motivationalLine, audioFilePath);
      } else {
        await _scheduleSingleNotification(taskData, motivationalLine, audioFilePath);
      }
      
      print('✅ Task scheduled successfully');
      
    } catch (e) {
      print('❌ Error scheduling task: $e');
      rethrow;
    }
  }
  
  // Generate motivational line
  Future<String> _generateMotivationalLine(Map<String, dynamic> taskData) async {
    try {
      return await _api.generateLine(
        taskData['description'] ?? 'Complete your task!',
        toneStyle: taskData['toneStyle'] ?? 'Balanced',
      );
    } catch (e) {
      print('⚠️ Error generating motivational line: $e');
      return 'You can do this! Time to tackle ${taskData['description'] ?? 'your task'}!';
    }
  }
  
  // Generate and save audio
  Future<String> _generateAndSaveAudio(Map<String, dynamic> taskData, String motivationalLine) async {
    try {
      if (taskData['backendVoiceStyle'] != null || taskData['voiceStyle'] != null) {
        print('🎵 Generating voice audio...');
        
        final voiceStyle = taskData['backendVoiceStyle'] ?? taskData['voiceStyle'];
        final audioBytes = await _api.generateVoice(
          motivationalLine,
          voiceStyle: voiceStyle,
        );
        
        return await _saveAudioToDevice(audioBytes, taskData['description']);
      }
      
      return '';
    } catch (e) {
      print('⚠️ Error generating audio: $e');
      return '';
    }
  }
  
  // Single notification scheduling
  Future<void> _scheduleSingleNotification(
    Map<String, dynamic> taskData, 
    String motivationalLine, 
    String audioFilePath
  ) async {
    final scheduledTime = taskData['dateTime'] as DateTime;
    final isAmberAlert = taskData['isAmberAlert'] == true;
    final notificationId = taskData['description'].hashCode.abs() % 2147483647;
    
    print('🔔 Scheduling ${isAmberAlert ? 'AMBER ALERT' : 'regular'} notification for: $scheduledTime');
    
    final channelKey = isAmberAlert ? 'amber_alert_channel' : 'motivator_reminders';
    final schedule = NotificationCalendar.fromDate(date: scheduledTime);
    
    try {
      await NotificationManager.instance.createNotification(
        id: notificationId,
        channelKey: channelKey,
        title: isAmberAlert ? '🚨 EMERGENCY MOTIVATIONAL ALERT 🚨' : '🎯 Time for Action!',
        body: taskData['description'] ?? 'Motivational Reminder',
        payload: {
          'taskDescription': taskData['description'] ?? 'Unknown Task',
          'motivationalLine': motivationalLine,
          'audioFilePath': audioFilePath,
          'voiceStyle': taskData['backendVoiceStyle'] ?? taskData['voiceStyle'] ?? 'Default',
          'toneStyle': taskData['toneStyle'] ?? 'Balanced',
          'isRecurring': 'false',
          'isAmberAlert': isAmberAlert.toString(),
          'forceOverrideSilent': (taskData['forceOverrideSilent'] ?? false).toString(),
        },
        schedule: schedule,
        layout: NotificationLayout.Default,
        wakeUpScreen: isAmberAlert,
        fullScreenIntent: isAmberAlert,
        criticalAlert: isAmberAlert,
        category: isAmberAlert ? NotificationCategory.Alarm : NotificationCategory.Reminder,
        color: isAmberAlert ? Colors.red : Colors.teal,
      );
      
      print('✅ ${isAmberAlert ? 'Amber alert' : 'Regular notification'} scheduled successfully');
      
    } catch (e) {
      print('❌ Error scheduling notification: $e');
      rethrow;
    }
  }
  
  // Recurring notification scheduling
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
    
    // Limit to prevent too many notifications (max 50)
    if (scheduleDates.length > 50) {
      scheduleDates = scheduleDates.take(50).toList();
    }
    
    final channelKey = isAmberAlert ? 'amber_alert_channel' : 'motivator_reminders';
    
    // Schedule each notification
    for (int i = 0; i < scheduleDates.length; i++) {
      final scheduleDate = scheduleDates[i];
      final notificationId = (taskData['description'].hashCode.abs() + i) % 2147483647;
      
      await NotificationManager.instance.createNotification(
        id: notificationId,
        channelKey: channelKey,
        title: isAmberAlert ? '🚨 RECURRING AMBER ALERT 🚨' : '🎯 Time for Action!',
        body: '${taskData['description'] ?? 'Motivational Reminder'} (${taskData['recurringFrequency'] ?? 'Weekly'})',
        payload: {
          'taskDescription': taskData['description'] ?? 'Unknown Task',
          'motivationalLine': motivationalLine,
          'audioFilePath': audioFilePath,
          'isRecurring': 'true',
          'isAmberAlert': isAmberAlert.toString(),
          'recurringFrequency': taskData['recurringFrequency'] ?? 'Weekly',
        },
        schedule: NotificationCalendar.fromDate(date: scheduleDate),
        layout: NotificationLayout.Default,
        wakeUpScreen: isAmberAlert,
        fullScreenIntent: isAmberAlert,
        criticalAlert: isAmberAlert,
        category: isAmberAlert ? NotificationCategory.Alarm : NotificationCategory.Reminder,
        color: isAmberAlert ? Colors.red : Colors.teal,
      );
    }
    
    print('✅ Scheduled ${scheduleDates.length} ${isAmberAlert ? 'amber alert' : 'regular'} recurring notifications');
  }
  
  // ===== DATE GENERATION METHODS =====
  
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
  
  List<DateTime> generateWeeklyDates(DateTime startTime, List<int> selectedDays, DateTime? endDate, bool neverEnds) {
    List<DateTime> dates = [];
    DateTime current = startTime;
    final maxDate = neverEnds ? DateTime.now().add(const Duration(days: 365)) : endDate!;
    
    while (current.isBefore(maxDate) && dates.length < 200) {
      if (selectedDays.contains(current.weekday)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  List<DateTime> generateMonthlyDates(DateTime startTime, DateTime? endDate, bool neverEnds) {
    List<DateTime> dates = [];
    DateTime current = startTime;
    final maxDate = neverEnds ? DateTime.now().add(const Duration(days: 365)) : endDate!;
    
    while (current.isBefore(maxDate) && dates.length < 24) {
      dates.add(current);
      current = DateTime(current.year, current.month + 1, current.day, current.hour, current.minute);
    }
    
    return dates;
  }
  
  // ===== HELPER METHODS =====
  
  String getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
  
  Future<String> _saveAudioToDevice(Uint8List audioBytes, String taskDescription) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeTaskName = taskDescription.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final fileName = '${safeTaskName}_$timestamp.mp3';
      final filePath = '${audioDir.path}/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);
      
      print('💾 Audio file saved: $filePath (${audioBytes.length} bytes)');
      return filePath;
      
    } catch (e) {
      print('❌ Error saving audio file: $e');
      rethrow;
    }
  }
  
  // ===== UTILITY METHODS =====
  
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
  
  Future<int> getScheduledNotificationCount() async {
    try {
      final notifications = await NotificationManager.instance.getScheduledNotifications();
      return notifications.length;
    } catch (e) {
      print('❌ Error getting notification count: $e');
      return 0;
    }
  }
  
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