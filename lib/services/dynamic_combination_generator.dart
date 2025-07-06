// lib/services/dynamic_combination_generator.dart
import 'dart:math';

/// 🎭 Dynamic Combination Generator
/// Generates ALL possible tone combinations on-the-fly
class DynamicCombinationGenerator {
  
  static const List<String> _allTones = [
    'military', 'street', 'nerdy', 'latin', 'southern', 
    'gen_z', 'gamer', 'theatrical', 'finance_bro', 
    'spiritual', 'professional'
  ];
  
  static const Map<String, Map<String, String>> _toneData = {
    'military': {'name': 'Trained Soldier', 'short': 'Tactical', 'emoji': '🎖️'},
    'street': {'name': 'Street/Urban', 'short': 'Street', 'emoji': '🗣️'},
    'nerdy': {'name': 'Nerdy/Academic', 'short': 'Scholar', 'emoji': '🤓'},
    'latin': {'name': 'Latin Colloquial', 'short': 'Latino', 'emoji': '🌮'},
    'southern': {'name': 'Southern Eccentric', 'short': 'Country', 'emoji': '🤠'},
    'gen_z': {'name': 'Gen Z Core', 'short': 'Gen Z', 'emoji': '🔥'},
    'gamer': {'name': 'Gamer/Internet', 'short': 'Digital', 'emoji': '🎮'},
    'theatrical': {'name': 'Theatrical/Dramatic', 'short': 'Dramatic', 'emoji': '🎭'},
    'finance_bro': {'name': 'Finance Bro', 'short': 'Hustle', 'emoji': '💰'},
    'spiritual': {'name': 'Spiritual/Wellness', 'short': 'Mindful', 'emoji': '🧘'},
    'professional': {'name': 'Professional/Formal', 'short': 'Professional', 'emoji': '👔'},
  };
  
  /// 🎯 Generate combination key from tone list
  static String generateComboKey(List<String> tones) {
    final sortedTones = List<String>.from(tones)..sort();
    return sortedTones.join('_');
  }
  
  /// 🎭 Generate human-readable name for any combination
  static String generateComboName(List<String> tones) {
    if (tones.length == 1) {
      return _toneData[tones[0]]?['name'] ?? tones[0];
    }
    
    // Special 2-tone combinations
    if (tones.length == 2) {
      final sorted = List<String>.from(tones)..sort();
      final specialNames = <String, String>{
        'military_street': 'Military Hood',
        'military_nerdy': 'Tactical Scholar',
        'military_latin': 'Latino Warrior',
        'military_southern': 'Country Soldier',
        'military_gen_z': 'Digital Soldier',
        'military_gamer': 'Tactical Gamer',
        'military_theatrical': 'Dramatic Commander',
        'military_finance_bro': 'Strategic Hustler',
        'military_spiritual': 'Warrior Monk',
        'military_professional': 'Military Professional',
        
        'street_nerdy': 'Smart Street',
        'street_latin': 'Urban Latino',
        'street_southern': 'Country Street',
        'street_gen_z': 'Urban Gen Z',
        'street_gamer': 'Street Gamer',
        'street_theatrical': 'Street Performer',
        'street_finance_bro': 'Hood Entrepreneur',
        'street_spiritual': 'Urban Mystic',
        'street_professional': 'Corporate Street',
        
        'nerdy_latin': 'Latino Scholar',
        'nerdy_southern': 'Country Professor',
        'nerdy_gen_z': 'Digital Native Scholar',
        'nerdy_gamer': 'Gaming Academic',
        'nerdy_theatrical': 'Dramatic Scholar',
        'nerdy_finance_bro': 'Analytical Hustler',
        'nerdy_spiritual': 'Enlightened Scholar',
        'nerdy_professional': 'Academic Professional',
        
        'latin_southern': 'Latino Country',
        'latin_gen_z': 'Latino Gen Z',
        'latin_gamer': 'Latino Gamer',
        'latin_theatrical': 'Latino Performer',
        'latin_finance_bro': 'Latino Entrepreneur',
        'latin_spiritual': 'Latino Mystic',
        'latin_professional': 'Latino Professional',
        
        'southern_gen_z': 'Country Gen Z',
        'southern_gamer': 'Country Gamer',
        'southern_theatrical': 'Country Performer',
        'southern_finance_bro': 'Country Hustler',
        'southern_spiritual': 'Country Mystic',
        'southern_professional': 'Country Professional',
        
        'gen_z_gamer': 'Digital Native',
        'gen_z_theatrical': 'Dramatic Gen Z',
        'gen_z_finance_bro': 'Young Hustler',
        'gen_z_spiritual': 'Mindful Gen Z',
        'gen_z_professional': 'Professional Gen Z',
        
        'gamer_theatrical': 'Dramatic Gamer',
        'gamer_finance_bro': 'Gaming Entrepreneur',
        'gamer_spiritual': 'Mindful Gamer',
        'gamer_professional': 'Professional Gamer',
        
        'theatrical_finance_bro': 'Dramatic Hustler',
        'theatrical_spiritual': 'Dramatic Mystic',
        'theatrical_professional': 'Dramatic Professional',
        
        'finance_bro_spiritual': 'Mindful Hustler',
        'finance_bro_professional': 'Professional Hustler',
        
        'spiritual_professional': 'Mindful Professional',
      };
      
      final key = sorted.join('_');
      if (specialNames.containsKey(key)) {
        return specialNames[key]!;
      }
    }
    
    // For 3+ combinations, use short names
    if (tones.length == 3) {
      final shortNames = tones.map((t) => _toneData[t]?['short'] ?? t).toList();
      return shortNames.join(' + ');
    }
    
    // For 4+ combinations, use compact naming
    return 'Multi-${tones.length} Blend';
  }
  
  /// 🎯 Generate all possible combinations from detected tones
  static List<Map<String, dynamic>> generateAllCombinations(Map<String, double> toneScores) {
    // Get significant tones (score >= 1)
    final significantTones = toneScores.entries
        .where((entry) => entry.value >= 1)
        .map((entry) => entry.key)
        .toList();
    
    if (significantTones.isEmpty) return [];
    
    List<Map<String, dynamic>> allCombinations = [];
    
    // Generate all possible combinations (1 to significantTones.length, max 4)
    for (int size = 1; size <= significantTones.length && size <= 4; size++) {
      final combinations = _generateCombinations(significantTones, size);
      
      for (final combo in combinations) {
        final comboScore = _calculateComboScore(combo, toneScores);
        final confidence = _calculateComboConfidence(combo, toneScores);
        
        allCombinations.add({
          'tones': combo,
          'key': generateComboKey(combo),
          'name': generateComboName(combo),
          'description': _generateComboDescription(combo),
          'score': comboScore,
          'confidence': confidence,
          'size': combo.length,
          'emojis': combo.map((t) => _toneData[t]?['emoji'] ?? '').join(''),
          'blendStyle': _generateBlendStyle(combo),
        });
      }
    }
    
    // Sort by score + confidence
    allCombinations.sort((a, b) {
      final scoreA = (a['score'] as double) * (a['confidence'] as double);
      final scoreB = (b['score'] as double) * (b['confidence'] as double);
      return scoreB.compareTo(scoreA);
    });
    
    return allCombinations;
  }
  
  /// 🔧 Generate all combinations of specific size
  static List<List<String>> _generateCombinations(List<String> items, int size) {
    if (size == 1) {
      return items.map((item) => [item]).toList();
    }
    
    List<List<String>> result = [];
    
    for (int i = 0; i < items.length; i++) {
      final remaining = items.sublist(i + 1);
      final smallerCombos = _generateCombinations(remaining, size - 1);
      
      for (final combo in smallerCombos) {
        result.add([items[i], ...combo]);
      }
    }
    
    return result;
  }
  
  /// 📊 Calculate combination score
  static double _calculateComboScore(List<String> combo, Map<String, double> toneScores) {
    double totalScore = 0;
    for (final tone in combo) {
      totalScore += toneScores[tone] ?? 0;
    }
    return totalScore;
  }
  
  /// 🎯 Calculate combination confidence
  static double _calculateComboConfidence(List<String> combo, Map<String, double> toneScores) {
    final comboScore = _calculateComboScore(combo, toneScores);
    final maxPossibleScore = combo.length * 5.0; // Assuming max score of 5 per tone
    
    // Adjust for combination size (smaller combos are more confident)
    final sizeMultiplier = 1.0 / sqrt(combo.length);
    
    return (comboScore / maxPossibleScore * sizeMultiplier).clamp(0.0, 1.0);
  }
  
  /// 📝 Generate combination description
  static String _generateComboDescription(List<String> combo) {
    if (combo.length == 1) {
      return '${_toneData[combo[0]]?['name'] ?? combo[0]} communication style';
    }
    
    final toneNames = combo.map((t) => _toneData[t]?['short'] ?? t).toList();
    
    if (combo.length == 2) {
      return 'Blend of ${toneNames[0]} and ${toneNames[1]} communication styles';
    } else if (combo.length == 3) {
      return 'Triple blend: ${toneNames.join(', ')} communication styles';
    } else {
      return 'Complex ${combo.length}-way blend of communication styles';
    }
  }
  
  /// 🎨 Generate blend style
  static String _generateBlendStyle(List<String> combo) {
    if (combo.length == 1) {
      return 'single_${combo[0]}';
    }
    
    final sorted = List<String>.from(combo)..sort();
    return sorted.join('_');
  }
  
  /// 🎯 Find best combination match
  static Map<String, dynamic>? findBestCombination(Map<String, double> toneScores) {
    final allCombos = generateAllCombinations(toneScores);
    
    if (allCombos.isEmpty) return null;
    
    // Return the highest scoring combination
    return allCombos.first;
  }
  
  /// 🎭 Generate modifiers for any combination
  static List<String> generateDynamicModifiers(List<String> tones) {
    List<String> modifiers = [];
    
    if (tones.length == 1) {
      // Single tone modifiers
      switch (tones[0]) {
        case 'military':
          modifiers.add('Use clear, direct, mission-focused language with military precision.');
          break;
        case 'street':
          modifiers.add('Keep it real and authentic - use urban vernacular naturally.');
          break;
        case 'nerdy':
          modifiers.add('Use intellectual, precise language with technical accuracy.');
          break;
        case 'latin':
          modifiers.add('Include warm, familial expressions and cultural colloquialisms.');
          break;
        case 'southern':
          modifiers.add('Use charming Southern expressions and colorful metaphors.');
          break;
        case 'gen_z':
          modifiers.add('Use authentic Gen Z expressions and current slang naturally.');
          break;
        case 'gamer':
          modifiers.add('Use gaming and internet culture references appropriately.');
          break;
        case 'theatrical':
          modifiers.add('Be expressive, dramatic, and emotionally rich in language.');
          break;
        case 'finance_bro':
          modifiers.add('Use business/finance terminology and success-oriented language.');
          break;
        case 'spiritual':
          modifiers.add('Use mindful, growth-oriented language with positive energy.');
          break;
        case 'professional':
          modifiers.add('Maintain professional, formal language with proper structure.');
          break;
      }
    } else {
      // Multi-tone modifiers
      final toneNames = tones.map((t) => _toneData[t]?['short'] ?? t).toList();
      modifiers.add('Naturally blend ${toneNames.join(', ')} communication styles.');
      modifiers.add('Adapt fluidly between these authentic expressions as context requires.');
      
      // Add specific guidance for common combinations
      if (tones.contains('military') && tones.contains('street')) {
        modifiers.add('Example blend: "Roger that, bro - mission understood, no cap."');
      }
      if (tones.contains('nerdy') && tones.contains('street')) {
        modifiers.add('Example blend: "Actually, that approach slaps different, real talk."');
      }
    }
    
    return modifiers;
  }
}