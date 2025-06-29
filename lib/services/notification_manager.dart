import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

import '../screens/amber_alert_screen.dart';

@pragma("vm:entry-point")
class NotificationManager {
  static NotificationManager? _instance;
  static NotificationManager get instance => _instance ??= NotificationManager._();
  NotificationManager._();

  // Global navigator key reference (will be set by main app)
  GlobalKey<NavigatorState>? _navigatorKey;
  
  // 🚨 CRITICAL: Prevent infinite loops
  bool _isAmberAlertActive = false;
  
  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  // ===== SETUP NOTIFICATION LISTENERS =====
  void setupNotificationListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onNotificationDismissed,
    );
    print("✅ Notification listeners set up successfully");
  }

  // ===== ENHANCED PERMISSION HANDLING FOR AMBER ALERTS =====
  Future<void> requestAwesomeNotificationPermissions() async {
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
        await AwesomeNotifications().requestPermissionToSendNotifications(
          channelKey: 'amber_alert_channel',
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
            NotificationPermission.Vibration,
            NotificationPermission.Light,
            NotificationPermission.CriticalAlert,
            NotificationPermission.FullScreenIntent,
          ],
        );
        print('✅ Critical alert permissions requested');
      } catch (e) {
        print('⚠️ Critical alert permission request failed (might not be supported): $e');
      }
      
      // 3. Request additional Android permissions
      if (Platform.isAndroid) {
        try {
          await Permission.systemAlertWindow.request();
          print('✅ System alert window permission requested');
          
          await Permission.accessNotificationPolicy.request();
          print('✅ Do not disturb access requested');
          
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
  }

  // ===== NOTIFICATION EVENT HANDLERS =====
  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreated(ReceivedNotification receivedNotification) async {
    print('🔔 Notification created: ${receivedNotification.title}');
    
    // 🚨 IGNORE helper notifications to prevent loops
    if (receivedNotification.id == 999999) {
      print('🔄 Helper notification created (ignoring to prevent loops)');
      return;
    }
    
    // 🚨 If it's an amber alert, add extra logging
    if (receivedNotification.channelKey == 'amber_alert_channel') {
      print('🚨 AMBER ALERT NOTIFICATION CREATED: ${receivedNotification.title}');
      
      try {
        HapticFeedback.heavyImpact();
      } catch (e) {
        print('⚠️ Error triggering amber alert feedback: $e');
      }
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayed(ReceivedNotification receivedNotification) async {
    print('🔔 Notification displayed: ${receivedNotification.title}');
    
    // 🚨 CRITICAL: Ignore helper notifications to prevent infinite loops
    if (receivedNotification.id == 999999) {
      print('🔄 Helper notification displayed (ignoring to prevent loops)');
      return;
    }
    
    // 🚨 Handle amber alert trigger notifications (for future scheduled alerts)
    if (receivedNotification.payload?['triggerAmberAlert'] == 'true') {
      print('🚨 AMBER ALERT TRIGGER DETECTED - DEPLOYING AMBER ALERT NOW!');
      
      final taskDescription = receivedNotification.payload?['taskDescription'] ?? 'Emergency Task';
      final motivationalLine = receivedNotification.payload?['motivationalLine'] ?? 'Critical alert!';
      final audioFilePath = receivedNotification.payload?['audioFilePath'] ?? '';
      
      await _deployAmberAlert(
        taskDescription: taskDescription,
        motivationalLine: motivationalLine,
        audioFilePath: audioFilePath,
        triggerId: receivedNotification.id!,
      );
      
      try {
        await AwesomeNotifications().cancel(receivedNotification.id!);
        print('🚨 Trigger notification hidden - amber alert deployed');
      } catch (e) {
        print('⚠️ Could not hide trigger notification: $e');
      }
      
      return;
    }
    
    // 🚨 CRITICAL FIX: Handle amber alerts - ONLY STRATEGY A HIJACKS SCREEN
    if (receivedNotification.channelKey == 'amber_alert_channel') {
      print('🚨 AMBER ALERT DISPLAYED - CHECKING FOR AUTO-HIJACK...');
      
      final isEmergencyAlert = receivedNotification.payload?['emergency'] == 'true';
      final strategy = receivedNotification.payload?['strategy'];
      
      print('🔍 Emergency: $isEmergencyAlert, Strategy: $strategy');
      
      // 🎯 ONLY STRATEGY A TRIGGERS SCREEN HIJACKING
      if (isEmergencyAlert && strategy == 'A') {
        print('🚨 AMBER ALERT STRATEGY A - HIJACKING SCREEN AUTOMATICALLY');
        print('🚨 AUTO-LAUNCHING FULL SCREEN ALERT NOW!');
        
        NotificationManager.instance._showLockScreenBypassAlert(
          title: receivedNotification.title ?? '🚨 EMERGENCY ALERT 🚨',
          message: receivedNotification.payload?['motivationalLine'] ?? 'Critical motivational emergency requires your attention!',
          taskDescription: receivedNotification.payload?['taskDescription'],
          payload: receivedNotification.payload,
          audioPath: receivedNotification.payload?['audioFilePath'],
        );
        
        // Emergency haptic feedback
        try {
          for (int i = 0; i < 5; i++) {
            HapticFeedback.heavyImpact();
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (e) {
          print('⚠️ Error with amber alert haptic pattern: $e');
        }
        
        // 🎵 AUDIO DISABLED HERE - AmberAlertScreen will handle audio playback
        // Audio will be played by the AmberAlertScreen to avoid double playback
        print('🎵 Audio playback delegated to AmberAlertScreen to avoid double playback');
        
      } else {
        print('🚨 AMBER ALERT - Non-emergency or unrecognized strategy: $strategy');
        
        try {
          HapticFeedback.lightImpact();
        } catch (e) {
          print('⚠️ Error with amber alert haptic: $e');
        }
      }
      
      // 🚨 CRITICAL: RETURN EARLY - DO NOT PROCESS ANY OTHER LOGIC FOR AMBER ALERTS
      return;
    }
    
    // 🔔 Handle normal notifications (non-amber alerts)
    print('🔔 Normal notification displayed: ${receivedNotification.title}');
  }

  // 🚨 Deploy single amber alert (for future scheduled alerts)
  static Future<void> _deployAmberAlert({
    required String taskDescription,
    required String motivationalLine,
    required String audioFilePath,
    required int triggerId,
  }) async {
    print('🚨 DEPLOYING AMBER ALERT FROM TRIGGER...');
    
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: triggerId + 1000,
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
            'playAudio': 'true',
          },
        ),
      );
      
      print('🚨 Amber alert deployed from trigger successfully!');
      
    } catch (e) {
      print('❌ Error deploying amber alert from trigger: $e');
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDismissed(ReceivedAction receivedAction) async {
    print('🔔 Notification dismissed: ${receivedAction.title}');
    
    if (receivedAction.id == 999999) {
      print('🔄 Helper notification dismissed');
      return;
    }
    
    if (receivedAction.channelKey == 'amber_alert_channel') {
      print('🚨 AMBER ALERT DISMISSED');
      NotificationManager.instance._isAmberAlertActive = false;
      print('🔄 Amber alert flag reset due to dismissal');
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationActionReceived(ReceivedAction receivedAction) async {
    print('🔔 Notification tapped: ${receivedAction.payload}');
    print('🚨 DEBUG: _onNotificationActionReceived was called!');
    
    try {
      if (receivedAction.id == 999999) {
        print('🔄 Helper notification tapped (ignoring)');
        return;
      }
      
      final isAmberAlert = receivedAction.channelKey == 'amber_alert_channel';
      final isEmergencyAlert = receivedAction.payload?['emergency'] == 'true';
      final strategy = receivedAction.payload?['strategy'];
      
      if (isAmberAlert || isEmergencyAlert) {
        print('🚨 AMBER ALERT TAPPED - STRATEGY: $strategy');
        print('🚨 Amber alert screen already hijacked - providing feedback only');
        
        try {
          for (int i = 0; i < 3; i++) {
            HapticFeedback.heavyImpact();
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (e) {
          print('⚠️ Error with amber alert tap feedback: $e');
        }
        
        return;
      }
      
      // ===== NORMAL NOTIFICATION HANDLING (NON-AMBER ALERTS) =====
      if (receivedAction.payload != null && receivedAction.payload!.isNotEmpty) {
        final taskDescription = receivedAction.payload!['taskDescription'];
        final motivationalLine = receivedAction.payload!['motivationalLine'];
        final audioFilePath = receivedAction.payload!['audioFilePath'];
        final forceOverrideSilent = receivedAction.payload!['forceOverrideSilent'] == 'true';
        
        print('🎯 Task: $taskDescription');
        print('💬 Message: $motivationalLine');
        print('🎵 Audio file: $audioFilePath');
        print('🔊 Override silent: $forceOverrideSilent');
        
        if (audioFilePath != null && audioFilePath.isNotEmpty) {
          await NotificationManager.instance._playEmergencyAudio(audioFilePath, forceOverrideSilent);
        }
      }
    } catch (e) {
      print('❌ Error handling notification action: $e');
    }
  }

  // 🚨 Show Lock Screen Bypass Amber Alert
  void _showLockScreenBypassAlert({
    required String title,
    required String message,
    String? taskDescription,
    Map<String, String?>? payload,
    String? audioPath,
  }) {
    print('🚨 _showLockScreenBypassAlert called with title: $title');
    
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      print('❌ No context available for amber alert navigation');
      return;
    }
    
    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.settings.name == '/emergency_alert') {
      print('⚠️ Emergency alert already showing, ignoring duplicate');
      return;
    }
    
    try {
      print('✅ Context found - attempting EMERGENCY navigation');
      
      _isAmberAlertActive = true;
      
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => _buildEmergencyOverlay(
            title: title,
            message: message,
            taskDescription: taskDescription,
            payload: payload,
            audioPath: audioPath,
          ),
          opaque: true,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 200),
          settings: const RouteSettings(
            name: '/emergency_alert',
            arguments: {'emergency': true, 'bypassLock': true},
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        ),
        (route) => route.isFirst,
      );
      
      print('✅ EMERGENCY navigation initiated successfully');
      
      Timer(const Duration(seconds: 3), () {
        if (_isAmberAlertActive) {
          print('! Auto-resetting amber alert flag (timeout)');
          _isAmberAlertActive = false;
        }
      });
      
    } catch (e) {
      print('❌ Error during emergency navigation: $e');
      _isAmberAlertActive = false;
    }
  }

  // 🚨 Build emergency overlay widget
  Widget _buildEmergencyOverlay({
    required String title,
    required String message,
    String? taskDescription,
    Map<String, String?>? payload,
    String? audioPath,
  }) {
    print('🚨 Building emergency overlay widget...');
    
    return WillPopScope(
      onWillPop: () async {
        _isAmberAlertActive = false;
        print('🔄 Amber alert flag reset via WillPopScope');
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Color(0xFFCC0000),
                Color(0xFF660000),
                Colors.black,
              ],
              stops: [0.2, 0.6, 1.0],
            ),
          ),
          child: AmberAlertScreen(
            title: title,
            message: message,
            taskDescription: taskDescription,
            payload: payload,
            audioPath: audioPath,
          ),
        ),
      ),
    );
  }

  // 🎵 Emergency audio player
  Future<void> _playEmergencyAudio(String audioFilePath, bool forceOverrideSilent) async {
    try {
      print('🎵 Attempting to play EMERGENCY audio: $audioFilePath');
      
      if (audioFilePath.isEmpty || audioFilePath == 'null' || audioFilePath == '/test/path/emergency_audio.mp3') {
        print('! No audio path provided, playing fallback');
        
        try {
          HapticFeedback.heavyImpact();
          print('🔔 Fallback system alert sound played');
        } catch (e) {
          print('⚠️ Error with fallback sound: $e');
        }
        return;
      }
      
      final file = File(audioFilePath);
      if (!await file.exists()) {
        print('❌ Emergency audio file not found at: $audioFilePath');
        
        final fileName = audioFilePath.split('/').last;
        final directory = await getApplicationDocumentsDirectory();
        final alternativePath = '${directory.path}/audio/$fileName';
        
        final alternativeFile = File(alternativePath);
        if (await alternativeFile.exists()) {
          print('✅ Found audio file at alternative path: $alternativePath');
          await _playAudioFile(alternativePath, forceOverrideSilent);
          return;
        }
        
        print('❌ Audio file not found in any location, using fallback');
        HapticFeedback.heavyImpact();
        return;
      }
      
      print('✅ Emergency audio file found, size: ${await file.length()} bytes');
      await _playAudioFile(audioFilePath, forceOverrideSilent);
      
    } catch (e) {
      print('❌ Error with emergency audio system: $e');
      try {
        HapticFeedback.heavyImpact();
      } catch (hapticError) {
        print('❌ Even haptic feedback failed: $hapticError');
      }
    }
  }

  Future<void> _playAudioFile(String audioFilePath, bool forceOverrideSilent) async {
    AudioPlayer? audioPlayer;
    
    try {
      audioPlayer = AudioPlayer();
      await audioPlayer.setAudioSource(AudioSource.file(audioFilePath));
      await audioPlayer.setVolume(1.0);
      await audioPlayer.setSpeed(1.0);
      
      print('🚨 Playing EMERGENCY AUDIO with maximum override');
      
      for (int playCount = 0; playCount < 3; playCount++) {
        print('🎵 Playing emergency audio (attempt ${playCount + 1})');
        
        await audioPlayer.play();
        
        await Future.any([
          audioPlayer.playerStateStream
              .firstWhere((state) => state.processingState == ProcessingState.completed),
          Future.delayed(const Duration(seconds: 10)),
        ]);
        
        if (playCount < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
          await audioPlayer.seek(Duration.zero);
        }
      }
      
      print('✅ Emergency audio playback completed (3 times)');
      
    } catch (e) {
      print('⚠️ Error with emergency audio playback: $e');
      try {
        for (int i = 0; i < 5; i++) {
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (hapticError) {
        print('❌ Haptic fallback also failed: $hapticError');
      }
    } finally {
      try {
        await audioPlayer?.dispose();
      } catch (e) {
        print('⚠️ Error disposing emergency audio player: $e');
      }
    }
  }

  // ===== PUBLIC HELPER METHODS =====
  
  Future<void> createNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    Map<String, String?>? payload,
    NotificationSchedule? schedule,
    NotificationLayout? layout,
    bool wakeUpScreen = false,
    bool fullScreenIntent = false,
    bool criticalAlert = false,
    NotificationCategory? category,
    Color? color,
  }) async {
    try {
      if (channelKey == 'amber_alert_channel') {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: channelKey,
            title: title,
            body: body,
            payload: payload,
            notificationLayout: NotificationLayout.BigText,
            wakeUpScreen: true,
            fullScreenIntent: true,
            criticalAlert: true,
            category: NotificationCategory.Alarm,
            color: color ?? Colors.red,
            displayOnForeground: true,
            displayOnBackground: true,
            locked: true,
            autoDismissible: false,
            showWhen: true,
            actionType: ActionType.KeepOnTop,
          ),
          schedule: schedule,
        );
      } else {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: channelKey,
            title: title,
            body: body,
            payload: payload,
            notificationLayout: layout ?? NotificationLayout.Default,
            wakeUpScreen: wakeUpScreen,
            fullScreenIntent: fullScreenIntent,
            criticalAlert: criticalAlert,
            category: category,
            color: color,
            displayOnForeground: true,
            displayOnBackground: true,
          ),
          schedule: schedule,
        );
      }
      
      print('✅ Notification created successfully: $title');
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow;
    }
  }

  Future<bool> verifyAudioFile(String audioFilePath) async {
    try {
      if (audioFilePath.isEmpty) {
        print('⚠️ Empty audio file path provided');
        return false;
      }
      
      final file = File(audioFilePath);
      final exists = await file.exists();
      
      if (exists) {
        final size = await file.length();
        print('✅ Audio file verified: $audioFilePath ($size bytes)');
        return true;
      } else {
        print('❌ Audio file does not exist: $audioFilePath');
        return false;
      }
    } catch (e) {
      print('❌ Error verifying audio file: $e');
      return false;
    }
  }

  void resetAmberAlertFlag() {
    _isAmberAlertActive = false;
    print('🔄 Amber alert flag manually reset');
  }
  
  void forceResetAmberAlert() {
    _isAmberAlertActive = false;
    print('🔄 Amber alert state force reset');
  }

  Future<bool> areNotificationsAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  Future<bool> requestBasicPermissions() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  void debugTestAmberAlert() {
    print('🧪 DEBUG: Testing amber alert navigation...');
    _showLockScreenBypassAlert(
      title: 'DEBUG TEST ALERT',
      message: 'This is a debug test',
      taskDescription: 'debug test',
    );
  }
}