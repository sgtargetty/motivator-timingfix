// lib/services/hybrid_tone_detection.dart - FIXED VERSION
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'authentic_tone_detection.dart';
import 'dynamic_combination_generator.dart';

/// 🎭 Multi-Tone Hybrid Detection & Blending System
/// Now with DYNAMIC generation of ALL possible combinations!
class HybridToneDetection {
  
  static const String _hybridProfileKey = 'hybrid_tone_profile';
  static const String _toneComboHistoryKey = 'tone_combo_history';
  static const String _dominantBlendKey = 'dominant_blend';
  
  /// 🎯 Analyze text for hybrid tone combinations - NOW FULLY DYNAMIC!
  static Map<String, dynamic> analyzeHybridTones(String text) {
    // Get individual tone scores
    final toneScores = AuthenticToneDetection.analyzeTones(text);
    
    // 🚀 USE DYNAMIC COMBINATION GENERATOR
    final allPossibleCombos = DynamicCombinationGenerator.generateAllCombinations(toneScores);
    
    if (allPossibleCombos.isEmpty) {
      // No significant tones detected - fallback to single tone analysis
      final analysis = AuthenticToneDetection.determinePrimaryTones(toneScores);
      
      // Special case: bias toward professional for formal language
      if (analysis['primary'] == 'neutral' && toneScores['professional'] != null && toneScores['professional']! > 0) {
        return {
          'type': 'single',
          'primary': 'professional',
          'secondary': analysis['secondary'],
          'hybrid': null,
          'blendConfidence': 0.0,
          'allScores': toneScores,
        };
      }
      
      return {
        'type': 'single',
        'primary': analysis['primary'],
        'secondary': analysis['secondary'],
        'hybrid': null,
        'blendConfidence': 0.0,
        'allScores': toneScores,
      };
    }
    
    // Get the best combination (highest score)
    final bestCombo = allPossibleCombos.first;
    final tones = bestCombo['tones'] as List<String>;
    
    if (tones.length == 1) {
      // Single tone detected
      return {
        'type': 'single',
        'primary': tones[0],
        'secondary': allPossibleCombos.length > 1 ? (allPossibleCombos[1]['tones'] as List<String>)[0] : null,
        'hybrid': null,
        'blendConfidence': 0.0,
        'allScores': toneScores,
      };
    }
    
    // Multi-tone hybrid detected!
    return {
      'type': 'hybrid',
      'primary': tones[0],
      'secondary': tones.length > 1 ? tones[1] : null,
      'tertiary': tones.length > 2 ? tones[2] : null,
      'hybrid': {
        'key': bestCombo['key'],
        'name': bestCombo['name'],
        'description': bestCombo['description'],
        'blendStyle': bestCombo['blendStyle'],
        'emojis': bestCombo['emojis'],
        'commonality': _calculateCommonality(tones),
        'matchType': 'dynamic',
        'allTones': tones,
      },
      'blendConfidence': bestCombo['confidence'],
      'allScores': toneScores,
      'significantTones': tones.map((tone) => {
        'tone': tone,
        'score': toneScores[tone] ?? 0.0,
      }).toList(),
      'allPossibleCombos': allPossibleCombos.take(5).toList(), // Top 5 for debugging
    };
  }
  
  /// 🎭 Generate blended response modifiers - NOW FULLY DYNAMIC!
  static List<String> generateHybridModifiers(Map<String, dynamic> hybridAnalysis) {
    if (hybridAnalysis['type'] == 'single') {
      // Fall back to single tone modifiers
      return AuthenticToneDetection.generateToneModifiers(
        hybridAnalysis['primary'],
        hybridAnalysis['secondary'],
      );
    }
    
    final hybrid = hybridAnalysis['hybrid'];
    if (hybrid == null) return [];
    
    // 🚀 USE DYNAMIC MODIFIER GENERATION
    final allTones = hybrid['allTones'] as List<String>;
    return DynamicCombinationGenerator.generateDynamicModifiers(allTones);
  }
  
  /// 📚 Store hybrid analysis in user's learning profile
  static Future<void> storeHybridAnalysis(Map<String, dynamic> hybridAnalysis, int conversationCount) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing combo history
    final comboHistoryJson = prefs.getString(_toneComboHistoryKey) ?? '[]';
    final List<dynamic> comboHistory = jsonDecode(comboHistoryJson);
    
    // Add new hybrid data
    comboHistory.add({
      'conversation': conversationCount,
      'type': hybridAnalysis['type'],
      'primary': hybridAnalysis['primary'],
      'secondary': hybridAnalysis['secondary'],
      'tertiary': hybridAnalysis['tertiary'],
      'hybrid': hybridAnalysis['hybrid'],
      'confidence': hybridAnalysis['blendConfidence'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Keep only last 30 hybrid analyses
    if (comboHistory.length > 30) {
      comboHistory.removeAt(0);
    }
    
    await prefs.setString(_toneComboHistoryKey, jsonEncode(comboHistory));
    
    // Update dominant blend if we have enough data
    if (conversationCount >= 5) {
      await _updateDominantBlend(comboHistory);
    }
  }
  
  /// 🎯 Determine user's dominant hybrid pattern
  static Future<void> _updateDominantBlend(List<dynamic> comboHistory) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Count hybrid patterns
    Map<String, int> blendCounts = {};
    Map<String, double> blendConfidences = {};
    
    for (var combo in comboHistory) {
      if (combo['hybrid'] != null) {
        final blendKey = combo['hybrid']['key'] ?? 'unknown';
        blendCounts[blendKey] = (blendCounts[blendKey] ?? 0) + 1;
        blendConfidences[blendKey] = (blendConfidences[blendKey] ?? 0.0) + (combo['confidence'] ?? 0.0);
      }
    }
    
    // Find dominant blend
    String? dominantBlend;
    double highestWeightedScore = 0;
    
    blendCounts.forEach((blendKey, count) {
      final avgConfidence = blendConfidences[blendKey]! / count;
      final frequency = count / comboHistory.length;
      final weightedScore = avgConfidence * frequency * count;
      
      if (weightedScore > highestWeightedScore) {
        highestWeightedScore = weightedScore;
        dominantBlend = blendKey;
      }
    });
    
    if (dominantBlend != null) {
      final dominantData = {
        'blendKey': dominantBlend,
        'frequency': blendCounts[dominantBlend]! / comboHistory.length,
        'avgConfidence': blendConfidences[dominantBlend]! / blendCounts[dominantBlend]!,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_dominantBlendKey, jsonEncode(dominantData));
      
      print('🎭 DOMINANT BLEND UPDATED: $dominantBlend');
      print('📊 Frequency: ${((dominantData['frequency'] as double) * 100).toStringAsFixed(1)}%');
      print('🎯 Confidence: ${(dominantData['avgConfidence'] as double).toStringAsFixed(2)}');
    }
  }
  
  /// 📊 Get user's hybrid profile summary
  static Future<Map<String, dynamic>> getHybridProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    final comboHistoryJson = prefs.getString(_toneComboHistoryKey) ?? '[]';
    final List<dynamic> comboHistory = jsonDecode(comboHistoryJson);
    
    final dominantBlendJson = prefs.getString(_dominantBlendKey);
    Map<String, dynamic>? dominantBlend;
    if (dominantBlendJson != null) {
      dominantBlend = jsonDecode(dominantBlendJson);
    }
    
    // Calculate blend frequencies
    Map<String, int> blendFrequencies = {};
    for (var combo in comboHistory) {
      if (combo['hybrid'] != null) {
        final blendKey = combo['hybrid']['key'] ?? 'unknown';
        blendFrequencies[blendKey] = (blendFrequencies[blendKey] ?? 0) + 1;
      }
    }
    
    return {
      'totalCombos': comboHistory.length,
      'dominantBlend': dominantBlend,
      'blendFrequencies': blendFrequencies,
      'recentCombos': comboHistory.take(5).toList(),
      'hasHybridData': comboHistory.length >= 3,
    };
  }
  
  /// 📊 Calculate commonality for any combination
  static int _calculateCommonality(List<String> tones) {
    // Base commonality on combination size (fewer tones = more common)
    int baseCommonality = max(1, 10 - tones.length);
    
    // Adjust for specific high-frequency combinations
    if (tones.length == 2) {
      final sorted = List<String>.from(tones)..sort();
      final key = sorted.join('_');
      
      const highFrequencyCombos = {
        'military_street': 9,
        'street_gen_z': 10,
        'nerdy_professional': 8,
        'military_professional': 9,
        'street_latin': 8,
        'military_nerdy': 7,
        'gen_z_gamer': 8,
      };
      
      if (highFrequencyCombos.containsKey(key)) {
        return highFrequencyCombos[key]!;
      }
    }
    
    return baseCommonality;
  }
  
  /// 🎯 Get readable hybrid analysis string - DYNAMIC VERSION
  static String getHybridAnalysisString(Map<String, dynamic> analysis) {
    if (analysis['type'] == 'single') {
      return 'Single tone: ${analysis['primary']}';
    }
    
    final hybrid = analysis['hybrid'];
    if (hybrid == null) {
      return 'Multi-tone detected but no clear blend';
    }
    
    final confidence = ((analysis['blendConfidence'] ?? 0.0) * 100).round();
    final name = hybrid['name'] ?? 'Unknown Blend';
    
    return '$name (${confidence}% confidence)';
  }
}