// lib/services/hybrid_tone_detection.dart
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'authentic_tone_detection.dart';

/// 🎭 Multi-Tone Hybrid Detection & Blending System
/// Recognizes and blends authentic communication combinations like "Military + Street + Nerdy"
class HybridToneDetection {
  
  static const String _hybridProfileKey = 'hybrid_tone_profile';
  static const String _toneComboHistoryKey = 'tone_combo_history';
  static const String _dominantBlendKey = 'dominant_blend';
  
  // 🎯 Common authentic combinations found in real people
  static const Map<String, Map<String, dynamic>> _authenticCombos = {
    'military_street': {
      'name': 'Military Hood',
      'description': 'Disciplined soldier with street authenticity',
      'tones': ['military', 'street'],
      'commonality': 8, // How common this combo is (1-10)
      'blendStyle': 'structured_casual',
    },
    'nerdy_street': {
      'name': 'Smart Street',
      'description': 'Intellectual with urban vernacular',
      'tones': ['nerdy', 'street'],
      'commonality': 7,
      'blendStyle': 'academic_urban',
    },
    'military_nerdy': {
      'name': 'Tactical Scholar',
      'description': 'Strategic military mind with academic precision',
      'tones': ['military', 'nerdy'],
      'commonality': 6,
      'blendStyle': 'precise_analytical',
    },
    'military_southern': {
      'name': 'Country Soldier',
      'description': 'Southern hospitality with military discipline',
      'tones': ['military', 'southern'],
      'commonality': 7,
      'blendStyle': 'respectful_folksy',
    },
    'street_gen_z': {
      'name': 'Urban Gen Z',
      'description': 'Street smart with generational slang',
      'tones': ['street', 'gen_z'],
      'commonality': 9,
      'blendStyle': 'authentic_young',
    },
    'military_gamer': {
      'name': 'Tactical Gamer',
      'description': 'Military strategy meets gaming culture',
      'tones': ['military', 'gamer'],
      'commonality': 6,
      'blendStyle': 'strategic_digital',
    },
    'nerdy_theatrical': {
      'name': 'Dramatic Scholar',
      'description': 'Academic knowledge with expressive flair',
      'tones': ['nerdy', 'theatrical'],
      'commonality': 4,
      'blendStyle': 'expressive_intellectual',
    },
    'street_finance_bro': {
      'name': 'Hood Entrepreneur',
      'description': 'Street wisdom with business ambition',
      'tones': ['street', 'finance_bro'],
      'commonality': 6,
      'blendStyle': 'hustle_authentic',
    },
    'military_street_nerdy': {
      'name': 'Scholar Warrior Hood',
      'description': 'Triple threat: Military precision + Street authenticity + Academic insight',
      'tones': ['military', 'street', 'nerdy'],
      'commonality': 5,
      'blendStyle': 'tactical_smart_real',
    },
  };
  
  /// 🎯 Analyze text for hybrid tone combinations
  static Map<String, dynamic> analyzeHybridTones(String text) {
    // Get individual tone scores
    final toneScores = AuthenticToneDetection.analyzeTones(text);
    
    // Find tones with significant scores (threshold: 1+)
    final significantTones = toneScores.entries
        .where((entry) => entry.value >= 1)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    if (significantTones.length < 2) {
      // Single tone - use existing logic
      final analysis = AuthenticToneDetection.determinePrimaryTones(toneScores);
      return {
        'type': 'single',
        'primary': analysis['primary'],
        'secondary': analysis['secondary'],
        'hybrid': null,
        'blendConfidence': 0.0,
        'allScores': toneScores,
      };
    }
    
    // Multi-tone detected - analyze for authentic combinations
    final detectedCombo = _findBestComboMatch(significantTones);
    
    return {
      'type': 'hybrid',
      'primary': significantTones.first.key,
      'secondary': significantTones.length > 1 ? significantTones[1].key : null,
      'tertiary': significantTones.length > 2 ? significantTones[2].key : null,
      'hybrid': detectedCombo,
      'blendConfidence': _calculateBlendConfidence(significantTones, detectedCombo),
      'allScores': toneScores,
      'significantTones': significantTones.map((e) => {
        'tone': e.key,
        'score': e.value,
      }).toList(),
    };
  }
  
  /// 🔍 Find the best matching authentic combination
  static Map<String, dynamic>? _findBestComboMatch(List<MapEntry<String, double>> significantTones) {
    final detectedToneKeys = significantTones.map((e) => e.key).toSet();
    
    // Look for exact matches first
    for (String comboKey in _authenticCombos.keys) {
      final combo = _authenticCombos[comboKey]!;
      final comboTones = (combo['tones'] as List<String>).toSet();
      
      if (detectedToneKeys.containsAll(comboTones)) {
        return {
          'key': comboKey,
          'name': combo['name'],
          'description': combo['description'],
          'blendStyle': combo['blendStyle'],
          'commonality': combo['commonality'],
          'matchType': 'exact',
        };
      }
    }
    
    // Look for partial matches (2 out of 3 tones)
    for (String comboKey in _authenticCombos.keys) {
      final combo = _authenticCombos[comboKey]!;
      final comboTones = (combo['tones'] as List<String>).toSet();
      final intersection = detectedToneKeys.intersection(comboTones);
      
      if (intersection.length >= 2 && intersection.length >= comboTones.length * 0.6) {
        return {
          'key': comboKey,
          'name': combo['name'],
          'description': combo['description'],
          'blendStyle': combo['blendStyle'],
          'commonality': combo['commonality'],
          'matchType': 'partial',
        };
      }
    }
    
    // No predefined combo found - create custom hybrid
    if (significantTones.length >= 2) {
      return _createCustomHybrid(significantTones);
    }
    
    return null;
  }
  
  /// 🎨 Create custom hybrid for unique combinations
  static Map<String, dynamic> _createCustomHybrid(List<MapEntry<String, double>> significantTones) {
    final topTones = significantTones.take(3).map((e) => e.key).toList();
    final name = topTones.map((tone) => _getShortToneName(tone)).join(' + ');
    
    return {
      'key': 'custom_${topTones.join('_')}',
      'name': name,
      'description': 'Unique blend of ${topTones.join(', ')} communication styles',
      'blendStyle': 'adaptive_custom',
      'commonality': 3, // Custom combos are less common
      'matchType': 'custom',
      'customTones': topTones,
    };
  }
  
  /// 📊 Calculate confidence in the blend detection
  static double _calculateBlendConfidence(List<MapEntry<String, double>> significantTones, Map<String, dynamic>? combo) {
    if (combo == null) return 0.0;
    
    // Base confidence on score distribution and commonality
    final totalScore = significantTones.fold(0.0, (sum, tone) => sum + tone.value);
    final topTwoScore = significantTones.take(2).fold(0.0, (sum, tone) => sum + tone.value);
    
    final distribution = topTwoScore / totalScore; // How much of the score is in top 2
    final commonality = (combo['commonality'] ?? 5) / 10.0; // How common this combo is
    
    return (distribution * 0.6 + commonality * 0.4).clamp(0.0, 1.0);
  }
  
  /// 🎭 Generate blended response modifiers
  static List<String> generateHybridModifiers(Map<String, dynamic> hybridAnalysis) {
    List<String> modifiers = [];
    
    if (hybridAnalysis['type'] == 'single') {
      // Fall back to single tone modifiers
      return AuthenticToneDetection.generateToneModifiers(
        hybridAnalysis['primary'],
        hybridAnalysis['secondary'],
      );
    }
    
    final hybrid = hybridAnalysis['hybrid'];
    if (hybrid == null) return modifiers;
    
    final blendStyle = hybrid['blendStyle'];
    final primary = hybridAnalysis['primary'];
    final secondary = hybridAnalysis['secondary'];
    final tertiary = hybridAnalysis['tertiary'];
    
    // Generate blend-specific modifiers
    switch (blendStyle) {
      case 'structured_casual':
        modifiers.add('Blend military precision with street authenticity - be direct and real while maintaining structure.');
        modifiers.add('Use terms like "Roger that, bro" or "Mission understood, no cap" naturally.');
        break;
        
      case 'academic_urban':
        modifiers.add('Combine intellectual depth with urban vernacular - smart and street-wise.');
        modifiers.add('Explain complex concepts using authentic street language when appropriate.');
        break;
        
      case 'precise_analytical':
        modifiers.add('Use military precision enhanced with academic thoroughness.');
        modifiers.add('Be strategically minded and analytically detailed in responses.');
        break;
        
      case 'respectful_folksy':
        modifiers.add('Blend military respect with Southern charm and hospitality.');
        modifiers.add('Use "Yes sir" alongside folksy expressions naturally.');
        break;
        
      case 'authentic_young':
        modifiers.add('Combine street authenticity with current Gen Z expressions.');
        modifiers.add('Be real and generationally aware without forcing slang.');
        break;
        
      case 'strategic_digital':
        modifiers.add('Blend tactical military thinking with gaming/digital culture.');
        modifiers.add('Use strategic language that resonates with both military and gaming mindsets.');
        break;
        
      case 'tactical_smart_real':
        modifiers.add('Triple blend: Military precision + Academic insight + Street authenticity.');
        modifiers.add('Be strategically intelligent while keeping it 100% real.');
        modifiers.add('Example tone: "Roger that - the analytical data suggests this approach is fire, no cap."');
        break;
        
      case 'adaptive_custom':
        modifiers.add('Adapt naturally between ${primary}, ${secondary}${tertiary != null ? ', and $tertiary' : ''} communication styles.');
        modifiers.add('Blend these styles organically based on context and user energy.');
        break;
        
      default:
        modifiers.add('Naturally blend ${primary} and ${secondary} communication styles.');
    }
    
    // Add confidence-based modifier
    final confidence = hybridAnalysis['blendConfidence'] ?? 0.0;
    if (confidence > 0.7) {
      modifiers.add('High confidence in this blend - lean into it authentically.');
    } else if (confidence > 0.4) {
      modifiers.add('Moderate blend confidence - adapt naturally between styles.');
    } else {
      modifiers.add('Emerging blend - let the combination develop naturally.');
    }
    
    return modifiers;
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
      print('📊 Frequency: ${(dominantData['frequency'] * 100).toStringAsFixed(1)}%');
      print('🎯 Confidence: ${dominantData['avgConfidence'].toStringAsFixed(2)}');
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
  
  /// 🏷️ Helper: Get short tone name for combos
  static String _getShortToneName(String toneKey) {
    final shortNames = {
      'military': 'Tactical',
      'street': 'Street',
      'nerdy': 'Scholar',
      'southern': 'Country',
      'theatrical': 'Dramatic',
      'finance_bro': 'Hustle',
      'gamer': 'Digital',
      'spiritual': 'Mindful',
      'gen_z': 'Gen Z',
      'latin': 'Latino',
      'neutral': 'Balanced',
    };
    return shortNames[toneKey] ?? toneKey;
  }
  
  /// 🎯 Get readable hybrid analysis string
  static String getHybridAnalysisString(Map<String, dynamic> analysis) {
    if (analysis['type'] == 'single') {
      return 'Single tone: ${analysis['primary']}';
    }
    
    final hybrid = analysis['hybrid'];
    if (hybrid == null) {
      return 'Multi-tone detected but no clear blend';
    }
    
    final confidence = ((analysis['blendConfidence'] ?? 0.0) * 100).round();
    return '${hybrid['name']} (${confidence}% confidence)';
  }
}