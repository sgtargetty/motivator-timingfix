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
      case 'audio':
      default:
        return ReflectionStyle.audio;
    }
  }

  /// Get enabled reflection categories
  Future<List<String>> getEnabledCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString(_categoriesKey);
    
    if (categoriesJson != null) {
      return List<String>.from(jsonDecode(categoriesJson));
    } else {
      return List<String>.from(_defaultSettings[_categoriesKey] as List);
    }
  }

  /// Update reflection settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'enabled':
          await prefs.setBool(_enabledKey, value as bool);
          break;
        case 'style':
          await prefs.setString(_styleKey, value as String);
          break;
        case 'timing':
          await prefs.setString(_timingKey, jsonEncode(value));
          break;
        case 'categories':
          await prefs.setString(_categoriesKey, jsonEncode(value));
          break;
        case 'voiceStyle':
          await prefs.setString(_voiceStyleKey, value as String);
          break;
        case 'tone':
          await prefs.setString(_toneKey, value as String);
          break;
        case 'quietHours':
          await prefs.setString(_quietHoursKey, jsonEncode(value));
          break;
        case 'respectDND':
          await prefs.setBool(_respectDNDKey, value as bool);
          break;
      }
    }

    print('⚙️ Reflection settings updated: ${settings.keys.join(', ')}');
  }

  /// Get current reflection voice and tone preferences
  Future<Map<String, String>> getVoicePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'voiceStyle': prefs.getString(_voiceStyleKey) ?? _defaultSettings[_voiceStyleKey] as String,
      'tone': prefs.getString(_toneKey) ?? _defaultSettings[_toneKey] as String,
    };
  }

  /// Check if onboarding has been shown
  Future<bool> hasShownOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingShownKey) ?? false;
  }

  /// Mark onboarding as shown
  Future<void> setOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingShownKey, true);
  }

  /// Get all current settings for display
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
    final taskType = task['taskType'] as String?;

    // Check explicit task type first
    if (taskType != null) {
      switch (taskType.toLowerCase()) {
        case 'medical':
          return 'medical';
        case 'work':
          return 'work';
        case 'exercise':
        case 'fitness':
          return 'fitness';
        case 'study':
        case 'learning':
          return 'study';
        case 'personal':
          return 'personal';
        case 'creative':
          return 'creative';
      }
    }

    // Fallback to description analysis
    if (description.contains('doctor') || description.contains('dentist') || 
        description.contains('appointment') || description.contains('medical') ||
        description.contains('therapy') || description.contains('va ')) {
      return 'medical';
    }

    if (description.contains('meeting') || description.contains('important') ||
        description.contains('presentation') || description.contains('interview')) {
      return 'important_meeting';
    }

    if (description.contains('gym') || description.contains('workout') || 
        description.contains('exercise') || description.contains('run')) {
      return 'fitness';
    }

    if (description.contains('study') || description.contains('learn') || 
        description.contains('class') || description.contains('exam')) {
      return 'study';
    }

    if (description.contains('work') || description.contains('project') ||
        description.contains('deadline')) {
      return 'work';
    }

    return 'general';
  }
}