// lib/services/simple_learning_service.dart - HYBRID VERSION
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'authentic_tone_detection.dart';
import 'hybrid_tone_detection.dart';

/// 🧠 SimpleLearningService - Now with HYBRID tone recognition
class SimpleLearningService {
  // Storage keys
  static const String _conversationCountKey = 'total_conversations';
  static const String _toneHistoryKey = 'tone_history';
  static const String _primaryToneKey = 'primary_tone';
  static const String _secondaryToneKey = 'secondary_tone';
  static const String _hybridBlendKey = 'hybrid_blend'; // NEW: Store hybrid pattern
  static const String _toneConfidenceKey = 'tone_confidence';
  static const String _averageResponseLengthKey = 'avg_response_length';
  
  static const int _minConversationsForPersonalization = 3;
  static const int _shortResponseThreshold = 50;
  static const int _detailedResponseThreshold = 150;
  
  /// 🎭 Learn from user response with HYBRID tone detection
  static Future<void> learnFromResponse(String userResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Increment conversation count
    final conversationCount = (prefs.getInt(_conversationCountKey) ?? 0) + 1;
    await prefs.setInt(_conversationCountKey, conversationCount);
    
    // 🎯 HYBRID TONE ANALYSIS
    final hybridAnalysis = HybridToneDetection.analyzeHybridTones(userResponse);
    
    // Store this conversation's hybrid data
    await _storeHybridToneHistory(hybridAnalysis, conversationCount);
    
    // Store in hybrid system
    await HybridToneDetection.storeHybridAnalysis(hybridAnalysis, conversationCount);
    
    // Update response length tracking
    final responseLength = userResponse.length;
    final currentAvg = prefs.getDouble(_averageResponseLengthKey) ?? 0.0;
    final newAvg = ((currentAvg * (conversationCount - 1)) + responseLength) / conversationCount;
    await prefs.setDouble(_averageResponseLengthKey, newAvg);
    
    // 🎭 Update overall hybrid profile after minimum conversations
    if (conversationCount >= _minConversationsForPersonalization) {
      await _updateOverallHybridProfile();
    }
    
    print('🎭 HYBRID Learning - Conversation #$conversationCount');
    print('🎯 Analysis: ${HybridToneDetection.getHybridAnalysisString(hybridAnalysis)}');
    if (hybridAnalysis['type'] == 'hybrid') {
      final significant = hybridAnalysis['significantTones'] as List<dynamic>;
      print('📊 Detected Tones: ${significant.map((t) => '${t['tone']}: ${t['score']}').join(', ')}');
    }
    print('📏 Response Length: $responseLength chars');
  }
  
  /// 📚 Store individual conversation hybrid data
  static Future<void> _storeHybridToneHistory(Map<String, dynamic> hybridAnalysis, int conversationCount) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing tone history
    final toneHistoryJson = prefs.getString(_toneHistoryKey) ?? '[]';
    final List<dynamic> toneHistory = jsonDecode(toneHistoryJson);
    
    // Add new hybrid data
    toneHistory.add({
      'conversation': conversationCount,
      'type': hybridAnalysis['type'],
      'primary': hybridAnalysis['primary'],
      'secondary': hybridAnalysis['secondary'],
      'tertiary': hybridAnalysis['tertiary'],
      'hybrid': hybridAnalysis['hybrid'],
      'blendConfidence': hybridAnalysis['blendConfidence'],
      'significantTones': hybridAnalysis['significantTones'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Keep only last 50 conversations (storage management)
    if (toneHistory.length > 50) {
      toneHistory.removeAt(0);
    }
    
    await prefs.setString(_toneHistoryKey, jsonEncode(toneHistory));
  }
  
  /// 🎯 Analyze all conversations to determine overall hybrid profile
  static Future<void> _updateOverallHybridProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    final toneHistoryJson = prefs.getString(_toneHistoryKey) ?? '[]';
    final List<dynamic> toneHistory = jsonDecode(toneHistoryJson);
    
    if (toneHistory.isEmpty) return;
    
    // Count primary tone frequencies and hybrid patterns
    Map<String, int> primaryCounts = {};
    Map<String, int> hybridCounts = {};
    Map<String, double> hybridConfidences = {};
    
    for (var conversation in toneHistory) {
      String primary = conversation['primary'] ?? 'neutral';
      primaryCounts[primary] = (primaryCounts[primary] ?? 0) + 1;
      
      // Track hybrid patterns
      if (conversation['hybrid'] != null) {
        final hybridKey = conversation['hybrid']['key'] ?? 'unknown';
        hybridCounts[hybridKey] = (hybridCounts[hybridKey] ?? 0) + 1;
        hybridConfidences[hybridKey] = (hybridConfidences[hybridKey] ?? 0.0) + 
                                       (conversation['blendConfidence'] ?? 0.0);
      }
    }
    
    // Determine if user has a consistent hybrid pattern
    String? dominantHybrid;
    double hybridConfidence = 0.0;
    
    if (hybridCounts.isNotEmpty) {
      // Find most frequent hybrid with good confidence
      String topHybrid = '';
      double topScore = 0.0;
      
      hybridCounts.forEach((hybridKey, count) {
        final avgConfidence = hybridConfidences[hybridKey]! / count;
        final frequency = count / toneHistory.length;
        final score = avgConfidence * frequency * count;
        
        if (score > topScore) {
          topScore = score;
          topHybrid = hybridKey;
          hybridConfidence = avgConfidence;
        }
      });
      
      // Only use hybrid if it appears in 40%+ of conversations with good confidence
      if ((hybridCounts[topHybrid]! / toneHistory.length) >= 0.4 && hybridConfidence >= 0.5) {
        dominantHybrid = topHybrid;
      }
    }
    
    // Determine overall primary tone (fallback if no strong hybrid)
    String overallPrimary = 'neutral';
    if (primaryCounts.isNotEmpty) {
      overallPrimary = primaryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    
    // Store overall profile
    await prefs.setString(_primaryToneKey, overallPrimary);
    if (dominantHybrid != null) {
      await prefs.setString(_hybridBlendKey, dominantHybrid);
    }
    
    final confidenceLevel = hybridConfidence >= 0.7 ? 'high' : 
                           hybridConfidence >= 0.4 ? 'medium' : 'low';
    await prefs.setString(_toneConfidenceKey, confidenceLevel);
    
    print('🎭 HYBRID PROFILE UPDATED:');
    if (dominantHybrid != null) {
      print('🎯 Dominant Hybrid: $dominantHybrid (${(hybridConfidence * 100).round()}% confidence)');
    }
    print('🎯 Primary Fallback: $overallPrimary');
    print('📈 Hybrid Frequencies: ${hybridCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ')}');
  }
  
  /// 🎯 Generate personalized prompt with HYBRID tone matching
  static Future<String> generatePersonalizedPrompt(String basePrompt, String taskType) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationCount = prefs.getInt(_conversationCountKey) ?? 0;
    
    // Return base prompt if not enough data
    if (conversationCount < _minConversationsForPersonalization) {
      return basePrompt;
    }
    
    // Get learned tone profile
    final primaryTone = prefs.getString(_primaryToneKey) ?? 'neutral';
    final hybridBlend = prefs.getString(_hybridBlendKey);
    final confidence = prefs.getString(_toneConfidenceKey) ?? 'low';
    final avgResponseLength = prefs.getDouble(_averageResponseLengthKey) ?? 100.0;
    
    // 🎭 Generate HYBRID modifiers if we have a strong blend
    List<String> toneModifiers = [];
    
    if (hybridBlend != null) {
      // Get recent hybrid analysis to build modifiers
      final toneHistoryJson = prefs.getString(_toneHistoryKey) ?? '[]';
      final List<dynamic> toneHistory = jsonDecode(toneHistoryJson);
      
      // Find most recent hybrid analysis
      final recentHybrid = toneHistory.reversed.firstWhere(
        (conversation) => conversation['hybrid']?['key'] == hybridBlend,
        orElse: () => null,
      );
      
      if (recentHybrid != null) {
        final mockHybridAnalysis = {
          'type': 'hybrid',
          'primary': recentHybrid['primary'],
          'secondary': recentHybrid['secondary'],
          'tertiary': recentHybrid['tertiary'],
          'hybrid': recentHybrid['hybrid'],
          'blendConfidence': recentHybrid['blendConfidence'],
        };
        
        toneModifiers = HybridToneDetection.generateHybridModifiers(mockHybridAnalysis);
      }
    } else {
      // Fall back to single tone modifiers
      toneModifiers = AuthenticToneDetection.generateToneModifiers(primaryTone, null);
    }
    
    // Add length preference
    List<String> lengthModifiers = [];
    if (avgResponseLength < _shortResponseThreshold) {
      lengthModifiers.add('Keep responses concise and to the point - user prefers brevity.');
    } else if (avgResponseLength > _detailedResponseThreshold) {
      lengthModifiers.add('Provide detailed, thorough responses - user appreciates depth.');
    }
    
    // Build comprehensive personalized prompt
    List<String> allModifiers = [
      ...toneModifiers,
      ...lengthModifiers,
    ];
    
    final profileDescription = hybridBlend != null 
        ? 'Hybrid Communication Style: $hybridBlend'
        : 'Primary Communication Style: ${_getToneDisplayName(primaryTone)}';
    
    final personalizedPrompt = '''$basePrompt

🎭 PERSONALIZATION PROFILE:
$profileDescription
Confidence Level: $confidence
Average Response Length: ${avgResponseLength.round()} characters

RESPONSE GUIDELINES:
${allModifiers.map((modifier) => '• $modifier').join('\n')}

IMPORTANT: Match the user's authentic communication blend naturally - let their unique personality combination shine through in your response tone and word choices.''';
    
    print('🎯 HYBRID personalized prompt generated:');
    print('🎭 Profile: ${hybridBlend ?? primaryTone}, Confidence: $confidence');
    
    return personalizedPrompt;
  }
  
  /// 📊 Get comprehensive learning statistics with hybrid data
  static Future<Map<String, dynamic>> getLearningStats() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationCount = prefs.getInt(_conversationCountKey) ?? 0;
    
    // Get tone history for detailed analysis
    final toneHistoryJson = prefs.getString(_toneHistoryKey) ?? '[]';
    final List<dynamic> toneHistory = jsonDecode(toneHistoryJson);
    
    // Get hybrid profile
    final hybridProfile = await HybridToneDetection.getHybridProfile();
    
    // Calculate tone frequencies (including hybrids)
    Map<String, int> toneFrequencies = {};
    Map<String, int> hybridFrequencies = {};
    
    for (var conversation in toneHistory) {
      String primary = conversation['primary'] ?? 'neutral';
      toneFrequencies[primary] = (toneFrequencies[primary] ?? 0) + 1;
      
      if (conversation['hybrid'] != null) {
        String hybridKey = conversation['hybrid']['key'] ?? 'unknown';
        hybridFrequencies[hybridKey] = (hybridFrequencies[hybridKey] ?? 0) + 1;
      }
    }
    
    return {
      'conversationCount': conversationCount,
      'primaryTone': prefs.getString(_primaryToneKey) ?? 'unknown',
      'hybridBlend': prefs.getString(_hybridBlendKey),
      'toneConfidence': prefs.getString(_toneConfidenceKey) ?? 'unknown',
      'averageResponseLength': prefs.getDouble(_averageResponseLengthKey) ?? 0.0,
      'hasEnoughData': conversationCount >= _minConversationsForPersonalization,
      'toneFrequencies': toneFrequencies,
      'hybridFrequencies': hybridFrequencies,
      'hybridProfile': hybridProfile,
      'recentTones': toneHistory.take(10).map((c) => {
        'conversation': c['conversation'],
        'type': c['type'] ?? 'single',
        'primary': c['primary'],
        'hybrid': c['hybrid']?['name'],
        'confidence': c['blendConfidence'] ?? c['confidence'] ?? 0.0,
      }).toList(),
    };
  }
  
  /// 🗑️ Reset all learning data including hybrid data
  static Future<void> resetLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_conversationCountKey);
    await prefs.remove(_toneHistoryKey);
    await prefs.remove(_primaryToneKey);
    await prefs.remove(_secondaryToneKey);
    await prefs.remove(_hybridBlendKey);
    await prefs.remove(_toneConfidenceKey);
    await prefs.remove(_averageResponseLengthKey);
    
    // Also clear hybrid detection storage
    await prefs.remove('hybrid_tone_profile');
    await prefs.remove('tone_combo_history');
    await prefs.remove('dominant_blend');
    
    print('🔄 HYBRID learning data reset - all tone profiles cleared');
  }
  
  /// 🎭 Helper: Get display name for tone
  static String _getToneDisplayName(String toneKey) {
    final toneCategories = {
      'nerdy': 'Nerdy/Academic',
      'street': 'Street/Urban',
      'latin': 'Latin Colloquial',
      'southern': 'Southern Eccentric',
      'theatrical': 'Theatrical/Dramatic',
      'finance_bro': 'Finance Bro',
      'gamer': 'Gamer/Internet',
      'spiritual': 'Spiritual/Wellness',
      'gen_z': 'Gen Z Core',
      'military': 'Trained Soldier',
      'neutral': 'Neutral/Balanced'
    };
    
    return toneCategories[toneKey] ?? toneKey;
  }
}