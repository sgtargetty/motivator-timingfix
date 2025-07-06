// lib/services/authentic_tone_detection.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎭 Authentic Multi-Tone Detection System
/// Recognizes REAL communication styles, not sanitized corporate categories
class AuthenticToneDetection {
  
  // 🎯 AUTHENTIC TONE CATEGORIES
  static const Map<String, Map<String, dynamic>> _toneCategories = {
    
    // 🤓 Intellectual/Academic/Nerdy
    'nerdy': {
      'name': 'Nerdy/Academic',
      'weight': 0,
      'markers': [
        'actually', 'technically', 'specifically', 'precisely', 'furthermore',
        'algorithm', 'methodology', 'hypothesis', 'data suggests', 'correlation',
        'optimization', 'efficiency', 'implementation', 'framework', 'paradigm',
        'empirical', 'theoretical', 'substantial', 'comprehensive', 'systematic',
        'nerd', 'geek', 'intellectual', 'academic', 'research', 'study shows'
      ],
      'heavyMarkers': ['algorithmic', 'methodology', 'empirical evidence', 'peer reviewed'],
    },
    
    // 🗣️ Street/Urban/Ebonics
    'street': {
      'name': 'Street/Urban',
      'weight': 0,
      'markers': [
        'no cap', 'straight up', 'deadass', 'facts', 'real talk', 'periodt',
        'slaps', 'hits different', 'bussin', 'fire', 'lit', 'dope', 'sick',
        'finna', 'bout to', 'tryna', 'hella', 'mad', 'lowkey', 'highkey',
        'bruh', 'bro', 'fam', 'homie', 'sis', 'bestie', 'twin', 'gang',
        'cap', 'mid', 'trash', 'goated', 'legend', 'king', 'queen',
        'vibe', 'mood', 'energy', 'aura', 'main character', 'slay'
      ],
      'heavyMarkers': ['no cap', 'deadass', 'real talk', 'straight up', 'periodt'],
    },
    
    // 🌮 Latin/Hispanic Colloquial
    'latin': {
      'name': 'Latin Colloquial',
      'weight': 0,
      'markers': [
        'órale', 'ándale', 'buena onda', 'chévere', 'bacano', 'chido',
        'paisa', 'mijo', 'mija', 'hermano', 'hermana', 'primo', 'prima',
        'qué tal', 'cómo estás', 'todo bien', 'está bueno', 'está malo',
        'ay dios mío', 'por favor', 'gracias', 'de nada', 'claro que sí',
        'pinche', 'güey', 'wey', 'cabrón', 'chingón', 'padre', 'madre',
        'ese', 'esa', 'vato', 'vata', 'carnale', 'raza', 'la neta',
        // 🔥 ADD MISSING COMMON TERMS
        'puñeta', 'coño', 'joder', 'hombre', 'amigo', 'hermano', 'bro',
        'dale', 'wepa', 'ay bendito', 'que lo que', 'klk', 'tigre',
        'pana', 'loco', 'manito', 'compadre', 'mi amor', 'papito',
        'mamita', 'negrito', 'negrita', 'flaco', 'flaca', 'gordo',
        'mi vida', 'corazón', 'bebé', 'nene', 'nena', 'chulo', 'chula'
      ],
      'heavyMarkers': ['órale', 'ándale', 'chévere', 'qué tal', 'la neta', 'puñeta', 'coño'],
    },
    
    // 🤠 Southern/Country/Eccentric
    'southern': {
      'name': 'Southern Eccentric',
      'weight': 0,
      'markers': [
        'y\'all', 'ain\'t', 'fixin\' to', 'finna', 'reckon', 'might could',
        'bless your heart', 'well i\'ll be', 'i do declare', 'law mercy',
        'sugar', 'honey', 'darlin\'', 'sweetheart', 'sugar pie', 'buttercup',
        'madder than a wet hen', 'happy as a clam', 'busier than a bee',
        'cuter than a bug\'s ear', 'finer than frog\'s hair', 'uglier than sin',
        'hotter than blazes', 'colder than a witch\'s', 'dumber than dirt'
      ],
      'heavyMarkers': ['y\'all', 'bless your heart', 'i do declare', 'fixin\' to'],
    },
    
    // 🎭 Theatre/Drama/Expressive
    'theatrical': {
      'name': 'Theatrical/Dramatic',
      'weight': 0,
      'markers': [
        'darling', 'honey', 'sweetie', 'gorgeous', 'fabulous', 'divine',
        'absolutely', 'completely', 'utterly', 'totally', 'entirely',
        'dramatic', 'iconic', 'legendary', 'stunning', 'breathtaking',
        'chef\'s kiss', 'perfection', 'flawless', 'immaculate', 'exquisite',
        'serving', 'snapped', 'killed it', 'slayed', 'ate and left no crumbs'
      ],
      'heavyMarkers': ['darling', 'chef\'s kiss', 'absolutely divine', 'utterly fabulous'],
    },
    
    // 💰 Finance/Crypto/Business Bro
    'finance_bro': {
      'name': 'Finance Bro',
      'weight': 0,
      'markers': [
        'alpha', 'beta', 'sigma', 'grindset', 'hustle', 'bag', 'secured',
        'moon', 'diamond hands', 'paper hands', 'hodl', 'fud', 'pump',
        'bullish', 'bearish', 'ape', 'defi', 'nft', 'blockchain', 'crypto',
        'stonks', 'tendies', 'yolo', 'fomo', 'gains', 'losses', 'portfolio',
        'diversified', 'leveraged', 'margin', 'options', 'calls', 'puts'
      ],
      'heavyMarkers': ['diamond hands', 'to the moon', 'alpha grindset', 'sigma mindset'],
    },
    
    // 🎮 Gamer/Internet Culture
    'gamer': {
      'name': 'Gamer/Internet',
      'weight': 0,
      'markers': [
        'poggers', 'pog', 'based', 'cringe', 'sus', 'sus af', 'among us',
        'big brain', 'smooth brain', 'galaxy brain', '5head', 'pepega',
        'kappa', 'copium', 'hopium', 'ratio', 'l + ratio', 'touch grass',
        'git gud', 'skill issue', 'diff', 'gapped', 'clapped', 'rekt',
        'noob', 'tryhard', 'sweat', 'casual', 'hardcore', 'speedrun'
      ],
      'heavyMarkers': ['poggers', 'based', 'big brain', 'skill issue'],
    },
    
    // 🧘 Spiritual/Wellness/Mindful
    'spiritual': {
      'name': 'Spiritual/Wellness',
      'weight': 0,
      'markers': [
        'universe', 'manifestation', 'energy', 'vibration', 'chakras',
        'mindfulness', 'meditation', 'gratitude', 'blessed', 'divine',
        'alignment', 'intention', 'purpose', 'journey', 'growth',
        'healing', 'self-care', 'wellness', 'holistic', 'organic',
        'namaste', 'peace', 'love', 'light', 'abundance', 'flow state'
      ],
      'heavyMarkers': ['manifestation', 'chakras', 'divine alignment', 'universe'],
    },
    
    // 🔥 Gen Z Core (distinct from street)
    'gen_z': {
      'name': 'Gen Z Core',
      'weight': 0,
      'markers': [
        'bestie', 'bestfriend', 'girlie', 'purr', 'slay queen', 'icon',
        'it\'s giving', 'main character', 'side character', 'npc', 'villain era',
        'toxic', 'red flag', 'green flag', 'ick', 'the ick', 'valid',
        'stan', 'simp', 'caught in 4k', 'no thoughts head empty', 'brain rot',
        'cheugy', 'sending me', 'i\'m deceased', 'not me', 'the way'
      ],
      'heavyMarkers': ['it\'s giving', 'main character', 'caught in 4k', 'sending me'],
    },

    // 🎖️ Military/Trained Soldier
    'military': {
      'name': 'Trained Soldier',
      'weight': 0,
      'markers': [
        'roger', 'copy', 'affirmative', 'negative', 'wilco', 'over', 'out',
        'mission', 'objective', 'orders', 'sir', 'ma\'am', 'command',
        'deploy', 'deployment', 'unit', 'squad', 'platoon', 'company', 'battalion',
        'sitrep', 'status', 'report', 'briefing', 'debrief', 'intel', 'recon',
        'sector', 'perimeter', 'secure', 'clear', 'all clear', 'stand by',
        'standby', 'move out', 'fall back', 'retreat', 'advance', 'flanking',
        'contact', 'enemy contact', 'target', 'engagement', 'hostile', 'friendly',
        'coordinates', 'grid', 'bearing', 'azimuth', 'klick', 'clicks', 'meter',
        'uniform', 'gear', 'equipment', 'weapon', 'ammo', 'ammunition',
        'chow', 'mess hall', 'barracks', 'quarters', 'formation', 'attention',
        'at ease', 'dismissed', 'fall in', 'sound off', 'cadence',
        'battle buddy', 'wingman', 'cover', 'overwatch', 'guardian angel',
        'honor', 'duty', 'service', 'sacrifice', 'brotherhood', 'sisterhood',
        'veteran', 'active duty', 'reserves', 'guard', 'discharge', 'retirement'
        // 🔧 REMOVED 'eta' and 'asap' - too common in civilian use
      ],
      'heavyMarkers': [
        'semper fi', 'semper fidelis', 'oorah', 'hooyah', 'hooah', 'booyah',
        'devil dog', 'jarhead', 'marine', 'sailor', 'soldier', 'airman',
        'yes sir', 'no sir', 'yes ma\'am', 'no ma\'am', 'aye aye',
        'roger that', 'copy that', 'understood sir', 'understood ma\'am',
        'mission accomplished', 'mission complete', 'objectives met',
        'good to go', 'ready to rock', 'locked and loaded',
        'stay frosty', 'stay sharp', 'stay alert', 'heads up',
        'military time', '0800', '1400', '2100', 'hundred hours',
        'unknown hours', 'zulu time', 'mike', 'alpha', 'bravo', 'charlie'
      ],
    }
  };
  
  /// 🎯 Analyze text and return tone scores for ALL categories
  static Map<String, double> analyzeTones(String text) {
    final lowerText = text.toLowerCase();
    Map<String, double> scores = {};
    
    _toneCategories.forEach((toneKey, toneData) {
      double score = 0;
      
      // Check regular markers
      for (String marker in toneData['markers'] as List<String>) {
        if (lowerText.contains(marker.toLowerCase())) {
          score += 1;
        }
      }
      
      // Check heavy markers (worth more points)
      for (String heavyMarker in toneData['heavyMarkers'] as List<String>) {
        if (lowerText.contains(heavyMarker.toLowerCase())) {
          score += 3;
        }
      }
      
      scores[toneKey] = score;
    });
    
    return scores;
  }
  
  /// 🎭 Determine primary and secondary tones
  static Map<String, dynamic> determinePrimaryTones(Map<String, double> scores) {
    // Sort by score descending
    var sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    String primaryTone = 'neutral';
    String? secondaryTone;
    double primaryScore = 0;
    double secondaryScore = 0;
    
    if (sortedEntries.isNotEmpty && sortedEntries.first.value > 0) {
      primaryTone = sortedEntries.first.key;
      primaryScore = sortedEntries.first.value;
      
      if (sortedEntries.length > 1 && sortedEntries[1].value > 0) {
        secondaryTone = sortedEntries[1].key;
        secondaryScore = sortedEntries[1].value;
      }
    }
    
    return {
      'primary': primaryTone,
      'secondary': secondaryTone,
      'primaryScore': primaryScore,
      'secondaryScore': secondaryScore,
      'allScores': scores,
      'confidence': primaryScore >= 2 ? 'high' : primaryScore >= 1 ? 'medium' : 'low'
    };
  }
  
  /// 🎯 Generate tone-specific response modifiers
  static List<String> generateToneModifiers(String primaryTone, String? secondaryTone) {
    List<String> modifiers = [];
    
    switch (primaryTone) {
      case 'nerdy':
        modifiers.add('Use intellectual, precise language with technical accuracy.');
        modifiers.add('Include thoughtful analysis and detailed explanations.');
        break;
      case 'street':
        modifiers.add('Keep it real and authentic - use urban vernacular naturally.');
        modifiers.add('Be direct, honest, and use expressions like "no cap", "real talk".');
        break;
      case 'latin':
        modifiers.add('Include warm, familial expressions and cultural colloquialisms.');
        modifiers.add('Use phrases that reflect Latin cultural communication styles.');
        break;
      case 'southern':
        modifiers.add('Use charming Southern expressions and colorful metaphors.');
        modifiers.add('Be warm, hospitable, and use endearing terms naturally.');
        break;
      case 'theatrical':
        modifiers.add('Be expressive, dramatic, and emotionally rich in language.');
        modifiers.add('Use superlatives and theatrical flair naturally.');
        break;
      case 'finance_bro':
        modifiers.add('Use business/finance terminology and success-oriented language.');
        modifiers.add('Focus on growth, optimization, and achievement.');
        break;
      case 'gamer':
        modifiers.add('Use gaming and internet culture references appropriately.');
        modifiers.add('Be casual but knowledgeable about digital culture.');
        break;
      case 'spiritual':
        modifiers.add('Use mindful, growth-oriented language with positive energy.');
        modifiers.add('Focus on wellness, intention, and personal development.');
        break;
      case 'gen_z':
        modifiers.add('Use authentic Gen Z expressions and current slang naturally.');
        modifiers.add('Be supportive and use generational humor appropriately.');
        break;
      case 'military':
        modifiers.add('Use clear, direct, mission-focused language with military precision.');
        modifiers.add('Incorporate structured communication and appropriate military terminology.');
        modifiers.add('Be respectful, disciplined, and goal-oriented in responses.');
        break;
      default:
        modifiers.add('Use a balanced, natural tone that matches the user\'s energy.');
    }
    
    if (secondaryTone != null && secondaryTone != primaryTone) {
      modifiers.add('Blend in elements of ${_toneCategories[secondaryTone]?['name']} communication style.');
    }
    
    return modifiers;
  }
  
  /// 📊 Get readable tone analysis
  static String getToneAnalysisString(Map<String, dynamic> analysis) {
    String result = 'Primary: ${_toneCategories[analysis['primary']]?['name'] ?? analysis['primary']}';
    
    if (analysis['secondary'] != null) {
      result += ', Secondary: ${_toneCategories[analysis['secondary']]?['name']}';
    }
    
    result += ' (Confidence: ${analysis['confidence']})';
    return result;
  }
}