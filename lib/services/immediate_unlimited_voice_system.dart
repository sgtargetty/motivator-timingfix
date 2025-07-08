// 🚀 IMMEDIATE UNLIMITED VOICE SYSTEM
// Gives you unlimited combinations TODAY using enhanced ElevenLabs + your samples
// While building toward StyleTTS2 integration

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/motivator_api.dart';

class ImmediateUnlimitedVoiceSystem {
  static final ImmediateUnlimitedVoiceSystem _instance = ImmediateUnlimitedVoiceSystem._internal();
  factory ImmediateUnlimitedVoiceSystem() => _instance;
  ImmediateUnlimitedVoiceSystem._internal();

  final MotivatorApi _api = MotivatorApi();
  
  // 🎭 COMPLETE VOICE PERSONALITY CATALOG (All your EccentricVoiceSystem voices)
  static const Map<String, Map<String, dynamic>> _allVoicePersonalities = {
    // 💪 ALPHA SQUAD (All Male Personalities)
    'drill_sergeant': {
      'name': 'Drill Sergeant',
      'category': 'male',
      'elevenlabs_voice': 'male:Professional Male', // Map to your working EL voice
      'personality_enhancer': 'LISTEN UP RECRUIT! {name}! ',
      'name_style': 'SOLDIER {name}',
      'sample_fallback': 'male_professional_male',
    },
    'wise_mentor': {
      'name': 'Wise Mentor',
      'category': 'male',
      'elevenlabs_voice': 'male:Default Male',
      'personality_enhancer': 'Young {name}, wisdom comes to those who seek it. ',
      'name_style': 'my young apprentice {name}',
      'sample_fallback': 'male_default_male',
    },
    'hype_beast': {
      'name': 'Hype Beast',
      'category': 'male',
      'elevenlabs_voice': 'male:Energetic Male',
      'personality_enhancer': 'YOOOOO {name}! LET\'S GOOOOO! ',
      'name_style': '{name}, my dude',
      'sample_fallback': 'male_energetic_male',
    },
    'chill_surfer': {
      'name': 'Chill Surfer',
      'category': 'male',
      'elevenlabs_voice': 'male:Calm Male',
      'personality_enhancer': 'Dude {name}, totally gnarly vibes ahead. ',
      'name_style': '{name}, bro',
      'sample_fallback': 'male_default_male',
    },
    'british_butler': {
      'name': 'British Butler',
      'category': 'male',
      'elevenlabs_voice': 'male:Professional Male',
      'personality_enhancer': 'I do believe, Master {name}, that excellence awaits. ',
      'name_style': 'Master {name}',
      'sample_fallback': 'male_professional_male',
    },
    'sports_coach': {
      'name': 'Sports Coach',
      'category': 'male',
      'elevenlabs_voice': 'male:Energetic Male',
      'personality_enhancer': 'Alright {name}! Game time, champion! ',
      'name_style': 'Champion {name}',
      'sample_fallback': 'male_energetic_male',
    },

    // 👑 QUEEN SQUAD (All Female Personalities)
    'sassy_diva': {
      'name': 'Sassy Diva',
      'category': 'female',
      'elevenlabs_voice': 'female:Energetic Female',
      'personality_enhancer': 'Honey {name}, you\'re about to SPARKLE! ',
      'name_style': '{name}, gorgeous',
      'sample_fallback': 'female_energetic_female',
    },
    'supportive_mom': {
      'name': 'Supportive Mom',
      'category': 'female',
      'elevenlabs_voice': 'female:Default Female',
      'personality_enhancer': 'Sweetie {name}, mama believes in you! ',
      'name_style': '{name}, sweetie',
      'sample_fallback': 'female_default_female',
    },
    'queen_boss': {
      'name': 'Queen Boss',
      'category': 'female',
      'elevenlabs_voice': 'female:Professional Female',
      'personality_enhancer': 'Your Majesty {name}, the kingdom awaits your command! ',
      'name_style': 'Your Majesty {name}',
      'sample_fallback': 'female_professional_female',
    },
    'valley_girl': {
      'name': 'Valley Girl',
      'category': 'female',
      'elevenlabs_voice': 'female:Energetic Female',
      'personality_enhancer': 'OMG {name}! This is gonna be like, totally amazing! ',
      'name_style': '{name}, babe',
      'sample_fallback': 'female_energetic_female',
    },
    'zen_goddess': {
      'name': 'Zen Goddess',
      'category': 'female',
      'elevenlabs_voice': 'female:Calm Female',
      'personality_enhancer': 'Breathe in peace, {name}, breathe out possibility. ',
      'name_style': 'beautiful soul {name}',
      'sample_fallback': 'female_default_female',
    },
    'news_anchor': {
      'name': 'News Anchor',
      'category': 'female',
      'elevenlabs_voice': 'female:Professional Female',
      'personality_enhancer': 'This just in: {name} is about to achieve greatness! ',
      'name_style': '{name}',
      'sample_fallback': 'female_professional_female',
    },

    // 🎭 WILD CARDS (All Character Personalities)
    'superhero': {
      'name': 'Superhero',
      'category': 'character',
      'elevenlabs_voice': 'characters:Argent',
      'personality_enhancer': 'The city needs you, Hero {name}! With great power... ',
      'name_style': 'Hero {name}',
      'sample_fallback': 'characters_argent',
    },
    'robot_assistant': {
      'name': 'Robot Assistant',
      'category': 'character',
      'elevenlabs_voice': 'characters:Robot Assistant',
      'personality_enhancer': 'Initiating motivation protocol for User {name}. ',
      'name_style': 'User {name}',
      'sample_fallback': 'characters_robot_assistant',
    },
    'pirate_captain': {
      'name': 'Pirate Captain',
      'category': 'character',
      'elevenlabs_voice': 'characters:Baxter Jordan',
      'personality_enhancer': 'Ahoy {name}! Ready to sail the seven seas of success? ',
      'name_style': '{name}, me hearty',
      'sample_fallback': 'characters_baxter_jordan',
    },
    'wizard_sage': {
      'name': 'Wizard Sage',
      'category': 'character',
      'elevenlabs_voice': 'characters:Lana Croft',
      'personality_enhancer': 'Ancient magic flows through you, {name}. ',
      'name_style': 'Young wizard {name}',
      'sample_fallback': 'characters_lana_croft',
    },
    'game_show_host': {
      'name': 'Game Show Host',
      'category': 'character',
      'elevenlabs_voice': 'characters:Lana Croft',
      'personality_enhancer': 'Ladies and gentlemen, {name} is our next contestant! ',
      'name_style': 'contestant {name}',
      'sample_fallback': 'characters_lana_croft',
    },
    'lana_croft': {
      'name': 'Lana Croft',
      'category': 'character',
      'elevenlabs_voice': 'characters:Lana Croft',
      'personality_enhancer': 'Adventure awaits, {name}! Ready to explore the unknown? ',
      'name_style': 'fellow adventurer {name}',
      'sample_fallback': 'characters_lana_croft',
    },
    'baxter_jordan': {
      'name': 'Baxter Jordan',
      'category': 'character',
      'elevenlabs_voice': 'characters:Baxter Jordan',
      'personality_enhancer': 'Greetings {name}! Excellence is our standard. ',
      'name_style': '{name}, my friend',
      'sample_fallback': 'characters_baxter_jordan',
    },
    'argent': {
      'name': 'Argent',
      'category': 'character',
      'elevenlabs_voice': 'characters:Argent',
      'personality_enhancer': 'Sharp focus, {name}. Precision is power. ',
      'name_style': 'Agent {name}',
      'sample_fallback': 'characters_argent',
    },
  };

  // 🎭 ALL TONE STYLES WITH ENHANCED PROMPTS
  static const Map<String, Map<String, dynamic>> _enhancedToneStyles = {
    'Balanced': {
      'intensity': 5,
      'prompt_enhancer': 'Speak with balanced, supportive energy. ',
      'text_modifier_type': 'none',
    },
    'Drill Sergeant': {
      'intensity': 10,
      'prompt_enhancer': 'Speak with INTENSE, COMMANDING MILITARY ENERGY! USE CAPS! ',
      'text_modifier_type': 'uppercase',
    },
    'Cheerleader': {
      'intensity': 9,
      'prompt_enhancer': 'Speak with ENTHUSIASTIC, SPIRITED cheerleader energy! Go team! ',
      'text_modifier_type': 'cheer',
    },
    'Sage': {
      'intensity': 3,
      'prompt_enhancer': 'Speak with wise, contemplative, thoughtful energy. ',
      'text_modifier_type': 'sage',
    },
    'Coach': {
      'intensity': 7,
      'prompt_enhancer': 'Speak with motivational coaching energy! You can do this! ',
      'text_modifier_type': 'coach',
    },
    'Friend': {
      'intensity': 4,
      'prompt_enhancer': 'Speak like a caring friend with warm, casual energy. ',
      'text_modifier_type': 'friend',
    },
  };

  /// 🎤 UNLIMITED VOICE GENERATION: Any personality + any tone + any name
  Future<Uint8List?> generateUnlimitedVoice({
    required String originalText,
    required String voicePersonality,
    required String toneStyle,
    required String userName,
  }) async {
    try {
      print('🎤 Generating unlimited voice:');
      print('  Personality: $voicePersonality');
      print('  Tone: $toneStyle');
      print('  Name: $userName');

      // 1. Try pre-generated sample first (instant, free)
      final sampleAudio = await _tryPreGeneratedSample(
        voicePersonality: voicePersonality,
        toneStyle: toneStyle,
        userName: userName,
      );
      
      if (sampleAudio != null) {
        print('✅ Using pre-generated sample');
        return sampleAudio;
      }

      // 2. Generate with enhanced ElevenLabs (unlimited combinations)
      final enhancedAudio = await _generateEnhancedElevenLabs(
        originalText: originalText,
        voicePersonality: voicePersonality,
        toneStyle: toneStyle,
        userName: userName,
      );

      if (enhancedAudio != null) {
        print('✅ Generated with enhanced ElevenLabs');
        return enhancedAudio;
      }

      print('❌ Voice generation failed');
      return null;
    } catch (e) {
      print('❌ Unlimited voice generation error: $e');
      return null;
    }
  }

  /// 🎯 TRY PRE-GENERATED SAMPLE (For speed + cost savings)
  Future<Uint8List?> _tryPreGeneratedSample({
    required String voicePersonality,
    required String toneStyle,
    required String userName,
  }) async {
    try {
      final personality = _allVoicePersonalities[voicePersonality];
      if (personality == null) return null;

      final samplePrefix = personality['sample_fallback'];
      final toneKey = _mapToneForSample(toneStyle);
      final nameKey = _findClosestSampleName(userName);

      if (nameKey != null) {
        final samplePath = '${samplePrefix}_${toneKey}_${nameKey}.mp3';
        
        try {
          final byteData = await rootBundle.load('assets/voices/premium/$samplePath');
          print('✅ Found pre-generated sample: $samplePath');
          return byteData.buffer.asUint8List();
        } catch (e) {
          print('❌ Sample not found: $samplePath');
        }
      }

      return null;
    } catch (e) {
      print('❌ Sample loading error: $e');
      return null;
    }
  }

  /// 🚀 ENHANCED ELEVENLABS GENERATION (Unlimited combinations)
  Future<Uint8List?> _generateEnhancedElevenLabs({
    required String originalText,
    required String voicePersonality,
    required String toneStyle,
    required String userName,
  }) async {
    try {
      final personality = _allVoicePersonalities[voicePersonality];
      final tone = _enhancedToneStyles[toneStyle];
      
      if (personality == null || tone == null) return null;

      // Build enhanced text with personality and name
      final enhancedText = _buildEnhancedText(
        originalText: originalText,
        personality: personality,
        tone: tone,
        userName: userName,
      );

      // Use mapped ElevenLabs voice
      final elevenLabsVoice = personality['elevenlabs_voice'];
      
      print('🎯 Enhanced text: ${enhancedText.substring(0, math.min(100, enhancedText.length))}...');
      print('🎤 Using ElevenLabs voice: $elevenLabsVoice');

      // Generate with your existing ElevenLabs API
      return await _api.generateVoice(
        enhancedText,
        voiceStyle: elevenLabsVoice,
        toneStyle: toneStyle,
      );
    } catch (e) {
      print('❌ Enhanced ElevenLabs error: $e');
      return null;
    }
  }

  /// 📝 BUILD ENHANCED TEXT (Personality + tone + name integration)
  String _buildEnhancedText({
    required String originalText,
    required Map<String, dynamic> personality,
    required Map<String, dynamic> tone,
    required String userName,
  }) {
    // 1. Add personality enhancer with user's name
    String enhancedText = personality['personality_enhancer']
        .replaceAll('{name}', userName);

    // 2. Apply tone modifications to original text
      final modifiedOriginal = _applyToneModification(originalText, tone['text_modifier_type']);

    // 3. Replace generic references with personalized ones (word-boundary aware)
    String personalizedText = modifiedOriginal;
    final nameStyle = personality['name_style'].replaceAll('{name}', userName);
    
    // Replace whole words only to avoid "your" -> "User sergeant" issues
    personalizedText = personalizedText.replaceAllMapped(
      RegExp(r'\byour\b', caseSensitive: false),
      (match) => '${nameStyle}\'s',
    );
    personalizedText = personalizedText.replaceAllMapped(
      RegExp(r'\byou\b', caseSensitive: false),  
      (match) => nameStyle,
    );

    // 4. Combine everything
    return '$enhancedText$personalizedText';
  }

  /// 🗺️ MAP TONE STYLE TO SAMPLE NAMING
  String _mapToneForSample(String toneStyle) {
    switch (toneStyle) {
      case 'Drill Sergeant': return 'Drill_Sergeant';
      case 'Cheerleader': return 'Cheerleader';
      case 'Sage': return 'Sage';
      case 'Coach': return 'Coach';
      case 'Friend': return 'Friend';
      default: return 'Balanced';
    }
  }

  /// 👤 FIND CLOSEST SAMPLE NAME
  String? _findClosestSampleName(String userName) {
    const sampleNames = ['Ashley', 'Brandon', 'Jessica', 'Marcus', 'Ryan', 'Tyler'];
    final cleanName = userName.trim().toLowerCase();
    
    // Exact match
    for (final name in sampleNames) {
      if (name.toLowerCase() == cleanName) return name;
    }
    
    // Partial match
    for (final name in sampleNames) {
      if (name.toLowerCase().startsWith(cleanName)) return name;
    }
    
    return null; // Will trigger ElevenLabs generation
  }

  /// 🎯 GET ALL VOICE PERSONALITIES
  static List<Map<String, dynamic>> getAllVoicePersonalities() {
    return _allVoicePersonalities.entries.map((entry) {
      final voice = Map<String, dynamic>.from(entry.value);
      voice['key'] = entry.key;
      return voice;
    }).toList();
  }

  /// 📊 GET VOICES BY CATEGORY
  static Map<String, List<Map<String, dynamic>>> getVoicesByCategory() {
    final categorized = <String, List<Map<String, dynamic>>>{
      'male': [],
      'female': [],
      'character': [],
    };

    for (final entry in _allVoicePersonalities.entries) {
      final voice = Map<String, dynamic>.from(entry.value);
      voice['key'] = entry.key;
      categorized[voice['category']]?.add(voice);
    }

    return categorized;
  }

  /// 🎭 GET ALL TONE STYLES
  static List<String> getAllToneStyles() {
    return _enhancedToneStyles.keys.toList();
  }
  /// 📝 APPLY TONE MODIFICATION
  String _applyToneModification(String text, String modificationType) {
    switch (modificationType) {
      case 'uppercase':
        return text.toUpperCase().replaceAll('.', '!');
      case 'cheer':
        return '$text GO GO GO!';
      case 'sage':
        return 'Hmm... $text Indeed.';
      case 'coach':
        return '$text Let\'s make it happen!';
      case 'friend':
        return 'Hey, $text You\'ve got this!';
      case 'none':
      default:
        return text;
    }
  }
}