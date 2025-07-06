// lib/services/simple_learning_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 🧠 SimpleLearningService - Phase 1 of AI Companion
/// Detects and learns basic communication patterns from user responses
class SimpleLearningService {
  // Storage keys
  static const String _patternPrefix = 'learning_pattern_';
  static const String _conversationCountKey = 'total_conversations';
  static const String _enthusiasticCountKey = 'enthusiastic_responses';
  static const String _casualCountKey = 'casual_responses';
  static const String _shortResponseCountKey = 'short_responses';
  static const String _detailedResponseCountKey = 'detailed_responses';
  static const String _preferredToneKey = 'preferred_tone';
  static const String _averageResponseLengthKey = 'avg_response_length';
  
  // Pattern detection thresholds
  static const int _minConversationsForPersonalization = 3;
  static const int _shortResponseThreshold = 50; // characters
  static const int _detailedResponseThreshold = 200; // characters
  
  // Enthusiasm indicators
  static const List<String> _enthusiasmMarkers = [
    '!', '😊', '😄', '🎉', '💪', '✨', '🚀', 'awesome', 'great', 'amazing',
    'excited', 'happy', 'love', 'fantastic', 'wonderful', 'excellent'
  ];
  
  // Casual indicators
  static const List<String> _casualMarkers = [
    'yeah', 'yep', 'nah', 'gonna', 'wanna', 'kinda', 'sorta', 
    'lol', 'haha', 'cool', 'ok', 'okay', 'alright', 'sure'
  ];
  
  /// Learn from a user's response and update communication patterns
  static Future<void> learnFromResponse(String userResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Increment conversation count
    final conversationCount = (prefs.getInt(_conversationCountKey) ?? 0) + 1;
    await prefs.setInt(_conversationCountKey, conversationCount);
    
    // Analyze response characteristics
    final isEnthusiastic = _detectEnthusiasm(userResponse);
    final isCasual = _detectCasualTone(userResponse);
    final responseLength = userResponse.length;
    
    // Update enthusiasm counter
    if (isEnthusiastic) {
      final enthusiasticCount = (prefs.getInt(_enthusiasticCountKey) ?? 0) + 1;
      await prefs.setInt(_enthusiasticCountKey, enthusiasticCount);
    }
    
    // Update casual counter
    if (isCasual) {
      final casualCount = (prefs.getInt(_casualCountKey) ?? 0) + 1;
      await prefs.setInt(_casualCountKey, casualCount);
    }
    
    // Update response length patterns
    if (responseLength < _shortResponseThreshold) {
      final shortCount = (prefs.getInt(_shortResponseCountKey) ?? 0) + 1;
      await prefs.setInt(_shortResponseCountKey, shortCount);
    } else if (responseLength > _detailedResponseThreshold) {
      final detailedCount = (prefs.getInt(_detailedResponseCountKey) ?? 0) + 1;
      await prefs.setInt(_detailedResponseCountKey, detailedCount);
    }
    
    // Update average response length
    final currentAvg = prefs.getDouble(_averageResponseLengthKey) ?? 0.0;
    final newAvg = ((currentAvg * (conversationCount - 1)) + responseLength) / conversationCount;
    await prefs.setDouble(_averageResponseLengthKey, newAvg);
    
    // Determine preferred tone after minimum conversations
    if (conversationCount >= _minConversationsForPersonalization) {
      await _updatePreferredTone();
    }
    
    print('🧠 Learning update - Conversation #$conversationCount');
    print('📊 Enthusiastic: $isEnthusiastic, Casual: $isCasual, Length: $responseLength');
  }
  
  /// Generate personalized text based on learned patterns
  static Future<String> generatePersonalizedPrompt(String basePrompt, String taskType) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationCount = prefs.getInt(_conversationCountKey) ?? 0;
    
    // Return base prompt if not enough data
    if (conversationCount < _minConversationsForPersonalization) {
      return basePrompt;
    }
    
    // Get learned preferences
    final preferredTone = prefs.getString(_preferredToneKey) ?? 'balanced';
    final avgResponseLength = prefs.getDouble(_averageResponseLengthKey) ?? 100.0;
    
    // Build personalized prompt additions
    List<String> promptModifiers = [];
    
    // Add tone modifiers
    switch (preferredTone) {
      case 'enthusiastic':
        promptModifiers.add('Be enthusiastic and energetic in your response.');
        promptModifiers.add('Use exclamation points and positive language.');
        break;
      case 'casual':
        promptModifiers.add('Keep the tone casual and conversational.');
        promptModifiers.add('Use friendly, informal language.');
        break;
      case 'professional':
        promptModifiers.add('Maintain a professional but caring tone.');
        promptModifiers.add('Be clear and supportive without being overly casual.');
        break;
    }
    
    // Add length preference
    if (avgResponseLength < _shortResponseThreshold) {
      promptModifiers.add('The user prefers brief responses, so keep it concise.');
    } else if (avgResponseLength > _detailedResponseThreshold) {
      promptModifiers.add('The user appreciates detailed responses, so feel free to be thorough.');
    }
    
    // Combine base prompt with personalization
    final personalizedPrompt = '$basePrompt\n\nPersonalization notes:\n${promptModifiers.join('\n')}';
    
    print('🎯 Personalized prompt generated with tone: $preferredTone');
    return personalizedPrompt;
  }
  
  /// Get current learning statistics
  static Future<Map<String, dynamic>> getLearningStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'conversationCount': prefs.getInt(_conversationCountKey) ?? 0,
      'enthusiasticResponses': prefs.getInt(_enthusiasticCountKey) ?? 0,
      'casualResponses': prefs.getInt(_casualCountKey) ?? 0,
      'shortResponses': prefs.getInt(_shortResponseCountKey) ?? 0,
      'detailedResponses': prefs.getInt(_detailedResponseCountKey) ?? 0,
      'preferredTone': prefs.getString(_preferredToneKey) ?? 'unknown',
      'averageResponseLength': prefs.getDouble(_averageResponseLengthKey) ?? 0.0,
      'hasEnoughData': (prefs.getInt(_conversationCountKey) ?? 0) >= _minConversationsForPersonalization,
    };
  }
  
  /// Reset all learning data (for privacy or testing)
  static Future<void> resetLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_conversationCountKey);
    await prefs.remove(_enthusiasticCountKey);
    await prefs.remove(_casualCountKey);
    await prefs.remove(_shortResponseCountKey);
    await prefs.remove(_detailedResponseCountKey);
    await prefs.remove(_preferredToneKey);
    await prefs.remove(_averageResponseLengthKey);
    
    print('🔄 Learning data reset');
  }
  
  // Private helper methods
  
  static bool _detectEnthusiasm(String text) {
    final lowerText = text.toLowerCase();
    return _enthusiasmMarkers.any((marker) => 
      marker.length == 1 ? text.contains(marker) : lowerText.contains(marker)
    );
  }
  
  static bool _detectCasualTone(String text) {
    final lowerText = text.toLowerCase();
    return _casualMarkers.any((marker) => lowerText.contains(marker));
  }
  
  static Future<void> _updatePreferredTone() async {
    final prefs = await SharedPreferences.getInstance();
    
    final enthusiasticCount = prefs.getInt(_enthusiasticCountKey) ?? 0;
    final casualCount = prefs.getInt(_casualCountKey) ?? 0;
    final conversationCount = prefs.getInt(_conversationCountKey) ?? 1;
    
    // Calculate percentages
    final enthusiasticPercent = enthusiasticCount / conversationCount;
    final casualPercent = casualCount / conversationCount;
    
    String preferredTone;
    if (enthusiasticPercent > 0.6) {
      preferredTone = 'enthusiastic';
    } else if (casualPercent > 0.6) {
      preferredTone = 'casual';
    } else if (enthusiasticPercent < 0.2 && casualPercent < 0.2) {
      preferredTone = 'professional';
    } else {
      preferredTone = 'balanced';
    }
    
    await prefs.setString(_preferredToneKey, preferredTone);
    print('🎭 Preferred tone updated to: $preferredTone');
  }
}