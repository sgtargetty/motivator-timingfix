// 🎭 ECCENTRIC VOICE PERSONALITY SYSTEM
// Provides motivational theater troupe with 18+ unique personalities

class EccentricVoiceSystem {
  static final Map<String, Map<String, dynamic>> _voices = {
    // 💪 ALPHA SQUAD (Male Personalities)
    'drill_sergeant': {
      'name': 'Drill Sergeant',
      'category': 'male',
      'description': 'Military-style motivation with commanding presence',
      'icon': '🎖️',
      'sample_phrase': 'LISTEN UP RECRUIT! That task isn\'t gonna complete itself! MOVE MOVE MOVE!',
      'voice_settings': {
        'stability': 0.8,
        'similarity_boost': 0.7,
        'style': 'aggressive',
      },
    },
    'wise_mentor': {
      'name': 'Wise Mentor',
      'category': 'male', 
      'description': 'Thoughtful guidance with ancient wisdom',
      'icon': '🧙‍♂️',
      'sample_phrase': 'Young apprentice, the path to success requires but one step forward.',
      'voice_settings': {
        'stability': 0.9,
        'similarity_boost': 0.8,
        'style': 'calm',
      },
    },
    'hype_beast': {
      'name': 'Hype Beast',
      'category': 'male',
      'description': 'Maximum energy motivational powerhouse',
      'icon': '⚡',
      'sample_phrase': 'YOOOOO! We\'re about to CRUSH this task! LET\'S GOOOOO!',
      'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.6,
        'style': 'energetic',
      },
    },
    'chill_surfer': {
      'name': 'Chill Surfer',
      'category': 'male',
      'description': 'Laid-back motivation with good vibes',
      'icon': '🏄‍♂️',
      'sample_phrase': 'Dude, riding the wave of productivity is totally gnarly. Catch this task!',
      'voice_settings': {
        'stability': 0.7,
        'similarity_boost': 0.5,
        'style': 'relaxed',
      },
    },
    'british_butler': {
      'name': 'British Butler',
      'category': 'male',
      'description': 'Proper etiquette with distinguished service',
      'icon': '🎩',
      'sample_phrase': 'I do believe it\'s time to attend to your task, most excellently.',
      'voice_settings': {
        'stability': 0.9,
        'similarity_boost': 0.9,
        'style': 'formal',
      },
    },
    'sports_coach': {
      'name': 'Sports Coach',
      'category': 'male',
      'description': 'Championship mindset with team spirit',
      'icon': '🏆',
      'sample_phrase': 'Alright champion! Game time! Let\'s bring home the victory!',
      'voice_settings': {
        'stability': 0.7,
        'similarity_boost': 0.7,
        'style': 'motivational',
      },
    },

    // 👑 QUEEN SQUAD (Female Personalities)
    'sassy_diva': {
      'name': 'Sassy Diva',
      'category': 'female',
      'description': 'Fierce confidence with glamorous attitude',
      'icon': '💋',
      'sample_phrase': 'Honey, procrastination is SO last season! Time to SPARKLE while you hustle!',
      'voice_settings': {
        'stability': 0.6,
        'similarity_boost': 0.8,
        'style': 'confident',
      },
    },
    'supportive_mom': {
      'name': 'Supportive Mom',
      'category': 'female',
      'description': 'Nurturing encouragement with loving wisdom',
      'icon': '🤱',
      'sample_phrase': 'Sweetie, I believe in you! You\'ve got this - one step at a time.',
      'voice_settings': {
        'stability': 0.8,
        'similarity_boost': 0.8,
        'style': 'nurturing',
      },
    },
    'queen_boss': {
      'name': 'Queen Boss',
      'category': 'female',
      'description': 'Executive power with royal authority',
      'icon': '👸',
      'sample_phrase': 'Your Majesty, the kingdom of productivity awaits your command!',
      'voice_settings': {
        'stability': 0.9,
        'similarity_boost': 0.8,
        'style': 'authoritative',
      },
    },
    'valley_girl': {
      'name': 'Valley Girl',
      'category': 'female',
      'description': 'Bubbly enthusiasm with infectious energy',
      'icon': '💅',
      'sample_phrase': 'OMG! This task is gonna be like, totally amazing! You\'re gonna rock it!',
      'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.6,
        'style': 'bubbly',
      },
    },
    'zen_goddess': {
      'name': 'Zen Goddess',
      'category': 'female',
      'description': 'Mindful motivation with spiritual grace',
      'icon': '🧘‍♀️',
      'sample_phrase': 'Breathe in possibility, breathe out procrastination. Your task awaits.',
      'voice_settings': {
        'stability': 0.9,
        'similarity_boost': 0.7,
        'style': 'meditative',
      },
    },
    'news_anchor': {
      'name': 'News Anchor',
      'category': 'female',
      'description': 'Professional delivery with authoritative presence',
      'icon': '📺',
      'sample_phrase': 'This just in: You\'re about to complete an important task. Stay tuned!',
      'voice_settings': {
        'stability': 0.8,
        'similarity_boost': 0.8,
        'style': 'professional',
      },
    },

    // 🎭 WILD CARDS (Character Personalities)
    'superhero': {
      'name': 'Superhero',
      'category': 'character',
      'description': 'Heroic inspiration with super powers',
      'icon': '🦸‍♂️',
      'sample_phrase': 'With great tasks come great responsibility! Your city needs you!',
      'voice_settings': {
        'stability': 0.7,
        'similarity_boost': 0.7,
        'style': 'heroic',
      },
    },
    'pirate_captain': {
      'name': 'Pirate Captain',
      'category': 'character',
      'description': 'Adventurous spirit with swashbuckling style',
      'icon': '🏴‍☠️',
      'sample_phrase': 'Ahoy matey! Time to plunder that task and claim yer treasure!',
      'voice_settings': {
        'stability': 0.6,
        'similarity_boost': 0.7,
        'style': 'adventurous',
      },
    },
    'robot_ai': {
      'name': 'Robot AI',
      'category': 'character',
      'description': 'Logical efficiency with robotic precision',
      'icon': '🤖',
      'sample_phrase': 'TASK.EXECUTION.REQUIRED. INITIATING.MOTIVATION.PROTOCOL. BEEP BOOP.',
      'voice_settings': {
        'stability': 0.9,
        'similarity_boost': 0.5,
        'style': 'robotic',
      },
    },
    'game_show_host': {
      'name': 'Game Show Host',
      'category': 'character',
      'description': 'Exciting presentation with prize energy',
      'icon': '🎪',
      'sample_phrase': 'Ladies and gentlemen, for ONE MILLION points... complete this task!',
      'voice_settings': {
        'stability': 0.6,
        'similarity_boost': 0.8,
        'style': 'enthusiastic',
      },
    },
    'shakespeare': {
      'name': 'Shakespeare',
      'category': 'character',
      'description': 'Dramatic flair with poetic motivation',
      'icon': '🎭',
      'sample_phrase': 'To task, or not to task? That is NOT the question! TO TASK!',
      'voice_settings': {
        'stability': 0.8,
        'similarity_boost': 0.9,
        'style': 'theatrical',
      },
    },
    'alien_visitor': {
      'name': 'Alien Visitor',
      'category': 'character',
      'description': 'Otherworldly wisdom with cosmic perspective',
      'icon': '👽',
      'sample_phrase': 'Greetings Earthling! The cosmic forces align for task completion!',
      'voice_settings': {
        'stability': 0.7,
        'similarity_boost': 0.6,
        'style': 'mysterious',
      },
    },
  };

  // 🎨 TONE STYLES - Dramatic intensity levels
  static final Map<String, Map<String, dynamic>> _toneStyles = {
    'gentle_nudge': {
      'name': 'Gentle Nudge',
      'description': 'Soft, encouraging whispers',
      'intensity': 1,
      'icon': '🌸',
      'modifiers': ['softly', 'gently', 'kindly'],
    },
    'cheerleader': {
      'name': 'Cheerleader',
      'description': 'Positive, enthusiastic support',
      'intensity': 3,
      'icon': '📣',
      'modifiers': ['enthusiastically', 'cheerfully', 'brightly'],
    },
    'coach': {
      'name': 'Coach',
      'description': 'Firm but supportive guidance',
      'intensity': 5,
      'icon': '🏅',
      'modifiers': ['firmly', 'confidently', 'supportively'],
    },
    'drill_sergeant': {
      'name': 'Drill Sergeant',
      'description': 'Commanding, no-nonsense approach',
      'intensity': 7,
      'icon': '⚔️',
      'modifiers': ['commandingly', 'forcefully', 'urgently'],
    },
    'hype_beast': {
      'name': 'Hype Beast',
      'description': 'Maximum energy and excitement',
      'intensity': 10,
      'icon': '🔥',
      'modifiers': ['explosively', 'intensely', 'with maximum energy'],
    },
  };

  // 🎯 PUBLIC API METHODS

  /// Get a specific voice by its key
  static Map<String, dynamic>? getVoiceByKey(String key) {
    return _voices[key];
  }

  /// Get all voices in a specific category
  static List<Map<String, dynamic>> getVoicesByCategory(String category) {
    return _voices.values
        .where((voice) => voice['category'] == category)
        .toList();
  }

  /// Get all voices organized by category
  static Map<String, List<Map<String, dynamic>>> getAllVoicesByCategory() {
    return {
      'male': getVoicesByCategory('male'),
      'female': getVoicesByCategory('female'),
      'character': getVoicesByCategory('character'),
    };
  }

  /// Get voice key by name (for backward compatibility)
  static String? getVoiceKeyByName(String name) {
    for (final entry in _voices.entries) {
      if (entry.value['name'] == name) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get all available voice keys
  static List<String> getAllVoiceKeys() {
    return _voices.keys.toList();
  }

  /// Get tone style information
  static Map<String, dynamic>? getToneStyle(String styleName) {
    return _toneStyles[styleName];
  }

  /// Get all tone styles
  static Map<String, Map<String, dynamic>> getAllToneStyles() {
    return _toneStyles;
  }

  /// Generate SSML for dramatic voice effects
  static String generateSSML({
    required String text,
    required String voiceKey,
    required String toneStyle,
    double? speakingRate,
    double? pitch,
  }) {
    final voice = getVoiceByKey(voiceKey);
    final tone = getToneStyle(toneStyle);
    
    if (voice == null || tone == null) {
      return '<speak>$text</speak>';
    }

    final modifiers = (tone['modifiers'] as List<String>).join(', ');
    final intensity = tone['intensity'] as int;
    
    // Adjust speaking rate based on personality and tone intensity
    final rate = speakingRate ?? _calculateSpeakingRate(voice, intensity);
    final voicePitch = pitch ?? _calculatePitch(voice, intensity);
    
    return '''
<speak>
  <prosody rate="${rate}x" pitch="${voicePitch > 0 ? '+' : ''}${voicePitch}st">
    <emphasis level="${intensity > 7 ? 'strong' : intensity > 4 ? 'moderate' : 'reduced'}">
      $text
    </emphasis>
  </prosody>
</speak>''';
  }

  /// Calculate speaking rate based on personality and tone
  static double _calculateSpeakingRate(Map<String, dynamic> voice, int intensity) {
    final baseRate = voice['voice_settings']['style'] == 'relaxed' ? 0.8 : 1.0;
    final intensityModifier = (intensity - 5) * 0.1; // -0.5 to +0.5
    return (baseRate + intensityModifier).clamp(0.5, 2.0);
  }

  /// Calculate pitch adjustment based on personality and tone
  static double _calculatePitch(Map<String, dynamic> voice, int intensity) {
    final category = voice['category'];
    final basePitch = category == 'female' ? 2.0 : category == 'character' ? 0.0 : -1.0;
    final intensityModifier = (intensity - 5) * 1.0; // -5 to +5 semitones
    return (basePitch + intensityModifier).clamp(-10.0, 10.0);
  }

  /// Generate motivational prompt for AI systems
  static String generateMotivationalPrompt({
    required String voiceKey,
    required String toneStyle,
    required String taskDescription,
    String? userName,
  }) {
    final voice = getVoiceByKey(voiceKey);
    final tone = getToneStyle(toneStyle);
    
    if (voice == null || tone == null) {
      return 'You need to complete: $taskDescription';
    }

    final personality = voice['name'];
    final description = voice['description'];
    final samplePhrase = voice['sample_phrase'];
    final toneDescription = tone['description'];
    final intensity = tone['intensity'];

    return '''
You are a ${personality} motivational coach. ${description}

Your speaking style: ${toneDescription} (intensity level ${intensity}/10)
Example of how you talk: "${samplePhrase}"

Task to motivate about: ${taskDescription}
${userName != null ? 'User\'s name: ${userName}' : ''}

Generate a motivational message that:
1. Stays completely in character as ${personality}
2. Uses the ${toneStyle} tone style
3. Is specific to the task: ${taskDescription}
4. Is between 15-40 words
5. Includes personality-specific language and energy level

Remember: You ARE the ${personality}. Speak directly as this character would.''';
  }

  /// Get category display information
  static Map<String, Map<String, dynamic>> getCategoryInfo() {
    return {
      'male': {
        'label': '💪 Alpha Squad',
        'description': 'Strong, confident male personalities',
        'icon': '💪',
        'color': 'blue',
      },
      'female': {
        'label': '👑 Queen Squad', 
        'description': 'Fierce, empowered female personalities',
        'icon': '👑',
        'color': 'pink',
      },
      'character': {
        'label': '🎭 Wild Cards',
        'description': 'Unique characters and personas',
        'icon': '🎭', 
        'color': 'purple',
      },
    };
  }

  /// Get default voice for a category
  static String getDefaultVoiceForCategory(String category) {
    switch (category) {
      case 'male':
        return 'drill_sergeant';
      case 'female':
        return 'sassy_diva';
      case 'character':
        return 'superhero';
      default:
        return 'drill_sergeant';
    }
  }
}