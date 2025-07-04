// lib/services/reflection_settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ReflectionStyle { silent, audio, takeover }

class ReflectionSettingsService {
  // Storage keys
  static const String _enabledKey = 'reflection_enabled';
  static const String _styleKey = 'reflection_style';
  static const String _timingKey = 'reflection_timing';
  static const String _categoriesKey = 'reflection_categories';
  static const String _voiceStyleKey = 'reflection_voice_style';
  static const String _toneKey = 'reflection_tone';
  static const String _quietHoursKey = 'reflection_quiet_hours';
  static const String _respectDNDKey = 'reflection_respect_dnd';
  static const String _onboardingShownKey = 'reflection_onboarding_shown';

  // Default settings
  static const Map<String, dynamic> _defaultSettings = {
    _enabledKey: false, // Requires explicit opt-in
    _styleKey: 'audio', // Audio check-in (not takeover)
    _timingKey: {
      'quickCheckin': false,      // 30 min - disabled by default
      'followUp': true,           // 2 hours - enabled by default  
      'eveningReview': false,     // 6+ hours - disabled by default
      'quickTime': 30,            // minutes
      'followUpTime': 120,        // minutes
      'eveningTime': 360,         // minutes (6 hours)
    },
    _categoriesKey: [
      'medical',                  // High value - enabled by default
      'important_meeting',        // High value - enabled by default
    ],
    _voiceStyleKey: 'male:Default Male', // Use user's current voice
    _toneKey: 'supportive',
    _quietHoursKey: {
      'enabled': true,
      'startHour': 22,           // 10 PM
      'startMinute': 0,
      'endHour': 8,              // 8 AM  
      'endMinute': 0,
    },
    _respectDNDKey: true,        // Respect Do Not Disturb by default
    _onboardingShownKey: false,
  };

  /// Check if reflections are enabled
  Future<bool> isReflectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? _defaultSettings[_enabledKey] as bool;
  }

  /// Enable/disable reflections
  Future<void> setReflectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    
    print('🎭 Reflections ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if reflections should trigger for this task
  Future<bool> shouldTriggerReflection(Map<String, dynamic> task) async {
    // First check if reflections are enabled at all
    if (!await isReflectionEnabled()) {
      return false;
    }

    // Check if current time respects quiet hours
    if (!await _isOutsideQuietHours()) {
      print('🌙 Reflection blocked: Quiet hours active');
      return false;
    }

    // Check task category against enabled categories
    final taskCategory = _determineTaskCategory(task);
    final enabledCategories = await getEnabledCategories();
    
    if (!enabledCategories.contains(taskCategory)) {
      print('📋 Reflection blocked: Category $taskCategory not enabled');
      return false;
    }

    print('✅ Reflection approved for task: ${task['description']}');
    return true;
  }

  /// Get reflection timing preferences
  Future<List<Duration>> getReflectionTimings() async {
    final prefs = await SharedPreferences.getInstance();
    final timingJson = prefs.getString(_timingKey);
    
    Map<String, dynamic> timing;
    if (timingJson != null) {
      timing = jsonDecode(timingJson);
    } else {
      timing = _defaultSettings[_timingKey] as Map<String, dynamic>;
    }

    List<Duration> timings = [];

    if (timing['quickCheckin'] == true) {
      timings.add(Duration(minutes: timing['quickTime'] ?? 30));
    }

    if (timing['followUp'] == true) {
      timings.add(Duration(minutes: timing['followUpTime'] ?? 120));
    }

    if (timing['eveningReview'] == true) {
      timings.add(Duration(minutes: timing['eveningTime'] ?? 360));
    }

    return timings;
  }

  /// Get notification style preference
  Future<ReflectionStyle> getNotificationStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final styleString = prefs.getString(_styleKey) ?? _defaultSettings[_styleKey] as String;
    
    switch (styleString) {
      case 'silent':
        return ReflectionStyle.silent;
      case 'takeover':
        return ReflectionStyle.takeover;
      default:
        return ReflectionStyle.audio;
    }
  }

  /// Set notification style
  Future<void> setNotificationStyle(ReflectionStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    String styleString;
    
    switch (style) {
      case ReflectionStyle.silent:
        styleString = 'silent';
        break;
      case ReflectionStyle.takeover:
        styleString = 'takeover';
        break;
      default:
        styleString = 'audio';
    }
    
    await prefs.setString(_styleKey, styleString);
    print('🎭 Reflection style set to: $styleString');
  }

  /// Get enabled categories
  Future<List<String>> getEnabledCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(_categoriesKey);
    
    if (categoriesJson != null) {
      return List<String>.from(jsonDecode(categoriesJson));
    } else {
      return List<String>.from(_defaultSettings[_categoriesKey] as List);
    }
  }

  /// Set enabled categories
  Future<void> setEnabledCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoriesKey, jsonEncode(categories));
    print('📋 Reflection categories updated: $categories');
  }

  /// Get voice preferences
  Future<Map<String, dynamic>> getVoicePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'voiceStyle': prefs.getString(_voiceStyleKey) ?? _defaultSettings[_voiceStyleKey] as String,
      'tone': prefs.getString(_toneKey) ?? _defaultSettings[_toneKey] as String,
    };
  }

  /// Set voice style
  Future<void> setVoiceStyle(String voiceStyle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceStyleKey, voiceStyle);
    print('🎵 Reflection voice style set to: $voiceStyle');
  }

  /// Set tone
  Future<void> setTone(String tone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_toneKey, tone);
    print('🎭 Reflection tone set to: $tone');
  }

  /// Get quiet hours settings
  Future<Map<String, dynamic>> getQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final quietHoursJson = prefs.getString(_quietHoursKey);
    
    if (quietHoursJson != null) {
      return jsonDecode(quietHoursJson);
    } else {
      return Map<String, dynamic>.from(_defaultSettings[_quietHoursKey] as Map);
    }
  }

  /// Set quiet hours
  Future<void> setQuietHours(Map<String, dynamic> quietHours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quietHoursKey, jsonEncode(quietHours));
    print('🌙 Quiet hours updated: $quietHours');
  }

  /// Check if Do Not Disturb should be respected
  Future<bool> shouldRespectDND() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_respectDNDKey) ?? _defaultSettings[_respectDNDKey] as bool;
  }

  /// Set DND respect preference
  Future<void> setRespectDND(bool respect) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_respectDNDKey, respect);
    print('📵 DND respect set to: $respect');
  }

  /// Check if onboarding has been shown
  Future<bool> hasShownOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingShownKey) ?? _defaultSettings[_onboardingShownKey] as bool;
  }

  /// Mark onboarding as shown
  Future<void> markOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingShownKey, true);
    print('🎓 Reflection onboarding marked as shown');
  }

  /// Get all settings as a map for UI display
  Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'enabled': await isReflectionEnabled(),
      'style': await getNotificationStyle(),
      'timing': jsonDecode(prefs.getString(_timingKey) ?? jsonEncode(_defaultSettings[_timingKey])),
      'categories': await getEnabledCategories(),
      'voicePreferences': await getVoicePreferences(),
      'quietHours': jsonDecode(prefs.getString(_quietHoursKey) ?? jsonEncode(_defaultSettings[_quietHoursKey])),
      'respectDND': prefs.getBool(_respectDNDKey) ?? _defaultSettings[_respectDNDKey] as bool,
    };
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_enabledKey, _defaultSettings[_enabledKey] as bool);
    await prefs.setString(_styleKey, _defaultSettings[_styleKey] as String);
    await prefs.setString(_timingKey, jsonEncode(_defaultSettings[_timingKey]));
    await prefs.setString(_categoriesKey, jsonEncode(_defaultSettings[_categoriesKey]));
    await prefs.setString(_voiceStyleKey, _defaultSettings[_voiceStyleKey] as String);
    await prefs.setString(_toneKey, _defaultSettings[_toneKey] as String);
    await prefs.setString(_quietHoursKey, jsonEncode(_defaultSettings[_quietHoursKey]));
    await prefs.setBool(_respectDNDKey, _defaultSettings[_respectDNDKey] as bool);
    
    print('🔄 Reflection settings reset to defaults');
  }

  // Private helper methods

  /// Check if current time is outside quiet hours
  Future<bool> _isOutsideQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final quietHoursJson = prefs.getString(_quietHoursKey);
    
    Map<String, dynamic> quietHours;
    if (quietHoursJson != null) {
      quietHours = jsonDecode(quietHoursJson);
    } else {
      quietHours = _defaultSettings[_quietHoursKey] as Map<String, dynamic>;
    }

    if (quietHours['enabled'] != true) {
      return true; // Quiet hours disabled
    }

    final now = DateTime.now();
    final startHour = quietHours['startHour'] as int;
    final startMinute = quietHours['startMinute'] as int;
    final endHour = quietHours['endHour'] as int;
    final endMinute = quietHours['endMinute'] as int;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    // Handle overnight quiet hours (e.g., 22:00 to 08:00)
    if (startMinutes > endMinutes) {
      return currentMinutes < startMinutes && currentMinutes >= endMinutes;
    } else {
      return currentMinutes < startMinutes || currentMinutes >= endMinutes;
    }
  }

  /// Determine task category for reflection filtering
  String _determineTaskCategory(Map<String, dynamic> task) {
    final description = (task['description'] as String? ?? '').toLowerCase();
    final taskType = task['taskType'] as String? ?? '';

    // Medical appointments
    if (description.contains('doctor') || 
        description.contains('appointment') || 
        description.contains('medical') ||
        description.contains('dentist') ||
        description.contains('therapy')) {
      return 'medical';
    }

    // Important meetings
    if (description.contains('meeting') || 
        description.contains('interview') || 
        description.contains('presentation') ||
        taskType.toLowerCase() == 'work') {
      return 'important_meeting';
    }

    // Fitness
    if (description.contains('workout') || 
        description.contains('gym') || 
        description.contains('exercise') ||
        taskType.toLowerCase() == 'exercise') {
      return 'fitness';
    }

    // Personal
    if (taskType.toLowerCase() == 'personal' || 
        description.contains('personal')) {
      return 'personal';
    }

    // Default to general
    return 'general';
  }
}