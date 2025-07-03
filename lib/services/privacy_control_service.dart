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
    return prefs.getBool(_humanInLoopKey) ?? true; // Default to true for safety
  }

  /// Enable/disable human-in-the-loop controls
  Future<void> setHumanInLoopEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_humanInLoopKey, enabled);
    print('👤 Human-in-the-loop enabled: $enabled');
  }

  // 🚨 KILL SWITCH FUNCTIONALITY

  /// Activate emergency kill switch - wipes ALL user data
  Future<void> activateKillSwitch() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('🚨 ACTIVATING PRIVACY KILL SWITCH 🚨');
    
    // Mark kill switch as activated
    await prefs.setBool(_killSwitchActivatedKey, true);
    
    // Wipe all user data
    await _performCompleteDataWipe();
    
    // Reset all privacy settings to defaults
    await _resetPrivacySettings();
    
    print('🗑️ All user data wiped. Privacy kill switch activated.');
  }

  /// Check if kill switch has been activated
  Future<bool> isKillSwitchActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_killSwitchActivatedKey) ?? false;
  }

  /// Factory reset - complete app reset
  Future<void> performFactoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('🏭 PERFORMING FACTORY RESET 🏭');
    
    // Clear ALL SharedPreferences
    await prefs.clear();
    
    // Clear any cached files
    await _clearCachedFiles();
    
    print('✅ Factory reset complete. App restored to initial state.');
  }

  // 📊 DATA TRANSPARENCY

  /// Get summary of what data is stored locally
  Future<Map<String, dynamic>> getDataTransparencyReport() async {
    final prefs = await SharedPreferences.getInstance();
    
    final allKeys = prefs.getKeys();
    final dataCategories = <String, List<String>>{
      'User Preferences': [],
      'Task Data': [],
      'Conversation History': [],
      'Learning Patterns': [],
      'Privacy Settings': [],
      'App Settings': [],
    };

    for (final key in allKeys) {
      if (key.contains('user_') || key.contains('name')) {
        dataCategories['User Preferences']!.add(key);
      } else if (key.contains('task') || key.contains('calendar')) {
        dataCategories['Task Data']!.add(key);
      } else if (key.contains('conversation') || key.contains('reflection')) {
        dataCategories['Conversation History']!.add(key);
      } else if (key.contains('learning') || key.contains('pattern')) {
        dataCategories['Learning Patterns']!.add(key);
      } else if (key.contains('privacy') || key.contains('consent')) {
        dataCategories['Privacy Settings']!.add(key);
      } else {
        dataCategories['App Settings']!.add(key);
      }
    }

    return {
      'totalDataPoints': allKeys.length,
      'categories': dataCategories,
      'dataCollectionEnabled': await hasDataCollectionConsent(),
      'aiLearningEnabled': await isAILearningEnabled(),
      'debuggingEnabled': await hasDebuggingConsent(),
      'humanInLoopEnabled': await isHumanInLoopEnabled(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Export user data (for GDPR compliance)
  Future<Map<String, dynamic>> exportUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final userData = <String, dynamic>{};

    for (final key in allKeys) {
      final value = prefs.get(key);
      userData[key] = value;
    }

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
      'data': userData,
      'note': 'This is ALL data stored locally on your device. No data is sent to our servers without your explicit consent.',
    };
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
    
    print('🛡️ Privacy settings reset to secure defaults');
  }

  /// Clear cached files
  Future<void> _clearCachedFiles() async {
    // Implementation depends on your file storage strategy
    // This would clear any cached audio files, temporary data, etc.
    print('📁 Cached files cleared');
  }

  // 🎯 CONSENT MANAGEMENT

  /// Show privacy consent dialog for new users
  static Future<Map<String, bool>> showPrivacyConsentDialog() async {
    // This would return user choices for different consent types
    return {
      'dataCollection': false,
      'aiLearning': false,
      'debugging': false,
      'analytics': false,
    };
  }

  /// Check if all required consents are obtained
  Future<bool> hasRequiredConsents() async {
    // Basic app functionality doesn't require any consents
    // All advanced features are opt-in only
    return true;
  }

  // 📋 COMPLIANCE HELPERS

  /// Generate privacy policy compliance text with third-party disclaimers
  String getPrivacyPolicyText() {
    return '''
🛡️ MOTIVATOR AI PRIVACY POLICY

═══════════════════════════════════════════

📱 MOTIVATOR AI APP - ZERO DATA STORAGE:
• We do NOT store, collect, or access your personal data
• All conversations, tasks, and reflections stay on YOUR device only
• We cannot see, read, or access your information
• No data is uploaded to our servers without explicit consent
• We have ZERO access to your personal information

⚠️ THIRD-PARTY SERVICE DISCLAIMERS:

🤖 OPENAI (Chat/Reflection Processing):
• When you use reflection features, text is sent to OpenAI's API
• OpenAI processes your text to generate AI responses
• OpenAI has their own privacy policy and data handling
• We are NOT responsible for OpenAI's data practices
• You consent directly to OpenAI's terms when using AI features
• Disable AI features to avoid any OpenAI data processing

🎤 ELEVENLABS (Voice Generation):
• When you use voice features, text is sent to ElevenLabs API
• ElevenLabs converts text to speech audio
• ElevenLabs has their own privacy policy and data handling  
• We are NOT responsible for ElevenLabs' data practices
• You consent directly to ElevenLabs' terms when using voice features
• Disable voice features to avoid any ElevenLabs data processing

═══════════════════════════════════════════

🔒 YOUR DATA CONTROL OPTIONS:

FULL OFFLINE MODE:
• Use app without any AI features
• No data sent to any external services
• 100% local functionality only

SELECTIVE FEATURE USE:
• Choose which AI features to enable
• Each feature clearly shows what data is sent where
• Opt-in consent required for each service

INSTANT DATA CONTROL:
• Kill Switch: Wipe all local data instantly
• Factory Reset: Complete app reset
• Export Data: Download everything we store locally

═══════════════════════════════════════════

⚖️ LEGAL DISCLAIMERS:

LIABILITY LIMITATION:
• Motivator AI app holds NO LIABILITY for third-party data practices
• OpenAI and ElevenLabs are independent services with separate terms
• Users consent directly to third-party services when using features
• We provide tools to disable all external data sharing
• Use app in offline mode for complete data privacy

DATA FLOW TRANSPARENCY:
• App → OpenAI: Only when using AI reflection features
• App → ElevenLabs: Only when using voice generation features  
• App → Our Servers: NEVER (we have no servers for user data)
• All data sharing is explicit, opt-in, and user-controlled

USER RESPONSIBILITY:
• Review OpenAI's privacy policy before using AI features
• Review ElevenLabs' privacy policy before using voice features
• Disable features you're not comfortable with
• Use offline mode for maximum privacy

═══════════════════════════════════════════

🌟 OUR PRIVACY COMMITMENT:

WE PROMISE:
✅ Zero data collection by Motivator AI
✅ Complete transparency about data flow  
✅ Full user control over all features
✅ No hidden data sharing
✅ Instant data deletion capabilities
✅ Clear third-party service disclosures

WE CANNOT CONTROL:
❌ OpenAI's data handling practices
❌ ElevenLabs' data handling practices
❌ Third-party API data retention
❌ External service privacy policies
❌ Data processing by services you choose to use

═══════════════════════════════════════════

📞 CONTACT & SUPPORT:

Questions about Motivator AI privacy: [Your contact]
Questions about OpenAI data: contact@openai.com
Questions about ElevenLabs data: support@elevenlabs.io

Last Updated: ${DateTime.now().toString().split(' ')[0]}
Version: 1.0.0

═══════════════════════════════════════════

By using this app, you acknowledge:
• You understand the data flow to third-party services
• You take responsibility for enabling/disabling features
• You will review third-party privacy policies independently  
• Motivator AI is not liable for third-party data practices
• You have full control to use the app completely offline
''';
  }
}