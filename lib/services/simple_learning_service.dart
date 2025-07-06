// lib/services/simple_learning_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// lib/services/simple_learning_service.dart - IMPROVED VERSION
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 🧠 SimpleLearningService - Enhanced with Better Tone Detection
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
  
  // 🔧 IMPROVED: Better pattern detection thresholds
  static const int _minConversationsForPersonalization = 3;
  static const int _shortResponseThreshold = 50;
  static const int _detailedResponseThreshold = 150; // Lowered from 200
  
  // 🔥 ENHANCED: More comprehensive slang detection
  static const List<String> _enthusiasmMarkers = [
    '!', '😊', '😄', '🎉', '💪', '✨', '🚀', '🔥', '💯', '👏', '🙌',
    'awesome', 'great', 'amazing', 'excited', 'happy', 'love', 'fantastic', 
    'wonderful', 'excellent', 'brilliant', 'epic', 'incredible', 'perfect',
    'fire', 'lit', 'dope', 'sick', 'beast', 'legendary', 'goated'
  ];
  
  // 🗣️ ENHANCED: More Gen Z and casual detection
  static const List<String> _casualMarkers = [
    'yeah', 'yep', 'nah', 'gonna', 'wanna', 'kinda', 'sorta', 
    'lol', 'haha', 'cool', 'ok', 'okay', 'alright', 'sure',
    // Gen Z / Modern slang
    'bruh', 'fr', 'ngl', 'tbh', 'lowkey', 'highkey', 'deadass', 'cap', 'no cap',
    'slaps', 'hits different', 'vibe', 'vibes', 'mood', 'periodt', 'bet', 'say less',
    'fire', 'lit', 'dope', 'sick', 'af', 'asf', 'fam', 'bestie', 'bestfriend',
    'sis', 'bro', 'dude', 'homie', 'facts', 'periodt', 'slay', 'queen', 'king',
    'stan', 'simp', 'sus', 'based', 'cringe', 'mid', 'bussin', 'sheesh',
    'w take', 'l take', 'ratio', 'touch grass', 'main character', 'salty'
  ];
  
  // 🎯 ENHANCED: Professional language indicators
  static const List<String> _professionalMarkers = [
    'meeting', 'appointment', 'scheduled', 'completed', 'productive', 
    'successful', 'according to plan', 'as expected', 'proceeded', 
    'discussion', 'presentation', 'conference', 'regarding', 'furthermore',
    'therefore', 'however', 'nevertheless', 'consequently', 'accordingly'
  ];
  
  /// Learn from a user's response with enhanced detection
  static Future<void> learnFromResponse(String userResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Increment conversation count
    final conversationCount = (prefs.getInt(_conversationCountKey) ?? 0) + 1;
    await prefs.setInt(_conversationCountKey, conversationCount);
    
    // 🔥 ENHANCED: Better analysis with scoring system
    final enthusiasmScore = _calculateEnthusiasmScore(userResponse);
    final casualScore = _calculateCasualScore(userResponse);
    final professionalScore = _calculateProfessionalScore(userResponse);
    final responseLength = userResponse.length;
    
    // 🎯 IMPROVED: Use scoring thresholds instead of binary detection
    final isEnthusiastic = enthusiasmScore >= 2; // Was just true/false
    final isCasual = casualScore >= 2; // Was just true/false
    final isProfessional = professionalScore >= 2;
    
    // Update counters
    if (isEnthusiastic) {
      final enthusiasticCount = (prefs.getInt(_enthusiasticCountKey) ?? 0) + 1;
      await prefs.setInt(_enthusiasticCountKey, enthusiasticCount);
    }
    
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
    
    // 🎯 IMPROVED: Better tone determination after minimum conversations
    if (conversationCount >= _minConversationsForPersonalization) {
      await _updatePreferredToneEnhanced();
    }
    
    print('🧠 Enhanced Learning - Conversation #$conversationCount');
    print('📊 Enthusiasm: $enthusiasmScore, Casual: $casualScore, Professional: $professionalScore');
    print('🎯 Final Detection - Enthusiastic: $isEnthusiastic, Casual: $isCasual, Length: $responseLength');
  }
  
  /// 🔥 NEW: Calculate enthusiasm score (0-5)
  static int _calculateEnthusiasmScore(String text) {
    final lowerText = text.toLowerCase();
    int score = 0;
    
    for (String marker in _enthusiasmMarkers) {
      if (marker.length == 1) {
        // Count emojis and punctuation
        score += text.split(marker).length - 1;
      } else if (lowerText.contains(marker)) {
        // Strong enthusiasm words get 2 points
        if (['fire', 'lit', 'dope', 'sick', 'amazing', 'epic'].contains(marker)) {
          score += 2;
        } else {
          score += 1;
        }
      }
    }
    
    return score;
  }
  
  /// 🗣️ NEW: Calculate casual score (0-5) 
  static int _calculateCasualScore(String text) {
    final lowerText = text.toLowerCase();
    int score = 0;
    
    for (String marker in _casualMarkers) {
      if (lowerText.contains(marker)) {
        // Gen Z slang gets higher scores
        if (['bruh', 'fr', 'ngl', 'deadass', 'fire', 'lit', 'dope', 'af', 'bussin', 'sheesh'].contains(marker)) {
          score += 3; // Heavy weight for strong slang
        } else if (['tbh', 'lowkey', 'vibe', 'mood', 'bet', 'facts'].contains(marker)) {
          score += 2; // Medium weight
        } else {
          score += 1; // Light weight for basic casual words
        }
      }
    }
    
    return score;
  }
  
  /// 👔 NEW: Calculate professional score (0-5)
  static int _calculateProfessionalScore(String text) {
    final lowerText = text.toLowerCase();
    int score = 0;
    
    for (String marker in _professionalMarkers) {
      if (lowerText.contains(marker)) {
        score += 1;
      }
    }
    
    // Professional indicators
    if (text.contains('.') && text.length > 30) score += 1; // Complete sentences
    if (lowerText.contains('thank you') || lowerText.contains('please')) score += 1; // Politeness
    if (!_detectEnthusiasm(text) && !_detectCasualTone(text)) score += 1; // Neutral tone
    
    return score;
  }
  
  /// 🎭 ENHANCED: Better tone determination algorithm
  static Future<void> _updatePreferredToneEnhanced() async {
    final prefs = await SharedPreferences.getInstance();
    
    final enthusiasticCount = prefs.getInt(_enthusiasticCountKey) ?? 0;
    final casualCount = prefs.getInt(_casualCountKey) ?? 0;
    final conversationCount = prefs.getInt(_conversationCountKey) ?? 0;
    
    if (conversationCount == 0) return;
    
    // 🔧 IMPROVED: Lower thresholds and better logic
    final enthusiasticPercent = (enthusiasticCount / conversationCount) * 100;
    final casualPercent = (casualCount / conversationCount) * 100;
    
    String preferredTone;
    
    // 🎯 NEW: Priority-based tone detection
    if (casualPercent >= 40) { // Lowered from 60% to 40%
      if (enthusiasticPercent >= 40) {
        preferredTone = 'enthusiastic_casual'; // NEW: Combo tone
      } else {
        preferredTone = 'casual';
      }
    } else if (enthusiasticPercent >= 50) { // Lowered from 60%
      preferredTone = 'enthusiastic';
    } else if (enthusiasticPercent < 20 && casualPercent < 20) {
      preferredTone = 'professional';
    } else {
      preferredTone = 'balanced';
    }
    
    await prefs.setString(_preferredToneKey, preferredTone);
    print('🎭 Enhanced tone updated to: $preferredTone (Casual: ${casualPercent.toStringAsFixed(1)}%, Enthusiastic: ${enthusiasticPercent.toStringAsFixed(1)}%)');
  }
  
  /// Generate personalized text with enhanced tone matching
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
    
    // 🎯 ENHANCED: Better tone modifiers
    switch (preferredTone) {
      case 'enthusiastic':
        promptModifiers.add('Be very enthusiastic and energetic in your response!');
        promptModifiers.add('Use exclamation points and positive language like "awesome", "amazing", "fantastic"!');
        break;
      case 'casual':
        promptModifiers.add('Keep the tone very casual and conversational, like talking to a close friend.');
        promptModifiers.add('Use friendly, informal language. Be relaxed and natural.');
        break;
      case 'enthusiastic_casual':
        promptModifiers.add('Be enthusiastic AND casual - like an excited best friend!');
        promptModifiers.add('Use informal language with lots of energy and positivity!');
        break;
      case 'professional':
        promptModifiers.add('Maintain a professional, polite, and respectful tone.');
        promptModifiers.add('Be clear and supportive while keeping language formal and appropriate.');
        break;
      case 'balanced':
        promptModifiers.add('Use a balanced tone - supportive and encouraging but not overly casual or formal.');
        break;
    }
    
    // Add length preference
    if (avgResponseLength < _shortResponseThreshold) {
      promptModifiers.add('The user prefers brief, concise responses - keep it short and to the point.');
    } else if (avgResponseLength > _detailedResponseThreshold) {
      promptModifiers.add('The user appreciates detailed responses - feel free to be thorough and explanatory.');
    }
    
    // Combine base prompt with personalization
    final personalizedPrompt = '$basePrompt\n\nPersonalization guidelines:\n${promptModifiers.join('\n')}';
    
    print('🎯 Enhanced personalized prompt generated with tone: $preferredTone');
    return personalizedPrompt;
  }
  
  /// Get current learning statistics with enhanced info
  static Future<Map<String, dynamic>> getLearningStats() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationCount = prefs.getInt(_conversationCountKey) ?? 0;
    final enthusiasticCount = prefs.getInt(_enthusiasticCountKey) ?? 0;
    final casualCount = prefs.getInt(_casualCountKey) ?? 0;
    
    return {
      'conversationCount': conversationCount,
      'enthusiasticResponses': enthusiasticCount,
      'casualResponses': casualCount,
      'shortResponses': prefs.getInt(_shortResponseCountKey) ?? 0,
      'detailedResponses': prefs.getInt(_detailedResponseCountKey) ?? 0,
      'preferredTone': prefs.getString(_preferredToneKey) ?? 'unknown',
      'averageResponseLength': prefs.getDouble(_averageResponseLengthKey) ?? 0.0,
      'hasEnoughData': conversationCount >= _minConversationsForPersonalization,
      // NEW: Percentage breakdowns
      'casualPercent': conversationCount > 0 ? (casualCount / conversationCount * 100) : 0.0,
      'enthusiasticPercent': conversationCount > 0 ? (enthusiasticCount / conversationCount * 100) : 0.0,
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
    
    print('🔄 Enhanced learning data reset');
  }
  
  // Keep original methods for backward compatibility
  static bool _detectEnthusiasm(String text) {
    return _calculateEnthusiasmScore(text) >= 1;
  }
  
  static bool _detectCasualTone(String text) {
    return _calculateCasualScore(text) >= 1;
  }
}