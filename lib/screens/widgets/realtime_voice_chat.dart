// lib/screens/widgets/realtime_voice_chat.dart - FIXED VERSION (No Compilation Errors)

import 'dart:convert';
import 'dart:typed_data';
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
  
  late Animation<double> _pulseScale;
  late Animation<double> _listeningPulse;
  late Animation<double> _speakingBounce;
  late Animation<double> _thinkingRotation;
  
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

  @override
  void initState() {
    super.initState();
    _initializeVoiceChat();
    _setupAnimations();
    _loadPersistentMemory(); // Load memory on startup
  }

  // 🧠 PERSISTENT MEMORY MANAGEMENT
  Future<void> _loadPersistentMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get or create persistent user ID
      _persistentUserId = prefs.getString('persistent_user_id');
      if (_persistentUserId == null) {
        _persistentUserId = const Uuid().v4();
        await prefs.setString('persistent_user_id', _persistentUserId!);
        print("🆔 Created new persistent user ID: $_persistentUserId");
      } else {
        print("🆔 Loaded existing user ID: $_persistentUserId");
      }
      
      // Load conversation history
      final historyJson = prefs.getString('conversation_history_${widget.personality}');
      if (historyJson != null) {
        final historyList = json.decode(historyJson) as List;
        _conversationHistory = historyList.map((item) => 
          Map<String, String>.from(item)).toList();
        
        // Keep only last 20 conversations to prevent memory bloat
        if (_conversationHistory.length > 20) {
          _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
          await _savePersistentMemory();
        }
        
        print("📚 Loaded ${_conversationHistory.length} previous conversations");
      }
      
      // Load total conversation count
      _totalConversations = prefs.getInt('total_conversations_${widget.personality}') ?? 0;
      
      // Load backend memory stats
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
      
      // Save conversation history
      await prefs.setString(
        'conversation_history_${widget.personality}',
        json.encode(_conversationHistory)
      );
      
      // Save total conversation count
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
          print("   - Favorite topics: ${stats['favoriteTopics']}");
          
          // Update local state with backend data
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
      
      // Keep only last 20 conversations in memory
      if (_conversationHistory.length > 20) {
        _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
      }
    });
    
    // Save to persistent storage
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
  }

  Future<void> _initializeVoiceChat() async {
    _speechToText = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      print("🎵 TTS completed");
      if (mounted) {
        _resetToIdle();
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
        _currentStatus = "Listening... speak now!";
      });
      _listeningController.repeat(reverse: true);
    }
  }

  void _onSpeechError(dynamic error) {
    print("❌ Speech error: $error");
    setState(() {
      _currentState = VoiceState.error;
      _currentStatus = "Didn't catch that. Tap to try again!";
    });
    _resetToIdle();
  }

  // 🎤 Start Listening
  Future<void> _startListening() async {
    if (!_speechEnabled || _currentState != VoiceState.idle) return;

    try {
      setState(() {
        _currentState = VoiceState.listening;
        _currentStatus = "Listening... speak now!";
        _wordsSpoken = "";
      });

      HapticFeedback.lightImpact();
      _pulseController.stop();
      _listeningController.repeat(reverse: true);

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _wordsSpoken = result.recognizedWords;
            _confidenceLevel = result.confidence;
          });
          
          if (result.finalResult && !_isCurrentlyProcessing && _wordsSpoken != _lastProcessedText) {
            _isCurrentlyProcessing = true;
            _lastProcessedText = _wordsSpoken;
            _processUserInput(_wordsSpoken);
          }
        },
        listenFor: Duration(seconds: 12),
        pauseFor: Duration(seconds: 4),
        partialResults: true,
        localeId: "en_US",
        cancelOnError: true,
      );

    } catch (e) {
      print("❌ Error starting listening: $e");
      setState(() {
        _currentState = VoiceState.error;
        _currentStatus = "Error starting voice recognition. Try again!";
      });
      _resetToIdle();
    }
  }

  Future<void> _stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
        setState(() {
          _currentStatus = "Processing what you said...";
        });
        _resetToIdle();
      }
    } catch (e) {
      print("❌ Error stopping listening: $e");
      _resetToIdle();
    }
  }

  // 🧠 Process User Input WITH MEMORY
  Future<void> _processUserInput(String userText) async {
    if (userText.trim().isEmpty) {
      _resetToIdle();
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
      
      // Call backend with conversation history and persistent user ID
      final backendResponse = await _callBackendAPIWithMemory(userText);
      
      if (backendResponse != null && backendResponse['success'] == true) {
        final aiResponse = backendResponse['aiResponse'];
        final audioUrl = backendResponse['audioUrl'];
        final memoryStats = backendResponse['memoryStats'];
        
        setState(() {
          _lastAiResponse = aiResponse;
        });
        
        // Add to conversation history
        _addToConversationHistory(userText, aiResponse);
        
        print("🎯 AI Response: '$aiResponse'");
        print("🧠 Memory Stats: $memoryStats");
        print("🔊 Audio URL received: ${audioUrl != null ? 'Yes' : 'No'}");
        
        // Play real ElevenLabs voice or fallback to TTS
        if (audioUrl != null) {
          await _playElevenLabsAudio(audioUrl);
        } else {
          print("🎵 No audio URL, using fallback TTS");
          await _simulateVoice(aiResponse);
        }
        
        // Update status with memory info
        if (memoryStats != null && memoryStats['totalConversations'] > 0) {
          setState(() {
            _currentStatus = "💭 ${memoryStats['totalConversations']} conversations remembered";
          });
        }
        
      } else {
        // Fallback to mock response
        print("🎯 Backend failed, using smart mock response");
        final mockResponse = _getSmartMockResponse(userText);
        
        setState(() {
          _lastAiResponse = mockResponse;
        });
        
        await _simulateVoice(mockResponse);
      }
      _isCurrentlyProcessing = false; // Reset processing flag
    } catch (e) {
      print("❌ Error processing input: $e");
      setState(() {
        _currentState = VoiceState.error;
        _currentStatus = "Oops! Something went wrong. Try again.";
      });
      _resetToIdle();
    }
  }

  // 🌐 Backend API Call WITH MEMORY SUPPORT
  Future<Map<String, dynamic>?> _callBackendAPIWithMemory(String userText) async {
    try {
      if (_persistentUserId == null) {
        print("❌ No persistent user ID available");
        return null;
      }

      // Prepare conversation history for backend (last 10 messages)
      final recentHistory = _conversationHistory.length > 10 
          ? _conversationHistory.sublist(_conversationHistory.length - 10)
          : _conversationHistory;
      
      // Flatten conversation history properly
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
        'conversationHistory': flatHistory,  // Send conversation history
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

  // 🎵 Play ElevenLabs Audio
  Future<void> _playElevenLabsAudio(String audioUrl) async {
    try {
      setState(() {
        _currentState = VoiceState.speaking;
        _currentStatus = "${widget.personality} is speaking...";
      });
      
      _thinkingController.stop();
      _speakingController.repeat(reverse: true);
      
      // Decode base64 audio
      final base64Audio = audioUrl.split(',')[1];
      final audioBytes = base64Decode(base64Audio);
      
      print("🎵 ElevenLabs audio starting playback...");
      
      // Play audio once
      await _audioPlayer.play(BytesSource(audioBytes));

      // Wait for playback to complete
      await _audioPlayer.onPlayerComplete.first;
      
      print("✅ ElevenLabs audio playback completed");
      
      setState(() {
        _currentStatus = "Memory updated! Tap to continue...";
      });
      
      _resetToIdle();
      
    } catch (e) {
      print("❌ Error playing ElevenLabs audio: $e");
      // Fallback to TTS
      await _simulateVoice(_lastAiResponse);
    }
  }

  // 🎵 Fallback TTS
  Future<void> _simulateVoice(String text) async {
    setState(() {
      _currentState = VoiceState.speaking;
      _currentStatus = "${widget.personality} is speaking...";
    });
    
    _thinkingController.stop();
    _speakingController.repeat(reverse: true);
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print("❌ TTS error: $e");
      _resetToIdle();
    }
  }

  // 🤖 Smart Mock Response
  String _getSmartMockResponse(String userInput) {
    final input = userInput.toLowerCase();
    
    // Use memory-aware responses
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
    
    if (input.contains('remember') || input.contains('recall')) {
      return _conversationHistory.isEmpty
        ? "This is our first conversation, but I'll remember everything we discuss!"
        : "Absolutely! I remember our ${_conversationHistory.length} previous conversations.";
    }
    
    return _conversationHistory.isEmpty
      ? "That's interesting! Tell me more - I'm building my memory of our conversations."
      : "Based on what we've discussed before, that's a fascinating point.";
  }

  void _resetToIdle() {
    setState(() {
      _currentState = VoiceState.idle;
      if (!_hasLoadedMemory) {
        _currentStatus = "Loading your memory...";
      } else if (_conversationHistory.isNotEmpty) {
        _currentStatus = "💭 ${_conversationHistory.length} conversations remembered. Tap to continue!";
      } else {
        _currentStatus = "Tap to start your first conversation!";
      }
    });
    
    _pulseController.repeat(reverse: true);
    _listeningController.stop();
    _speakingController.stop();
    _thinkingController.stop();
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
          
          // Voice Interface
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Voice Button
                GestureDetector(
                  onTap: _currentState == VoiceState.idle ? _startListening : _stopListening,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _pulseScale,
                      _listeningPulse,
                      _speakingBounce,
                      _thinkingRotation,
                    ]),
                    builder: (context, child) {
                      double scale = 1.0;
                      Widget icon = Icon(Icons.mic, size: 48, color: Colors.white);
                      
                      switch (_currentState) {
                        case VoiceState.idle:
                          scale = _pulseScale.value;
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
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
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
    _pulseController.dispose();
    _listeningController.dispose();
    _speakingController.dispose();
    _thinkingController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}