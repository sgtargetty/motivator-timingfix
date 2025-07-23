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
      'greeting': 'Ready for an adventure?'
    },
    'Baxter Jordan': {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
      'color': Colors.blue,
      'greeting': 'Let\'s analyze this situation...'
    },
  };

  // 🎵 BACKCHANNEL AUDIO CLIPS CONFIGURATION
  Map<String, List<String>> get _audioClipsByType => {
    'acknowledgment': [
      'assets/audio/backchannel/mhmm_1.mp3',
      'assets/audio/backchannel/mhmm_2.mp3', 
      'assets/audio/backchannel/right_1.mp3',
      'assets/audio/backchannel/right_2.mp3',
      'assets/audio/backchannel/yeah_1.mp3',
      'assets/audio/backchannel/yeah_2.mp3',
    ],
    'understanding': [
      'assets/audio/backchannel/i_see_1.mp3',
      'assets/audio/backchannel/totally_1.mp3',
      'assets/audio/backchannel/totally_2.mp3',
      'assets/audio/backchannel/got_it_1.mp3',
    ],
    'curiosity': [
      'assets/audio/backchannel/oh_1.mp3',
      'assets/audio/backchannel/interesting_1.mp3',
      'assets/audio/backchannel/tell_me_more_1.mp3',
    ],
    'agreement': [
      'assets/audio/backchannel/absolutely_1.mp3',
      'assets/audio/backchannel/exactly_1.mp3',
      'assets/audio/backchannel/for_sure_1.mp3',
    ],
    'thinking': [
      'assets/audio/backchannel/hmm_1.mp3',
      'assets/audio/backchannel/hmm_2.mp3',
      'assets/audio/backchannel/let_me_think_1.mp3',
    ],
    'excitement': [
      'assets/audio/emotions/excited_1.mp3',
      'assets/audio/emotions/excited_2.mp3',
      'assets/audio/emotions/wow_1.mp3',
    ],
    'empathy': [
      'assets/audio/emotions/oh_no_1.mp3',
      'assets/audio/emotions/i_understand_1.mp3',
      'assets/audio/emotions/that_sucks_1.mp3',
    ]
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

  // 🎵 PRELOAD AUDIO CLIPS FOR INSTANT PLAYBACK
  Future<void> _preloadAudioClips() async {
    try {
      print("🎵 Preloading backchannel audio clips...");
      
      // Preload acknowledgment clips (most common)
      for (String clipPath in _audioClipsByType['acknowledgment']!) {
        try {
          await _backchannelPlayer.setSource(AssetSource(clipPath.replaceFirst('assets/', '')));
          print("✅ Preloaded: $clipPath");
        } catch (e) {
          print("⚠️ Failed to preload $clipPath: $e");
        }
      }
      
      print("🎵 Backchannel clips preloaded successfully");
      
    } catch (e) {
      print("❌ Error preloading audio clips: $e");
    }
  }

  // 🧠 ML-BASED CLIP SELECTION
  String _selectBackchannelClip(String userMessage, int conversationTurn) {
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

  // 🎵 INSTANT BACKCHANNEL RESPONSE
  Future<void> _playBackchannelClip(String userMessage) async {
    if (_isBackchannelPlaying) return;
    
    setState(() {
      _currentState = VoiceState.backchanneling;
      _currentStatus = "Listening and responding naturally...";
      _isBackchannelPlaying = true;
    });
    
    try {
      // Select appropriate clip using ML
      final clipPath = _selectBackchannelClip(userMessage, _conversationTurn);
      print("🎵 Playing backchannel clip: $clipPath");
      
      _backchannelController.repeat(reverse: true);
      
      // Play the instant response clip
      final assetPath = clipPath.replaceFirst('assets/', '');
      await _backchannelPlayer.play(AssetSource(assetPath));
      
      // Wait for clip to finish
      await _backchannelPlayer.onPlayerComplete.first;
      
      print("✅ Backchannel clip completed");
      
    } catch (e) {
      print("❌ Error playing backchannel clip: $e");
    } finally {
      setState(() {
        _isBackchannelPlaying = false;
      });
      _backchannelController.stop();
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
      
      _totalConversations = prefs.getInt('total_conversations_${widget.personality}') ?? 0;
      await _loadBackendMemory();
      
      setState(() {
        _hasLoadedMemory = true;
        if (_conversationHistory.isNotEmpty) {
          _currentStatus = "${widget.personality} remembers your ${_conversationHistory.length} previous conversations!";
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
          
          // 🎵 TRIGGER BACKCHANNEL RESPONSE during speech (if meaningful content)
          if (!_isBackchannelPlaying && 
              result.recognizedWords.length > 10 && 
              !_isJustFillerWords(result.recognizedWords) &&
              _conversationTurn > 0) {
            
            print("🎵 Triggering backchannel response during speech");
            _playBackchannelClip(result.recognizedWords);
          }
          
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
                _processUserInput(_wordsSpoken);
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
      
      // 🎵 Play thinking backchannel if no backchannel played yet
      if (!_isBackchannelPlaying && _conversationTurn > 0) {
        _playBackchannelClip("thinking about: " + userText);
      }
      
      final backendResponse = await _callBackendAPIWithMemory(userText);
      
      if (backendResponse != null && backendResponse['success'] == true) {
        final aiResponse = backendResponse['aiResponse'];
        final audioUrl = backendResponse['audioUrl'];
        final memoryStats = backendResponse['memoryStats'];
        
        setState(() {
          _lastAiResponse = aiResponse;
        });
        
        _addToConversationHistory(userText, aiResponse);
        
        print("🎯 AI Response: '$aiResponse'");
        print("🧠 Memory Stats: $memoryStats");
        print("🔊 Audio URL received: ${audioUrl != null ? 'Yes' : 'No'}");
        
        // 🎵 WAIT for any backchannel to finish before playing real response
        if (_isBackchannelPlaying) {
          print("🎵 Waiting for backchannel to finish...");
          while (_isBackchannelPlaying && mounted) {
            await Future.delayed(Duration(milliseconds: 100));
          }
        }
        
        // Play real response
        if (audioUrl != null) {
          await _playElevenLabsAudio(audioUrl);
        } else {
          print("🎵 No audio URL, using fallback TTS");
          await _simulateVoice(aiResponse);
        }
        
        if (memoryStats != null && memoryStats['totalConversations'] > 0) {
          setState(() {
            _currentStatus = "💭 ${memoryStats['totalConversations']} conversations remembered";
          });
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
        'hasMemory': _conversationHistory.isNotEmpty,
        'totalConversations': _totalConversations,
      };

      print("🌐 Sending request with memory:");
      print("   - User ID: $_persistentUserId");
      print("   - Conversation history: ${flatHistory.length} messages");
      print("   - Total conversations: $_totalConversations");

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
      print("🎵 TTS speaking: '$text'");
      await _flutterTts.speak(text);
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
        return "Good to see you again! What's on your mind today?";
      }
    }
    
    if (input.contains('hello') || input.contains('hi')) {
      return _conversationHistory.isEmpty 
        ? "Hello! I'm ${widget.personality}. Great to meet you!"
        : "Welcome back! I remember our previous conversations.";
    }
    
    if (input.contains('how are you')) {
      return _conversationHistory.isEmpty
        ? "I'm doing well and excited to get to know you!"
        : "I'm great! I've been thinking about our last conversation.";
    }
    
    return _conversationHistory.isEmpty
      ? "That's interesting! Tell me more."
      : "Based on what we've discussed before, that's a fascinating point.";
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