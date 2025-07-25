// lib/screens/widgets/realtime_voice_chat.dart - Complete Voice System with Backchannel

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

// Add this class at the TOP of realtime_voice_chat.dart
class FlexibleRelationshipManager {
  static const Map<String, Map<String, dynamic>> _personalityConfig = {
    'Lana Croft': {
      'name': 'Lana Croft',
      'gender': 'Female',
      'accent': 'British',
      'personality': 'Adventurous & Flirty',
      'description': 'Ready for an adventure? Let\'s explore together!',
      'icon': Icons.explore,
      'color': Color(0xFFD4AF37),
      'voiceId': 'cgSgspJ2msm6clMCkdW9',
      'defaultRelationshipTrack': 'romantic',
    },
    'Baxter Jordan': {
      'name': 'Baxter Jordan',
      'gender': 'Male',
      'accent': 'American',
      'personality': 'Analytical & Wise',
      'description': 'Let\'s analyze this situation and find the best path forward.',
      'icon': Icons.psychology,
      'color': Color(0xFF4A90E2),
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'defaultRelationshipTrack': 'mentor',
    },
    'Sophie Chen': {
      'name': 'Sophie Chen',
      'gender': 'Female',
      'accent': 'Asian-American',
      'personality': 'Bubbly & Sisterly',
      'description': 'OMG, this is going to be so much fun! Tell me everything!',
      'icon': Icons.favorite,
      'color': Color(0xFFFF6B9D),
      'voiceId': 'TBD',
      'defaultRelationshipTrack': 'platonic',
    },
    'Marcus Thompson': {
      'name': 'Marcus Thompson',
      'gender': 'Male',
      'accent': 'Black American',
      'personality': 'Chill & Loyal',
      'description': 'Yo, I got your back. Let\'s figure this out together, bro.',
      'icon': Icons.support,
      'color': Color(0xFF34C759),
      'voiceId': 'TBD',
      'defaultRelationshipTrack': 'platonic',
    },
  };

  static Map<String, dynamic>? _getPersonaConfig(String personality) {
    return _personalityConfig[personality];
  }
}

// 🎭 ADD THESE ENUMS HERE:
enum RelationshipType {
  romantic,     // Girlfriend/Boyfriend progression
  platonic,     // Best friend progression
  mentor,       // Wise advisor/teacher
  sibling,      // Brother/Sister dynamic
  companion,    // Loyal companion/pet-like (for unique personas)
}

enum RelationshipLevel {
  acquaintance,    // 0-30 points
  friend,          // 31-80 points  
  closeFriend,     // 81-150 points
  intimate,        // 151-250 points (context depends on relationship type)
  soulmate,        // 251+ points (context depends on relationship type)
}
// 🎯 RELATIONSHIP TYPE SELECTOR UI

class RelationshipTypeSelectorModal extends StatefulWidget {
  final String personality;
  final Function(RelationshipType) onRelationshipTypeSelected;

  const RelationshipTypeSelectorModal({
    Key? key,
    required this.personality,
    required this.onRelationshipTypeSelected,
  }) : super(key: key);

  @override
  _RelationshipTypeSelectorModalState createState() => _RelationshipTypeSelectorModalState();
}

class _RelationshipTypeSelectorModalState extends State<RelationshipTypeSelectorModal> {
  RelationshipType? selectedType;

  @override
  Widget build(BuildContext context) {
    final persona = FlexibleRelationshipManager._getPersonaConfig(widget.personality);
    final availableTypes = persona?['preferredRelationships'] as List<RelationshipType>? ?? [];    
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: (persona?['color'] as Color? ?? Colors.grey).withOpacity(0.1),
                child: Icon(
                  _getPersonaIcon(widget.personality),
                  color: persona?['color'] as Color? ?? Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How do you want to connect with ${widget.personality}?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Choose the type of relationship you'd like to build",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Relationship Type Options
          ...availableTypes.map((type) => _buildRelationshipOption(type)),
          
          SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Let me decide naturally"),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedType != null 
                    ? () {
                        widget.onRelationshipTypeSelected(selectedType!);
                        Navigator.pop(context);
                      }
                    : null,
                  child: Text("Start Chatting"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipOption(RelationshipType type) {
    final isSelected = selectedType == type;
    final info = _getRelationshipTypeInfo(type, widget.personality);
    
    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              info['icon'],
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 24,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    info['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getRelationshipTypeInfo(RelationshipType type, String personality) {
    final persona = FlexibleRelationshipManager._getPersonaConfig(personality);
    final gender = persona?['gender'] ?? 'Unknown';
    
    switch (type) {
      case RelationshipType.romantic:
        return {
          'icon': Icons.favorite,
          'title': gender == 'female' ? 'Romantic (Girlfriend)' : 'Romantic (Boyfriend)',
          'description': 'Build a loving romantic relationship with flirtation, dates, and deep emotional connection',
        };
        
      case RelationshipType.platonic:
        return {
          'icon': Icons.people,
          'title': 'Best Friend',
          'description': 'Deep friendship with emotional support, shared interests, and loyalty',
        };
        
      case RelationshipType.mentor:
        return {
          'icon': Icons.school,
          'title': 'Mentor & Guide',
          'description': 'Wise advisor who helps you grow, offers guidance, and supports your goals',
        };
        
      case RelationshipType.sibling:
        return {
          'icon': Icons.family_restroom,
          'title': gender == 'female' ? 'Like a Sister' : 'Like a Brother',
          'description': 'Protective, playful family-like bond with teasing and unconditional support',
        };
        
      case RelationshipType.companion:
        return {
          'icon': Icons.pets,
          'title': 'Loyal Companion',
          'description': 'Devoted companion who\'s always there for you through everything',
        };
    }
  }

  IconData _getPersonaIcon(String personality) {
    switch (personality) {
      case 'Lana Croft': return Icons.explore;
      case 'Baxter Jordan': return Icons.psychology;
      case 'Sophie Chen': return Icons.chat;
      case 'Marcus Thompson': return Icons.sports_basketball;
      default: return Icons.person;
    }
  }
}

// 🎯 SMART PERSONA SELECTION SCREEN
class PersonaSelectionScreen extends StatefulWidget {
  @override
  _PersonaSelectionScreenState createState() => _PersonaSelectionScreenState();
}

class _PersonaSelectionScreenState extends State<PersonaSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Choose Your AI Companion"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Who would you like to talk to?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Each AI has their own personality, voice, and relationship style",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: FlexibleRelationshipManager._personalityConfig.length,
                itemBuilder: (context, index) {
                  final personality = FlexibleRelationshipManager._personalityConfig.keys.elementAt(index);
                  final config = FlexibleRelationshipManager._personalityConfig[personality]!;
                  
                  return _buildPersonaCard(personality, config);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaCard(String personality, Map<String, dynamic> config) {
    return GestureDetector(
      onTap: () => _selectPersona(personality),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              config['color'].withOpacity(0.1),
              config['color'].withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: config['color'].withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: config['color'],
              child: Icon(
                _getPersonaIcon(personality),
                color: Colors.white,
                size: 30,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Name
            Text(
              personality,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 4),
            
            // Gender
            Text(
              "${config['gender']} • ${_getMainRelationshipType(config['defaultRelationship'])}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Personality
            Text(
              config['personality'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            Spacer(),
            
            // Relationship Types
            Wrap(
              spacing: 4,
              children: (config['preferredRelationships'] as List<RelationshipType>)
                  .take(2)
                  .map((type) => Chip(
                    label: Text(
                      _getShortRelationshipName(type),
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: config['color'].withOpacity(0.1),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPersona(String personality) {
    // Show relationship type selector
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RelationshipTypeSelectorModal(
        personality: personality,
        onRelationshipTypeSelected: (type) {
          // Navigate to chat with selected persona and relationship type
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RealtimeVoiceChat(                personality: personality,
                baseUrl: 'https://motivator-ai-backend.onrender.com',
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getPersonaIcon(String personality) {
    switch (personality) {
      case 'Lana Croft': return Icons.explore;
      case 'Baxter Jordan': return Icons.psychology;
      case 'Sophie Chen': return Icons.chat;
      case 'Marcus Thompson': return Icons.sports_basketball;
      default: return Icons.person;
    }
  }

  String _getMainRelationshipType(RelationshipType type) {
    switch (type) {
      case RelationshipType.romantic: return 'Romantic';
      case RelationshipType.platonic: return 'Friend';
      case RelationshipType.mentor: return 'Mentor';
      case RelationshipType.sibling: return 'Sibling';
      case RelationshipType.companion: return 'Companion';
    }
  }

  String _getShortRelationshipName(RelationshipType type) {
    switch (type) {
      case RelationshipType.romantic: return '💕 Romance';
      case RelationshipType.platonic: return '👫 Friend';
      case RelationshipType.mentor: return '🧙‍♂️ Mentor';
      case RelationshipType.sibling: return '👨‍👩‍👧‍👦 Family';
      case RelationshipType.companion: return '🐕 Companion';
    }
  }
}

// 🧠 ENHANCED BACKCHANNEL SELECTOR WITH DEEPER EMOTIONAL INTELLIGENCE
class BackchannelSelector {
  static List<String> _recentlyUsed = [];
  static int _maxHistorySize = 8; // Increased for better variety tracking
  static Map<String, int> _categoryUsage = {}; // Track category frequency

  // 🎯 ADVANCED MULTI-LAYER CONTEXT ANALYSIS
  static String selectBackchannelClip(String userMessage, int conversationTurn, Map<String, List<String>> clips) {
    final message = userMessage.toLowerCase();
    
    print("🧠 ENHANCED ML analyzing: '$userMessage' (turn $conversationTurn)");
    
    // 🚀 PRIORITY EMOTIONAL DETECTION (Most Important First)
    
    // 😢 HIGH PRIORITY: Emotional Distress - immediate empathy
    if (_detectEmotionalDistress(message)) {
      return _selectWithVariety(clips['empathy']!, 'empathy');
    }
    
    // 🎉 HIGH PRIORITY: Excitement & Success - celebrate with them
    if (_detectExcitement(message)) {
      return _selectWithVariety(clips['excitement']!, 'excitement');
    }
    
    // 💕 ROMANTIC/INTIMATE - handle specially 
    if (_detectIntimateContext(message)) {
      if (clips.containsKey('playful') && clips['playful']!.isNotEmpty) {
        return _selectWithVariety(clips['playful']!, 'playful');
      }
      return _selectWithVariety(clips['excitement']!, 'excitement');
    }
    
    // ❓ QUESTIONS & CURIOSITY - show engagement
    if (_detectQuestion(message)) {
      return _selectWithVariety(clips['curiosity']!, 'curiosity');
    }
    
    // ✅ AGREEMENT & CONFIRMATION - validate their thoughts
    if (_detectAgreement(message)) {
      return _selectWithVariety(clips['agreement']!, 'agreement');
    }
    
    // 🤔 COMPLEX THINKING - give thoughtful response
    if (_detectComplexThinking(message)) {
      return _selectWithVariety(clips['thinking']!, 'thinking');
    }
    
    // 🔄 CONVERSATION TRANSITIONS - natural flow
    if (_detectTransition(message)) {
      return _selectWithVariety(clips['filler_transitions']!, 'filler_transitions');
    }
    
    // 📈 CONVERSATION FLOW ADAPTATION
    if (conversationTurn <= 3) {
      // Early conversation - more acknowledgment with variety
      return _mixedResponse(['acknowledgment', 'understanding'], clips);
    } else if (conversationTurn > 8) {
      // Deep conversation - more varied emotional responses
      return _mixedResponse(['understanding', 'curiosity', 'thinking', 'agreement'], clips);
    }
    
    // 🎯 DEFAULT: Smart understanding with emotional awareness
    return _selectWithVariety(clips['understanding']!, 'understanding');
  }

  // 🔍 ENHANCED EMOTION DETECTION METHODS
  
  static bool _detectEmotionalDistress(String message) {
    final distressKeywords = [
      'problem', 'issue', 'stuck', 'wrong', 'bad', 'terrible', 'awful', 'hate', 
      'frustrated', 'angry', 'sad', 'depressed', 'upset', 'worried', 'stressed',
      'difficult', 'hard', 'tough', 'struggle', 'can\'t', 'won\'t work', 'broken'
    ];
    return _containsAny(message, distressKeywords);
  }

  static bool _detectExcitement(String message) {
    final excitementKeywords = [
      'awesome', 'amazing', 'great', 'love', 'fantastic', 'incredible', 'perfect',
      'yes!', 'finally', 'success', 'won', 'achieved', 'brilliant', 'excellent',
      'wonderful', 'thrilled', 'excited', 'can\'t wait', 'so good', 'best'
    ];
    return _containsAny(message, excitementKeywords);
  }

  static bool _detectIntimateContext(String message) {
    final intimateKeywords = [
      'hold hands', 'together', 'date', 'romantic', 'dinner', 'kiss', 'love',
      'together maybe', 'just us', 'intimate', 'close', 'sweet', 'cute',
      'stop calling it virtual' // User's specific hint about wanting real connection
    ];
    return _containsAny(message, intimateKeywords);
  }

  static bool _detectQuestion(String message) {
    return message.contains('?') || _containsAny(message, [
      'what', 'how', 'why', 'when', 'where', 'which', 'who',
      'tell me', 'explain', 'help me understand', 'do you think',
      'what about you', 'your thoughts', 'what do you'
    ]);
  }

  static bool _detectAgreement(String message) {
    final agreementKeywords = [
      'exactly', 'yes', 'right', 'agree', 'correct', 'true', 'definitely',
      'absolutely', 'you bet', 'for sure', 'totally', 'sounds good',
      'sounds like a plan', 'that works', 'perfect'
    ];
    return _containsAny(message, agreementKeywords);
  }

  static bool _detectComplexThinking(String message) {
    return message.length > 80 || _containsAny(message, [
      'complex', 'analyze', 'consider', 'strategy', 'plan', 'solution',
      'algorithm', 'technical', 'think about', 'philosophy', 'theory',
      'complicated', 'sophisticated', 'detailed'
    ]);
  }

  static bool _detectTransition(String message) {
    final transitionKeywords = [
      'so', 'well', 'actually', 'basically', 'anyway', 'moving on',
      'another thing', 'by the way', 'speaking of', 'that reminds me'
    ];
    return _containsAny(message, transitionKeywords);
  }

  // 🎲 SMART VARIETY SELECTION WITH CATEGORY BALANCING
  static String _selectWithVariety(List<String> clips, String category) {
    // Track category usage for better variety
    _categoryUsage[category] = (_categoryUsage[category] ?? 0) + 1;
    
    // Filter out recently used clips
    final availableClips = clips.where((clip) => !_recentlyUsed.contains(clip)).toList();
    
    String selectedClip;
    if (availableClips.isNotEmpty) {
      selectedClip = availableClips[math.Random().nextInt(availableClips.length)];
    } else {
      // If all clips used recently, clear oldest and pick any
      _recentlyUsed.clear();
      selectedClip = clips[math.Random().nextInt(clips.length)];
    }
    
    // Advanced tracking
    _recentlyUsed.add(selectedClip);
    if (_recentlyUsed.length > _maxHistorySize) {
      _recentlyUsed.removeAt(0);
    }
    
    print("🎵 SMART SELECTION: $category → ${selectedClip.split('/').last}");
    print("🎭 Category usage: $_categoryUsage");
    return selectedClip;
  }

  // 🎯 MIXED RESPONSE FOR CONVERSATIONAL VARIETY
  static String _mixedResponse(List<String> categories, Map<String, List<String>> clips) {
    // Choose category with least recent usage
    String chosenCategory = categories.first;
    int minUsage = _categoryUsage[chosenCategory] ?? 0;
    
    for (String category in categories) {
      int usage = _categoryUsage[category] ?? 0;
      if (usage < minUsage) {
        minUsage = usage;
        chosenCategory = category;
      }
    }
    
    return _selectWithVariety(clips[chosenCategory]!, chosenCategory);
  }

  static bool _containsAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}

// For non-blocking async calls
void unawaited(Future<void> future) {
  // Explicitly ignore the future
}

// 🎭 Voice states for UI
enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  backchanneling,
  error
}

class RealtimeVoiceChat extends StatefulWidget {
  final String personality;
  final String baseUrl;

  const RealtimeVoiceChat({
    Key? key,
    required this.personality,
    required this.baseUrl,
  }) : super(key: key);

  @override
  State<RealtimeVoiceChat> createState() => _RealtimeVoiceChatState();
}

class _RealtimeVoiceChatState extends State<RealtimeVoiceChat>
    with TickerProviderStateMixin {
  
  // 🎤 Voice Recognition
  late stt.SpeechToText _speechToText;
  late AudioPlayer _audioPlayer;
  late AudioPlayer _backchannelPlayer; // Separate player for instant clips
  late FlutterTts _flutterTts;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  
  // 🎭 UI Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _listeningController;
  late AnimationController _speakingController;
  late AnimationController _thinkingController;
  late AnimationController _backchannelController;
  
  late Animation<double> _pulseScale;
  late Animation<double> _listeningPulse;
  late Animation<double> _speakingBounce;
  late Animation<double> _thinkingRotation;
  late Animation<double> _backchannelPulse;
  
  // 🧠 PERSISTENT MEMORY & CONVERSATION STATE
  String _currentStatus = "Ready to chat!";
  String _lastAiResponse = "";
  List<Map<String, String>> _conversationHistory = [];
  List<Map<String, dynamic>> _customMemories = [];
  VoiceState _currentState = VoiceState.idle;
  String? _persistentUserId;
  int _totalConversations = 0;
  bool _hasLoadedMemory = false;
  Timer? _speechProcessingTimer;
  String _lastProcessedText = "";
  bool _isCurrentlyProcessing = false;

  // 🎵 BACKCHANNEL AUDIO SYSTEM
  List<String> _backchannelClips = [];
  List<String> _emotionClips = [];
  List<String> _greetingClips = [];
  bool _isBackchannelPlaying = false;
  String? _queuedRealResponse;
  Timer? _backchannelTimer;
  int _conversationTurn = 0;

  // 🎭 Personality Configurations
  Map<String, Map<String, dynamic>> get _personalityConfig => {
    'Lana Croft': {
        'voiceId': 'QXEkTn58Ik1IKjIMk8QA',
        'color': Colors.amber,
        'greeting': 'Ready for an adventure?',
        'gender': 'female',
        'preferredRelationships': [RelationshipType.romantic, RelationshipType.platonic],
        'defaultRelationship': RelationshipType.romantic,
        'personality': 'adventurous, confident, flirty',
        'accent': 'British',
        'description': 'British adventurer with a confident, flirty personality',
    },
    
    'Baxter Jordan': {
        'voiceId': 'pNInz6obpgDQGcFmaJgB', 
        'color': Colors.blue,
        'greeting': 'Let\'s analyze this situation...',
        'gender': 'male',
        'preferredRelationships': [RelationshipType.mentor, RelationshipType.platonic, RelationshipType.romantic],
        'defaultRelationship': RelationshipType.mentor,
        'personality': 'analytical, wise, supportive',
        'accent': 'American',
        'description': 'Wise American mentor with analytical thinking',
    },
    
    'Sophie Chen': {
        'voiceId': 'voice_id_3', // TODO: Add actual voice ID
        'color': Colors.pink,
        'greeting': 'Hey girl! What\'s up?',
        'gender': 'female',
        'preferredRelationships': [RelationshipType.platonic, RelationshipType.sibling],
        'defaultRelationship': RelationshipType.platonic,
        'personality': 'bubbly, supportive, sisterly',
        'accent': 'American',
        'description': 'Sweet Asian-American best friend with bubbly energy',
    },
    
    'Marcus Thompson': {
        'voiceId': 'voice_id_4', // TODO: Add actual voice ID
        'color': Colors.green,
        'greeting': 'What\'s good, bro?',
        'gender': 'male',
        'preferredRelationships': [RelationshipType.platonic, RelationshipType.mentor],
        'defaultRelationship': RelationshipType.platonic,
        'personality': 'chill, loyal, brotherhood',
        'accent': 'American',
        'description': 'Cool Black American bro with chill, loyal vibe',
    },
 };

  // 🎵 COMPREHENSIVE BACKCHANNEL AUDIO CLIPS CONFIGURATION
  Map<String, List<String>> get _audioClipsByType => {
    // ✅ QUICK ACKNOWLEDGMENTS (Most Frequent)
    'acknowledgment': [
      'assets/audio/backchannel/stronger_Mmhmm_acknowledgement.mp3',
      'assets/audio/backchannel/happy_Mmhmm_acknowledgement.mp3',
      'assets/audio/backchannel/clearing_throat_choking_Mhmm.mp3',
      'assets/audio/backchannel/Got_It_Acknowledge.mp3',
      'assets/audio/backchannel/Lively_Right_Acknowledge.mp3',
      'assets/audio/backchannel/Average_I_Get_It.mp3',
      'assets/audio/backchannel/sarcastic_Mmhmm.mp3', // For variety!
    ],

    // 🧠 UNDERSTANDING & PROCESSING
    'understanding': [
      'assets/audio/backchannel/I_see_caring.mp3',
      'assets/audio/backchannel/Average_That_Makes_Sense.mp3',
      'assets/audio/backchannel/Average_Totally.mp3',
      'assets/audio/backchannel/Average_Of_Course.mp3',
      'assets/audio/backchannel/Average_For_Sure.mp3',
      'assets/audio/backchannel/Average_Absolutely_Version_2.mp3',
    ],

    // 🤔 CURIOSITY & QUESTIONS
    'curiosity': [
      'assets/audio/backchannel/Curious_Really.mp3',
      'assets/audio/backchannel/Oh_Wow.mp3',
      'assets/audio/backchannel/Surprised_OOooh.mp3',
      'assets/audio/backchannel/Very_Intrigued_Thats_a_Good_Question.mp3',
      'assets/audio/backchannel/Seriously_Question.mp3',
      'assets/audio/backchannel/No_Way.mp3',
      'assets/audio/backchannel/Breathing_Whoa_No_Kidding.mp3',
      'assets/audio/backchannel/I_Had_No_Idea.mp3',
    ],

    // 🎯 AGREEMENT & CONFIRMATION
    'agreement': [
      'assets/audio/backchannel/Agreement_Exactly.mp3',
      'assets/audio/backchannel/Totally_Agree.mp3',
      'assets/audio/backchannel/Youre_Right.mp3',
      'assets/audio/backchannel/100_Percent.mp3',
      'assets/audio/backchannel/Definitely.mp3',
      'assets/audio/backchannel/Upbeat_Absolutely.mp3',
    ],

    // 🤯 THINKING & PROCESSING (Complex Topics)
    'thinking': [
      'assets/audio/backchannel/OH_Let_Me_Process_That.mp3',
      'assets/audio/backchannel/Laughing_Let_Me_Think_About_That.mp3',
      'assets/audio/backchannel/Breathing_Chuckle_Let_Me_Think_About_That.mp3',
      'assets/audio/backchannel/Genuine_Laughing_While_Saying_Let_Me_Think_About_That.mp3',
      'assets/audio/backchannel/Flirty_Laughing_Let_Me_Think_About_That_Thats_Good_Question.mp3',
      'assets/audio/backchannel/filler_quick_hmm.mp3',
    ],

    // 🎉 EXCITEMENT & POSITIVE REACTIONS
    'excitement': [
      'assets/audio/backchannel/excited_YEAH.mp3',
      'assets/audio/backchannel/Thats_Amazing.mp3',
      'assets/audio/backchannel/Thats_Wild.mp3',
      'assets/audio/backchannel/Cool.mp3',
      'assets/audio/backchannel/small_chuckle_yeah.mp3',
    ],

    // 💙 EMPATHY & CARING
    'empathy': [
      'assets/audio/backchannel/That_Sucks.mp3',
      'assets/audio/backchannel/Caring_Empathetic_Oh_Man.mp3',
      'assets/audio/backchannel/Caring_I_Feel_You.mp3',
      'assets/audio/backchannel/Caring_I_Understand.mp3',
      'assets/audio/backchannel/Caring_Thats_Tough.mp3',
    ],

    // 🔄 FILLER TRANSITIONS (Natural Flow)
    'filler_transitions': [
      'assets/audio/backchannel/Filler_Soo.mp3',
      'assets/audio/backchannel/Filler_The_Way_I_See_It.mp3',
      'assets/audio/backchannel/Filler_Wellll.mp3',
      'assets/audio/backchannel/Filler_Yeah_Well.mp3',
      'assets/audio/backchannel/Filler_Actually.mp3',
      'assets/audio/backchannel/Filler_I_Mean.mp3',
      'assets/audio/backchannel/Filer_Heres_The_Thing.mp3',
      'assets/audio/backchannel/Filler_Mmm_Okay.mp3',
      'assets/audio/backchannel/Filler_Huh_Lets_See.mp3',
      'assets/audio/backchannel/Filler_Slightly_Annoyed_Yea_Well.mp3',
    ],

    // 🎭 PLAYFUL & PERSONALITY
    'playful': [
      'assets/audio/backchannel/Filler_Playful_Mmmmm.mp3',
      'assets/audio/backchannel/Sensual_Moan_Explicit.mp3', // Interesting choice! 😏
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeVoiceChat();
    _setupAnimations();
    _loadPersistentMemory();
    _preloadAudioClips();
    
    // 🚀 Auto-start ChatGPT-style listening after initialization
    Timer(Duration(seconds: 3), () {
      if (mounted && _speechEnabled) {
        print("🎤 Auto-starting ChatGPT-style voice system...");
        setState(() {
          _currentStatus = "Ready to chat - just start speaking!";
        });
        _startListening();
      }
    });
  }

  // 🧹 CLEAN AI RESPONSE TEXT - Remove Emotion Markers
  String _cleanAIResponseText(String aiResponse) {
    String cleanedText = aiResponse;
    
    // List of common emotion markers to remove
    final emotionMarkers = [
      // Laughter
      r'\[Laughs?\]',
      r'\[Chuckles?\]',
      r'\[Giggles?\]',
      r'\[Snickers?\]',
      r'\[Cackles?\]',
      
      // Vocal expressions
      r'\[Sighs?\]',
      r'\[Gasps?\]',
      r'\[Whispers?\]',
      r'\[Mutters?\]',
      r'\[Hums?\]',
      
      // Physical actions
      r'\[Smiles?\]',
      r'\[Grins?\]',
      r'\[Nods?\]',
      r'\[Shrugs?\]',
      r'\[Winks?\]',
      
      // Pauses and timing
      r'\[Pauses?\]',
      r'\[Long pause\]',
      r'\[Brief pause\]',
      r'\[Silence\]',
      
      // Emotional states
      r'\[Excited\]',
      r'\[Surprised\]',
      r'\[Confused\]',
      r'\[Thoughtful\]',
      r'\[Curious\]',
      
      // Generic patterns - catches any [word] or [multiple words]
      r'\[[A-Za-z\s]+\]',
      
      // Asterisk actions like *laughs* or *chuckles*
      r'\*[A-Za-z\s]+\*',
      
      // Parenthetical actions like (laughs) or (chuckles)
      r'\([A-Za-z\s]*(?:laughs?|chuckles?|sighs?|smiles?|grins?)[A-Za-z\s]*\)',
    ];
    
    // Remove all emotion markers using regex
    for (String pattern in emotionMarkers) {
      cleanedText = cleanedText.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Clean up extra spaces and formatting
    cleanedText = cleanedText
        .replaceAll(RegExp(r'\s+'), ' ')  // Multiple spaces → single space
        .replaceAll(RegExp(r'\s*,\s*'), ', ')  // Fix comma spacing
        .replaceAll(RegExp(r'\s*\.\s*'), '. ')  // Fix period spacing
        .replaceAll(RegExp(r'\s*!\s*'), '! ')   // Fix exclamation spacing
        .replaceAll(RegExp(r'\s*\?\s*'), '? ')  // Fix question spacing
        .trim();
    
    // Remove empty sentences that might be left behind
    cleanedText = cleanedText
        .replaceAll(RegExp(r'\.\s*\.'), '.')
        .replaceAll(RegExp(r'^\s*[.,!?]\s*'), '')
        .trim();
    
    print("🧹 Original text: '$aiResponse'");
    print("🧹 Cleaned text: '$cleanedText'");
    
    return cleanedText;
  }

  // 🎵 PRELOAD AUDIO CLIPS FOR INSTANT PLAYBACK
  Future<void> _preloadAudioClips() async {
    try {
      print("🎵 Preloading ALL backchannel audio clips...");
      
      int totalClips = 0;
      for (String category in _audioClipsByType.keys) {
        for (String clipPath in _audioClipsByType[category]!) {
          try {
            await _backchannelPlayer.setSource(AssetSource(clipPath.replaceFirst('assets/', '')));
            totalClips++;
            print("✅ Preloaded: ${clipPath.split('/').last}");
          } catch (e) {
            print("⚠️ Failed to preload $clipPath: $e");
          }
        }
      }
      
      print("🎵 Successfully preloaded $totalClips backchannel clips!");
      
    } catch (e) {
      print("❌ Error preloading audio clips: $e");
    }
  }

  // 🧠 ENHANCED ML-BASED CLIP SELECTION
  String _selectBackchannelClip(String userMessage, int conversationTurn) {
   return BackchannelSelector.selectBackchannelClip(userMessage, conversationTurn, _audioClipsByType);
  }

  // 🧠 FALLBACK: SIMPLE ML-BASED CLIP SELECTION (If Enhanced Fails)
  String _selectBackchannelClipSimple(String userMessage, int conversationTurn) {
    final message = userMessage.toLowerCase();
    final clips = _audioClipsByType;
    
    print("🧠 ML selecting clip for: '$userMessage' (turn $conversationTurn)");
    
    // 🎯 CONTEXT-BASED SELECTION
    
    // First turn - more acknowledgment
    if (conversationTurn <= 2) {
      return _getRandomClip(clips['acknowledgment']!);
    }
    
    // Detect emotional context
    if (message.contains('problem') || message.contains('issue') || 
        message.contains('stuck') || message.contains('wrong')) {
      return _getRandomClip(clips['empathy']!);
    }
    
    // Detect excitement
    if (message.contains('awesome') || message.contains('amazing') || 
        message.contains('great') || message.contains('love')) {
      return _getRandomClip(clips['excitement']!);
    }
    
    // Detect questions or curiosity
    if (message.contains('?') || message.contains('what') || 
        message.contains('how') || message.contains('why')) {
      return _getRandomClip(clips['curiosity']!);
    }
    
    // Detect agreement/confirmation
    if (message.contains('exactly') || message.contains('yes') || 
        message.contains('right') || message.contains('agree')) {
      return _getRandomClip(clips['agreement']!);
    }
    
    // Detect thinking/complex topics
    if (message.length > 50 || message.contains('complex') || 
        message.contains('difficult') || message.contains('think')) {
      return _getRandomClip(clips['thinking']!);
    }
    
    // Default to understanding
    return _getRandomClip(clips['understanding']!);
  }

  String _getRandomClip(List<String> clips) {
    final random = math.Random();
    return clips[random.nextInt(clips.length)];
  }

  // 🎵 ENHANCED BACKCHANNEL PLAYBACK (Replace your existing method)
  Future<void> _playBackchannelClip(String userMessage) async {
    if (_isBackchannelPlaying) return;
  
    // Safer state management
    if (!mounted) return;
    setState(() {
      _currentState = VoiceState.backchanneling;
      _currentStatus = "Responding naturally...";
      _isBackchannelPlaying = true;
    });
  
    try {
      // Enhanced clip selection with new ML
      final clipPath = _selectBackchannelClip(userMessage, _conversationTurn);
      print("🚀 INSTANT: Playing backchannel clip: $clipPath");
    
      // Smoother animation
      _backchannelController.repeat(reverse: true);
    
      // NON-BLOCKING audio playback
      final assetPath = clipPath.replaceFirst('assets/', '');
      unawaited(_backchannelPlayer.play(AssetSource(assetPath)));
    
      // Improved completion handling
      _backchannelPlayer.onPlayerComplete.first.then((_) {
        print("✅ Backchannel completed smoothly");
        if (mounted) {
          setState(() {
            _isBackchannelPlaying = false;
            if (_currentState == VoiceState.backchanneling) {
              _currentState = VoiceState.processing; // Smooth transition
            }
        });
        _backchannelController.stop();
      }
    }).catchError((e) {
      print("❌ Backchannel error: $e");
      if (mounted) {
        setState(() {
          _isBackchannelPlaying = false;
        });
        _backchannelController.stop();
      }
    });
    
  } catch (e) {
    print("❌ Error playing backchannel: $e");
    if (mounted) {
      setState(() {
        _isBackchannelPlaying = false;
      });
      _backchannelController.stop();
    }
  }
}

  // 🗣️ Check for filler words
  bool _isJustFillerWords(String text) {
    final fillers = ['um', 'umm', 'uh', 'uhh', 'hmm', 'ah', 'er', 'like'];
    final words = text.toLowerCase().trim().split(' ');
    
    final meaningfulWords = words.where((word) => 
      word.length > 2 && !fillers.contains(word)
    ).toList();
    
    return meaningfulWords.isEmpty || text.trim().length < 5;
  }

  // 🔄 Auto-restart method with conversation tracking
  Future<void> _resetToIdleAndRestart() async {
    setState(() {
      _currentState = VoiceState.idle;
      _currentStatus = "Ready for next conversation...";
    });
    
    _thinkingController.stop();
    _speakingController.stop();
    _listeningController.stop();
    _backchannelController.stop();
    
    _isCurrentlyProcessing = false;
    _conversationTurn++; // Track conversation progress
    
    print("🔄 Conversation turn: $_conversationTurn, restarting in 1s...");
    
    await Future.delayed(Duration(seconds: 1));
    
    if (mounted && _speechEnabled) {
      print("🎤 Auto-restarting ChatGPT-style listening...");
      _startListening();
    }
  }

  // 🧠 PERSISTENT MEMORY MANAGEMENT
  Future<void> _loadPersistentMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _persistentUserId = prefs.getString('persistent_user_id');
      if (_persistentUserId == null) {
        _persistentUserId = const Uuid().v4();
        await prefs.setString('persistent_user_id', _persistentUserId!);
        print("🆔 Created new persistent user ID: $_persistentUserId");
      } else {
        print("🆔 Loaded existing user ID: $_persistentUserId");
      }
      
      final historyJson = prefs.getString('conversation_history_${widget.personality}');
      if (historyJson != null) {
        final historyList = json.decode(historyJson) as List;
        _conversationHistory = historyList.map((item) => 
          Map<String, String>.from(item)).toList();
        
        if (_conversationHistory.length > 20) {
          _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
          await _savePersistentMemory();
        }
        
        print("📚 Loaded ${_conversationHistory.length} previous conversations");
      }
      // 🧠 NEW: Load custom memories too!
    await _loadCustomMemories();
      
      _totalConversations = prefs.getInt('total_conversations_${widget.personality}') ?? 0;
      await _loadBackendMemory();
      
      setState(() {
        _hasLoadedMemory = true;
        if (_conversationHistory.isNotEmpty) {
          final memorySummary = _customMemories.isNotEmpty 
            ? " + ${_customMemories.length} custom memories"
            : "";
          _currentStatus = "${widget.personality} remembers your ${_conversationHistory.length} conversations$memorySummary!";
        } else {
          _currentStatus = "${widget.personality} is ready to start building memories with you!";
        }
      });
      
    } catch (e) {
      print("❌ Error loading persistent memory: $e");
      _persistentUserId = const Uuid().v4();
      setState(() {
        _hasLoadedMemory = true;
        _currentStatus = "Ready to chat!";
      });
    }
  }
  // 🧠 NEW: Load custom memories from SharedPreferences  
  Future<void> _loadCustomMemories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customMemoriesJson = prefs.getString('custom_memories_${widget.personality}') ?? '[]';
      _customMemories = List<Map<String, dynamic>>.from(json.decode(customMemoriesJson));
      print("🧠 Loaded ${_customMemories.length} custom memories");
    } catch (e) {
      print("❌ Error loading custom memories: $e");
      _customMemories = [];
    }
  }

  Future<void> _savePersistentMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(
        'conversation_history_${widget.personality}',
        json.encode(_conversationHistory)
      );
      
      await prefs.setInt('total_conversations_${widget.personality}', _totalConversations);
      
      print("💾 Saved conversation history: ${_conversationHistory.length} conversations");
      
    } catch (e) {
      print("❌ Error saving persistent memory: $e");
    }
  }

  Future<void> _loadBackendMemory() async {
    try {
      if (_persistentUserId == null) return;
      
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/voice-conversation/memory/$_persistentUserId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final memory = data['memory'];
          final stats = data['stats'];
          
          print("☁️ Backend memory loaded:");
          print("   - Total conversations: ${memory['totalConversations']}");
          print("   - Recent patterns: ${memory['recentPatterns']}");
          
          _totalConversations = memory['totalConversations'] ?? 0;
        }
      }
    } catch (e) {
      print("❌ Error loading backend memory: $e");
    }
  }

  void _addToConversationHistory(String userMessage, String aiResponse) {
    final conversationEntry = {
      'user': userMessage,
      'assistant': aiResponse,
      'timestamp': DateTime.now().toIso8601String(),
      'personality': widget.personality,
    };
    
    setState(() {
      _conversationHistory.add(conversationEntry);
      _totalConversations++;
      
      if (_conversationHistory.length > 20) {
        _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
      }
    });
    
    _savePersistentMemory();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _listeningController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _listeningPulse = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _listeningController, curve: Curves.easeInOut),
    );
    
    _speakingController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _speakingBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _speakingController, curve: Curves.elasticOut),
    );
    
    _thinkingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _thinkingRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _thinkingController, curve: Curves.linear),
    );

    // 🎵 NEW: Backchannel animation
    _backchannelController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _backchannelPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _backchannelController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeVoiceChat() async {
    _speechToText = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
    _backchannelPlayer = AudioPlayer(); // Separate player for instant clips
    _flutterTts = FlutterTts();
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      print("🎵 TTS completed");
      if (mounted) {
        _resetToIdleAndRestart();
      }
    });
    
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      
      if (_speechEnabled) {
        print("🎤 Speech recognition initialized successfully");
      }
      
    } catch (e) {
      print("❌ Failed to initialize speech recognition: $e");
      setState(() {
        _currentStatus = "Voice recognition not available. Using text mode.";
      });
    }
  }

  void _onSpeechStatus(String status) {
    print("🎤 Speech status: $status");
    
    if (status == "listening") {
      setState(() {
        _currentState = VoiceState.listening;
        _currentStatus = "Listening... speak naturally!";
      });
      _listeningController.repeat(reverse: true);
    }
  }

  void _onSpeechError(dynamic error) {
    print("❌ Speech error: $error");
    setState(() {
      _currentState = VoiceState.error;
      _currentStatus = "Voice error - will retry automatically!";
    });
    
    Timer(Duration(seconds: 3), () {
      _resetToIdleAndRestart();
    });
  }

  // 🎤 CHATGPT-STYLE: Start Listening with Backchannel Support
  Future<void> _startListening() async {
    if (!_speechEnabled || _currentState != VoiceState.idle) return;

    try {
      setState(() {
        _currentState = VoiceState.listening;
        _currentStatus = "Listening... start speaking anytime!";
        _wordsSpoken = "";
      });

      HapticFeedback.lightImpact();
      _pulseController.stop();
      _listeningController.repeat(reverse: true);

      print("🎤 Starting ChatGPT-style auto-listening...");

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _wordsSpoken = result.recognizedWords;
            _confidenceLevel = result.confidence;
          });
          
          print("🗣️ Speech result: '${result.recognizedWords}' (final: ${result.finalResult})");
          
          // 🎯 SMART PROCESSING: Only process after real content + silence
          if (result.finalResult && 
              !_isCurrentlyProcessing && 
              _wordsSpoken.trim().length > 5 && 
              !_isJustFillerWords(_wordsSpoken)) {
            
            print("🤔 Potential complete thought detected, waiting 2s to confirm...");
            
            Timer(Duration(seconds: 2), () {
              if (_wordsSpoken.trim() == result.recognizedWords.trim() && 
                  !_isCurrentlyProcessing) {
                
                print("✅ User finished speaking, processing: '$_wordsSpoken'");

                _isCurrentlyProcessing = true;
                _lastProcessedText = _wordsSpoken;
                _processUserInputWithBackchannel(_wordsSpoken);
              } else {
                print("🔄 User continued speaking, waiting longer...");
              }
            });
          }
        },
        listenFor: Duration(minutes: 10),
        pauseFor: Duration(seconds: 20),
        partialResults: true,
        localeId: "en_US",
        cancelOnError: true,
      );

    } catch (e) {
      print("❌ Error starting listening: $e");
      setState(() {
        _currentState = VoiceState.error;
        _currentStatus = "Voice error - will retry automatically!";
      });
      
      Timer(Duration(seconds: 3), () {
        _resetToIdleAndRestart();
      });
    }
  }

  // 🎵 NEW: Instant backchannel with parallel processing  
  Future<void> _processUserInputWithBackchannel(String userText) async {
    if (userText.trim().isEmpty) {
      _resetToIdleAndRestart();
      return;
    }

    // 🚀 INSTANT: Start backchannel and backend call simultaneously
    if (userText.length > 10 && !_isJustFillerWords(userText)) {
      try {
        print("🚀 Starting INSTANT backchannel + backend call in parallel");
        
        // Start both immediately - no waiting!
        final backchannelFuture = _playBackchannelClip(userText);
        final backendFuture = _processUserInput(userText);
        
        // Let them run in parallel - don't wait for backchannel to finish
        unawaited(backchannelFuture); // Fire and forget
        await backendFuture; // Wait for the real processing
        
      } catch (e) {
        print("⚠️ Parallel processing error: $e");
        // Fallback to normal processing
        await _processUserInput(userText);
      }
    } else {
      // Short messages skip backchannel
      await _processUserInput(userText);
    }
  }

  // 🧠 Process User Input with Backchannel Integration
  Future<void> _processUserInput(String userText) async {
    if (userText.trim().isEmpty) {
      _resetToIdleAndRestart();
      return;
    }

    setState(() {
      _currentState = VoiceState.processing;
      _currentStatus = "${widget.personality} is thinking...";
    });

    _listeningController.stop();
    _thinkingController.repeat();
    HapticFeedback.mediumImpact();

    try {
      print("🧠 Processing: '$userText' with ${widget.personality}");
      
      final backendResponse = await _callBackendAPIWithMemory(userText);
      
      if (backendResponse != null && backendResponse['success'] == true) {
        final aiResponse = backendResponse['aiResponse'];
        final audioUrl = backendResponse['audioUrl'];
        final memoryStats = backendResponse['memoryStats'];
        
        setState(() {
          _lastAiResponse = _cleanAIResponseText(aiResponse);  // 🧹 Clean the text!
        });
        
        _addToConversationHistory(userText, aiResponse);
        
        print("🎯 AI Response: '$aiResponse'");
        print("🧠 Memory Stats: $memoryStats");
        print("🔊 Audio URL received: ${audioUrl != null ? 'Yes' : 'No'}");

        // 🎵 SMART WAIT: Only wait if backchannel is still playing after backend is ready
        if (_isBackchannelPlaying) {
          print("🎵 Backend ready, waiting for backchannel to finish naturally...");
          
          // Wait max 3 seconds for backchannel to finish
          int waitCount = 0;
          while (_isBackchannelPlaying && mounted && waitCount < 30) {
            await Future.delayed(Duration(milliseconds: 100));
            waitCount++;
          }
          
          print("🔍 DEBUG: Backchannel wait completed. Still playing: $_isBackchannelPlaying");
        }

        // Play real response - ENSURE THIS ALWAYS HAPPENS
        if (audioUrl != null && mounted) {
          print("🎵 Starting ElevenLabs audio playback...");
          try {
            await _playElevenLabsAudio(audioUrl);
            print("✅ ElevenLabs audio completed successfully");
          } catch (e) {
            print("❌ ElevenLabs audio failed: $e");
            print("🎵 Falling back to TTS");
            await _simulateVoice(aiResponse);
          }
        } else {
          print("🎵 No audio URL or not mounted, using fallback TTS");
          await _simulateVoice(aiResponse);
        }

      } else {
        print("🎯 Backend failed, using smart mock response");
        final mockResponse = _getSmartMockResponse(userText);
        
        setState(() {
          _lastAiResponse = mockResponse;
        });
        
        await _simulateVoice(mockResponse);
        _resetToIdleAndRestart();
      }
      
    } catch (e) {
      print("❌ Error processing input: $e");
      setState(() {
        _currentState = VoiceState.error;
        _currentStatus = "Oops! Something went wrong. Restarting...";
      });
      
      Timer(Duration(seconds: 2), () {
        _resetToIdleAndRestart();
      });
    }
  }

  // 🌐 Backend API Call WITH MEMORY SUPPORT
  Future<Map<String, dynamic>?> _callBackendAPIWithMemory(String userText) async {
    try {
      if (_persistentUserId == null) {
        print("❌ No persistent user ID available");
        return null;
      }

      final flatHistory = <Map<String, String>>[];
      for (final entry in (_conversationHistory.length > 5 
          ? _conversationHistory.sublist(_conversationHistory.length - 5)
          : _conversationHistory)) {
        if (entry['user'] != null) {
          flatHistory.add({'role': 'user', 'content': entry['user']!});
        }
        if (entry['assistant'] != null) {
          flatHistory.add({'role': 'assistant', 'content': entry['assistant']!});
        }
      }

      final requestBody = {
        'userId': _persistentUserId,
        'personality': widget.personality,
        'userMessage': userText,
        'conversationHistory': flatHistory,
        'customMemories': _customMemories, // 🧠 ADD CUSTOM MEMORIES!
        'hasMemory': _conversationHistory.isNotEmpty,
        'totalConversations': _totalConversations,
        'responseStyle': 'conversational_short',
        'maxResponseLength': 100,
        'preferBrevity': true,
      };

      print("🌐 Sending request with memory:");
      print("   - User ID: $_persistentUserId");
      print("   - Conversation history: ${flatHistory.length} messages");
      print("   - Total conversations: $_totalConversations");
      print("   - Custom memories: ${_customMemories.length} entries");

      final response = await http.post(
        Uri.parse('${widget.baseUrl}/voice-conversation/text-only'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ Backend response received with memory support");
        return data;
      } else {
        print("❌ Backend error: ${response.statusCode}");
        print("❌ Response: ${response.body}");
        return null;
      }

    } catch (e) {
      print("❌ Network error: $e");
      return null;
    }
  }

  // 🎵 Play ElevenLabs Audio (UPDATED for auto-restart)
  Future<void> _playElevenLabsAudio(String audioUrl) async {
    try {
      setState(() {
        _currentState = VoiceState.speaking;
        _currentStatus = "${widget.personality} is speaking...";
      });
      
      _thinkingController.stop();
      _speakingController.repeat(reverse: true);
      
      final base64Audio = audioUrl.split(',')[1];
      final audioBytes = base64Decode(base64Audio);
      
      print("🎵 ElevenLabs audio starting playback...");
      
      await _audioPlayer.play(BytesSource(audioBytes));
      await _audioPlayer.onPlayerComplete.first;
      
      print("✅ ElevenLabs audio playback completed");
      
      setState(() {
        _currentStatus = "Memory updated! Ready for next conversation...";
      });
      
      _resetToIdleAndRestart();
      
    } catch (e) {
      print("❌ Error playing ElevenLabs audio: $e");
      await _simulateVoice(_lastAiResponse);
    }
  }

  // 🎵 Fallback TTS (UPDATED for auto-restart)
  Future<void> _simulateVoice(String text) async {
    setState(() {
      _currentState = VoiceState.speaking;
      _currentStatus = "${widget.personality} is speaking...";
    });
    
    _thinkingController.stop();
    _speakingController.repeat(reverse: true);
    
    try {
      final cleanedText = _cleanAIResponseText(text);  // 🧹 Clean before TTS
      print("🎵 TTS speaking: '$cleanedText'");
      await _flutterTts.speak(cleanedText);
    } catch (e) {
      print("❌ TTS error: $e");
      _resetToIdleAndRestart();
    }
  }

  // 🤖 Smart Mock Response
  String _getSmartMockResponse(String userInput) {
    final input = userInput.toLowerCase();
    
    if (_conversationHistory.isNotEmpty) {
      final lastConversation = _conversationHistory.last;
      if (lastConversation['user']?.toLowerCase().contains('hello') == true ||
          lastConversation['user']?.toLowerCase().contains('hi') == true) {
        final mockResponse = "Good to see you again! What's on your mind today?";
        return _cleanAIResponseText(mockResponse);  // 🧹 Clean mock responses too
      }
    }
    
    if (input.contains('hello') || input.contains('hi')) {
      final mockResponse = _conversationHistory.isEmpty 
        ? "Hello! I'm ${widget.personality}. Great to meet you!"
        : "Welcome back! I remember our previous conversations.";
      return _cleanAIResponseText(mockResponse);  // 🧹 Clean mock responses too
    }
    
    if (input.contains('how are you')) {
      final mockResponse = _conversationHistory.isEmpty
        ? "I'm doing well and excited to get to know you!"
        : "I'm great! I've been thinking about our last conversation.";
      return _cleanAIResponseText(mockResponse);  // 🧹 Clean mock responses too
    }
    
    final mockResponse = _conversationHistory.isEmpty
      ? "That's interesting! Tell me more."
      : "Based on what we've discussed before, that's a fascinating point.";
    return _cleanAIResponseText(mockResponse);  // 🧹 Clean mock responses too
  }

  @override
  Widget build(BuildContext context) {
    final config = _personalityConfig[widget.personality]!;
    final color = config['color'] as Color;
    
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // 🧠 Memory Status Display
          if (_hasLoadedMemory && _conversationHistory.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.memory, color: color, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "💭 ${_conversationHistory.length} conversations remembered",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // 🎤 Voice Interface with Backchannel Indicator
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Voice Indicator
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseScale,
                    _listeningPulse,
                    _speakingBounce,
                    _thinkingRotation,
                    _backchannelPulse,
                  ]),
                  builder: (context, child) {
                    double scale = 1.0;
                    Widget icon = Icon(Icons.mic, size: 48, color: Colors.white);
                    Color circleColor = color;
                    
                    switch (_currentState) {
                      case VoiceState.idle:
                        scale = _pulseScale.value;
                        icon = Icon(Icons.mic, size: 48, color: Colors.white);
                        break;
                      case VoiceState.listening:
                        scale = _listeningPulse.value;
                        icon = Icon(Icons.mic, size: 48, color: Colors.white);
                        break;
                      case VoiceState.processing:
                        scale = 1.0;
                        icon = Transform.rotate(
                          angle: _thinkingRotation.value * 2 * 3.14159,
                          child: Icon(Icons.psychology, size: 48, color: Colors.white),
                        );
                        break;
                      case VoiceState.speaking:
                        scale = _speakingBounce.value;
                        icon = Icon(Icons.volume_up, size: 48, color: Colors.white);
                        break;
                      case VoiceState.backchanneling:
                        scale = _backchannelPulse.value;
                        icon = Icon(Icons.hearing, size: 48, color: Colors.white);
                        circleColor = Colors.green; // Different color for backchannel
                        break;
                      case VoiceState.error:
                        scale = 1.0;
                        icon = Icon(Icons.error_outline, size: 48, color: Colors.white);
                        break;
                    }
                    
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: circleColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: icon,
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 32),
                
                // Status Text
                Text(
                  _currentStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                
                SizedBox(height: 16),
                
                // 🎵 Backchannel Status Indicator
                if (_isBackchannelPlaying)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hearing, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Responding naturally...",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Conversation Flow Indicator
                if (_currentState == VoiceState.listening)
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hearing, color: color, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Always listening - speak naturally",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Last Response
                if (_lastAiResponse.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _lastAiResponse,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speechProcessingTimer?.cancel();
    _backchannelTimer?.cancel();
    _pulseController.dispose();
    _listeningController.dispose();
    _speakingController.dispose();
    _thinkingController.dispose();
    _backchannelController.dispose();
    _audioPlayer.dispose();
    _backchannelPlayer.dispose();
    super.dispose();
  }
}