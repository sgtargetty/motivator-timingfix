// lib/services/privacy_control_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class PrivacyControlService {
  // Storage keys
  static const String _dataCollectionKey = 'data_collection_consent';
  static const String _aiLearningKey = 'ai_learning_enabled';
  static const String _debuggingConsentKey = 'debugging_consent';
  static const String _humanInLoopKey = 'human_in_loop_enabled';
  static const String _killSwitchActivatedKey = 'kill_switch_activated';
  static const String _userDataKey = 'user_stored_data';
  static const String _conversationHistoryKey = 'conversation_history';
  static const String _learningPatternsKey = 'learning_patterns';

  // 🛡️ PRIVACY CONTROLS
  
  /// Check if user has consented to data collection
  Future<bool> hasDataCollectionConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dataCollectionKey) ?? false;
  }

  /// Set data collection consent
  Future<void> setDataCollectionConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataCollectionKey, consent);
    
    if (!consent) {
      // If consent revoked, clear collected data
      await _clearCollectedData();
    }
    
    print('🛡️ Data collection consent: $consent');
  }

  /// Check if AI learning is enabled
  Future<bool> isAILearningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiLearningKey) ?? false;
  }

  /// Enable/disable AI learning
  Future<void> setAILearningEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiLearningKey, enabled);
    
    if (!enabled) {
      await _clearLearningData();
    }
    
    print('🧠 AI learning enabled: $enabled');
  }

  /// Check if debugging consent is given
  Future<bool> hasDebuggingConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_debuggingConsentKey) ?? false;
  }

  /// Set debugging consent
  Future<void> setDebuggingConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debuggingConsentKey, consent);
    print('🔧 Debugging consent: $consent');
  }

  /// Check if human-in-the-loop is enabled
  Future<bool> isHumanInLoopEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_humanInLoopKey) ?? true; // Default to enabled for safety
  }

  /// Enable/disable human-in-the-loop controls
  Future<void> setHumanInLoopEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_humanInLoopKey, enabled);
    print('👤 Human-in-loop enabled: $enabled');
  }

  /// Check if kill switch has been activated
  Future<bool> isKillSwitchActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_killSwitchActivatedKey) ?? false;
  }

  /// Activate emergency kill switch
  Future<void> activateKillSwitch() async {
    print('🚨 EMERGENCY KILL SWITCH ACTIVATED');
    
    // Stop all data collection immediately
    await setDataCollectionConsent(false);
    await setAILearningEnabled(false);
    await setDebuggingConsent(false);
    
    // Clear all data
    await _performCompleteDataWipe();
    
    // Mark kill switch as activated
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_killSwitchActivatedKey, true);
    
    // Provide haptic feedback
    HapticFeedback.heavyImpact();
    
    print('💀 All user data wiped, AI features disabled');
  }

  /// Get transparency report
  Future<Map<String, dynamic>> getTransparencyReport() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Count stored data
    final allKeys = prefs.getKeys();
    final userDataKeys = allKeys.where((key) => 
      !key.startsWith('flutter.') && 
      !key.startsWith('system_')
    ).toList();
    
    return {
      'dataCollectionConsent': await hasDataCollectionConsent(),
      'aiLearningEnabled': await isAILearningEnabled(),
      'debuggingConsent': await hasDebuggingConsent(),
      'humanInLoopEnabled': await isHumanInLoopEnabled(),
      'killSwitchActivated': await isKillSwitchActivated(),
      'storedDataKeys': userDataKeys.length,
      'storageBreakdown': _analyzeStoredData(allKeys),
      'lastUpdated': DateTime.now().toIso8601String(),
      'privacyStatement': 'No data is sent to our servers without your explicit consent.',
    };
  }

  /// Export all user data for portability
  Future<Map<String, dynamic>> exportUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    Map<String, dynamic> exportData = {};
    
    for (String key in allKeys) {
      if (!key.startsWith('flutter.') && !key.startsWith('system_')) {
        final value = prefs.get(key);
        exportData[key] = value;
      }
    }
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'userData': exportData,
      'privacySettings': await getTransparencyReport(),
    };
  }

  /// Factory reset - clear everything and reset to defaults
  Future<void> factoryReset() async {
    print('🏭 Factory reset initiated');
    
    await _performCompleteDataWipe();
    await _resetPrivacySettings();
    
    print('🔄 Factory reset complete');
  }

  // 🔒 PRIVATE HELPER METHODS

  /// Clear all collected user data
  Future<void> _clearCollectedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final keysToRemove = prefs.getKeys().where((key) => 
      key.contains('conversation') || 
      key.contains('reflection') ||
      key.contains('user_interaction') ||
      key.contains('behavior_pattern')
    ).toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    
    print('🗑️ Collected data cleared');
  }

  /// Clear AI learning data
  Future<void> _clearLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final keysToRemove = prefs.getKeys().where((key) => 
      key.contains('learning') || 
      key.contains('pattern') ||
      key.contains('adaptation') ||
      key.contains('personality_profile')
    ).toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    
    print('🧠 Learning data cleared');
  }

  /// Perform complete data wipe
  Future<void> _performCompleteDataWipe() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get all user-related keys
    final userDataKeys = prefs.getKeys().where((key) => 
      !key.startsWith('flutter.') && // Keep Flutter system preferences
      !key.startsWith('system_') // Keep system-level settings
    ).toList();

    // Remove all user data
    for (final key in userDataKeys) {
      await prefs.remove(key);
    }
    
    print('🗑️ Complete user data wipe performed');
  }

  /// Reset privacy settings to defaults
  Future<void> _resetPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_dataCollectionKey, false);
    await prefs.setBool(_aiLearningKey, false);
    await prefs.setBool(_debuggingConsentKey, false);
    await prefs.setBool(_humanInLoopKey, true);
    await prefs.setBool(_killSwitchActivatedKey, false);
    
    print('🛡️ Privacy settings reset to secure defaults');
  }

  /// Analyze stored data for transparency report
  Map<String, dynamic> _analyzeStoredData(Set<String> allKeys) {
    Map<String, int> breakdown = {
      'settings': 0,
      'tasks': 0,
      'conversations': 0,
      'learning': 0,
      'other': 0,
    };

    for (String key in allKeys) {
      if (key.contains('setting') || key.contains('config')) {
        breakdown['settings'] = breakdown['settings']! + 1;
      } else if (key.contains('task') || key.contains('calendar')) {
        breakdown['tasks'] = breakdown['tasks']! + 1;
      } else if (key.contains('conversation') || key.contains('reflection')) {
        breakdown['conversations'] = breakdown['conversations']! + 1;
      } else if (key.contains('learning') || key.contains('pattern')) {
        breakdown['learning'] = breakdown['learning']! + 1;
      } else if (!key.startsWith('flutter.')) {
        breakdown['other'] = breakdown['other']! + 1;
      }
    }

    return breakdown;
  }

  /// Clear cached files
  Future<void> _clearCachedFiles() async {
    // Implementation depends on your file storage strategy
    // This would clear any cached audio files, temporary data, etc.
    print('📁 Cached files cleared');
  }
}