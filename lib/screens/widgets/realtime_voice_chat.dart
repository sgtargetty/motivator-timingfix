// lib/screens/widgets/realtime_voice_chat.dart
// Real-time Voice Chat - ChatGPT Voice Mode Implementation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;

// 🚥 Pipeline State - MUST be outside class
enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error
}

class RealTimeVoiceChat extends StatefulWidget {
  final String personality;
  final String userId;
  
  const RealTimeVoiceChat({
    Key? key,
    required this.personality,
    required this.userId,
  }) : super(key: key);

  @override
  _RealTimeVoiceChatState createState() => _RealTimeVoiceChatState();
}

class _RealTimeVoiceChatState extends State<RealTimeVoiceChat>
    with TickerProviderStateMixin {
  
  // 🎤 Speech Recognition
  late stt.SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _wordsSpoken = "";
  double _confidence = 0.0;
  
  // 🔊 Audio Streaming
  late AudioPlayer _audioPlayer;
  WebSocketChannel? _elevenLabsChannel;
  StreamController<List<int>>? _audioStreamController;
  
  // 🎭 UI Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _listeningController;
  late AnimationController _speakingController;
  late AnimationController _thinkingController;
  
  // 🎨 Animations
  late Animation<double> _pulseScale;
  late Animation<double> _listeningPulse;
  late Animation<double> _speakingBounce;
  late Animation<double> _thinkingRotation;
  
  // 🧠 Conversation State
  String _currentStatus = "Ready to chat!";
  String _lastAiResponse = "";
  List<Map<String, String>> _conversationHistory = [];
  
  VoiceState _currentState = VoiceState.idle;

  // 🎭 Personality Configurations
  Map<String, Map<String, dynamic>> get _personalityConfig => {
    'Lana Croft': {
      'voiceId': 'QXEkTn58Ik1IKjIMk8QA',
      'systemPrompt': '''You are Lana Croft, an adventurous, confident AI motivation coach. 
      
      PERSONALITY: Adventurous explorer with fearless, encouraging spirit
      STYLE: Use adventure/exploration metaphors, be bold but supportive
      VOICE: Keep responses SHORT (10-25 words) for natural conversation
      PHRASES: "Ready for this adventure?", "Let's conquer this!", "You've got explorer spirit!"
      
      CRITICAL: This is VOICE conversation - be conversational, brief, and energetic!''',
      'color': Colors.amber,
    },
    'Baxter Jordan': {
      'voiceId': 'pNInz6obpgDQGcFmaJgB', // Replace with actual Baxter voice ID
      'systemPrompt': '''You are Baxter Jordan, an analytical, data-driven coach.
      
      PERSONALITY: Strategic, insightful, performance-focused
      STYLE: Use metrics and optimization language, be precise but encouraging
      VOICE: Keep responses SHORT (10-25 words) for natural conversation
      PHRASES: "Let's optimize this", "Data shows...", "Strategic approach here"
      
      CRITICAL: This is VOICE conversation - be conversational, brief, and analytical!''',
      'color': Colors.blue,
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeVoiceChat();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Pulse for idle state
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Listening animation
    _listeningController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _listeningPulse = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _listeningController, curve: Curves.easeInOut),
    );
    
    // Speaking animation
    _speakingController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _speakingBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _speakingController, curve: Curves.elasticOut),
    );
    
    // Thinking animation
    _thinkingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _thinkingRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _thinkingController, curve: Curves.linear),
    );
  }

  // 🎤 PHASE 1: Initialize Speech Recognition
  Future<void> _initializeVoiceChat() async {
    _speechToText = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
    
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (val) => _onSpeechStatus(val),
        onError: (val) => _onSpeechError(val),
        debugLogging: true,
      );
      
      if (_speechEnabled) {
        setState(() {
          _currentStatus = "Tap to start talking with ${widget.personality}!";
        });
        _pulseController.repeat(reverse: true);
      } else {
        throw Exception('Speech recognition not available');
      }
    } catch (e) {
      print("❌ Speech initialization error: $e");
      setState(() {
        _currentStatus = "Voice setup failed. Check permissions.";
        _currentState = VoiceState.error;
      });
    }
  }

  void _onSpeechStatus(String status) {
    print("🎤 Speech status: $status");
    if (status == "done" && _currentState == VoiceState.listening) {
      _processUserInput(_wordsSpoken);
    } else if (status == "listening") {
      setState(() {
        _currentStatus = "Listening... Say something!";
      });
    }
  }

  void _onSpeechError(dynamic error) {
    print("❌ Speech error: $error");
    setState(() {
      _currentState = VoiceState.error;
      _currentStatus = "Speech error: ${error.errorMsg ?? 'Unknown error'}";
    });
    _resetToIdle();
  }

  // 🎙️ PHASE 2: Voice Input Handling
  Future<void> _toggleListening() async {
    if (!_speechEnabled) {
      print("❌ Speech not enabled");
      return;
    }

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      HapticFeedback.lightImpact();
      
      setState(() {
        _isListening = true;
        _currentState = VoiceState.listening;
        _currentStatus = "Listening...";
        _wordsSpoken = "";
        _confidence = 0.0;
      });

      _pulseController.stop();
      _listeningController.repeat(reverse: true);
      
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _wordsSpoken = result.recognizedWords;
            _confidence = result.confidence;
            _currentStatus = _wordsSpoken.isEmpty 
                ? "Listening..." 
                : '"$_wordsSpoken"';
          });
        },
        listenFor: Duration(seconds: 8),   // Stop after 8 seconds
        pauseFor: Duration(seconds: 2),    // Process after 2 seconds of silence
        partialResults: true,              // Show real-time transcription
        localeId: "en_US",
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      print("❌ Error starting listening: $e");
      _resetToIdle();
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
      _listeningController.stop();
      
      setState(() {
        _isListening = false;
      });
      
      if (_wordsSpoken.isNotEmpty && _confidence > 0.3) {
        _processUserInput(_wordsSpoken);
      } else {
        setState(() {
          _currentStatus = "Didn't catch that. Try again!";
        });
        _resetToIdle();
      }
    } catch (e) {
      print("❌ Error stopping listening: $e");
      _resetToIdle();
    }
  }

  // 🧠 PHASE 3: Process User Input with OpenAI
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
      
      // Add user message to history
      _conversationHistory.add({
        "role": "user", 
        "content": userText
      });

      // Keep conversation manageable (last 8 messages)
      if (_conversationHistory.length > 8) {
        _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 8);
      }

      // Get personality config
      final config = _personalityConfig[widget.personality] ?? _personalityConfig['Lana Croft']!;
      
      // Prepare messages for OpenAI
      List<Map<String, String>> messages = [
        {
          "role": "system",
          "content": config['systemPrompt'] as String
        },
        ..._conversationHistory,
      ];

      // Call OpenAI API
      final aiResponse = await _callOpenAI(messages);
      
      if (aiResponse != null && aiResponse.isNotEmpty) {
        _conversationHistory.add({
          "role": "assistant",
          "content": aiResponse
        });
        
        setState(() {
          _lastAiResponse = aiResponse;
        });
        
        // Start voice generation and playback
        await _generateAndPlayVoice(aiResponse, config['voiceId'] as String);
      } else {
        throw Exception("Empty response from OpenAI");
      }

    } catch (e) {
      print("❌ Error processing input: $e");
      setState(() {
        _currentState = VoiceState.error;
        _currentStatus = "Oops! Something went wrong. Try again.";
      });
      
      _thinkingController.stop();
      Future.delayed(Duration(seconds: 2), _resetToIdle);
    }
  }

  // 🤖 OpenAI API Call
  Future<String?> _callOpenAI(List<Map<String, String>> messages) async {
    // TODO: Replace with your actual OpenAI API key
    const apiKey = 'sk-your-openai-key-here'; // Replace this with your key
    
    if (apiKey == 'sk-your-openai-key-here') {
      // Return mock response for testing without API key
      await Future.delayed(Duration(seconds: 1));
      final mockResponses = [
        "Ready for this adventure!",
        "Let's conquer this challenge!",
        "You've got the explorer's spirit!",
        "Time to push beyond limits!",
        "Adventure awaits, let's go!"
      ];
      return mockResponses[math.Random().nextInt(mockResponses.length)];
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4-turbo',
          'messages': messages,
          'max_tokens': 50, // Short responses for voice
          'temperature': 0.8,
          'presence_penalty': 0.2,
          'frequency_penalty': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content']?.trim();
        print("🤖 OpenAI Response: '$content'");
        return content;
      } else {
        print("❌ OpenAI API error: ${response.statusCode} - ${response.body}");
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ OpenAI call failed: $e");
      return null;
    }
  }

  // 🔊 PHASE 4: Generate and Play Voice (ElevenLabs)
  Future<void> _generateAndPlayVoice(String text, String voiceId) async {
    // TODO: Replace with your actual ElevenLabs API key
    const elevenLabsApiKey = 'your-elevenlabs-api-key-here'; // Replace this
        
    if (elevenLabsApiKey == 'your-elevenlabs-api-key-here') {
      // Fallback to text display with audio simulation
      setState(() {
        _currentState = VoiceState.speaking;
        _currentStatus = "${widget.personality}: $_lastAiResponse";
      });

      _thinkingController.stop();
      _speakingController.repeat(reverse: true);
      HapticFeedback.selectionClick();

      // Simulate voice duration based on text length
      final durationSeconds = math.max(2, (_lastAiResponse.length / 10).round());
      
      await Future.delayed(Duration(seconds: durationSeconds));
      
      _speakingController.stop();
      _resetToIdle();
      return;
    }

    try {
      setState(() {
        _currentState = VoiceState.speaking;
        _currentStatus = "${widget.personality}: $_lastAiResponse";
      });

      _thinkingController.stop();
      _speakingController.repeat(reverse: true);
      HapticFeedback.selectionClick();

      // Use HTTP API for simplicity (WebSocket can be added later for streaming)
      final response = await http.post(
        Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': elevenLabsApiKey,
        },
        body: json.encode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.75,
            'similarity_boost': 0.85,
            'style': 0.3,
            'use_speaker_boost': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        // Play audio directly from bytes
        final audioBytes = response.bodyBytes;
        await _playAudioFromBytes(audioBytes);
      } else {
        throw Exception('ElevenLabs API error: ${response.statusCode}');
      }

    } catch (e) {
      print("❌ Voice generation error: $e");
      // Show text response if voice fails
      setState(() {
        _currentStatus = "${widget.personality}: $_lastAiResponse";
      });
      _speakingController.stop();
      Future.delayed(Duration(seconds: 3), _resetToIdle);
    }
  }

  // 🎧 Play Audio from Bytes
  Future<void> _playAudioFromBytes(Uint8List audioBytes) async {
    try {
      // Create a temporary stream from bytes
      final audioSource = AudioSource.uri(
        Uri.dataFromBytes(audioBytes, mimeType: 'audio/mpeg'),
      );
      
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
      
      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          print("✅ Audio playback completed");
          _speakingController.stop();
          _resetToIdle();
        }
      });

    } catch (e) {
      print("❌ Audio playback error: $e");
      _speakingController.stop();
      _resetToIdle();
    }
  }

  void _resetToIdle() {
    setState(() {
      _currentState = VoiceState.idle;
      _currentStatus = "Tap to continue conversation";
      _isListening = false;
    });
    
    _listeningController.stop();
    _speakingController.stop();
    _thinkingController.stop();
    
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && _currentState == VoiceState.idle) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _audioPlayer.dispose();
    _elevenLabsChannel?.sink.close();
    _audioStreamController?.close();
    
    _pulseController.dispose();
    _listeningController.dispose();
    _speakingController.dispose();
    _thinkingController.dispose();
    
    super.dispose();
  }

  // 🎨 UI Build Method
  @override
  Widget build(BuildContext context) {
    final config = _personalityConfig[widget.personality] ?? _personalityConfig['Lana Croft']!;
    final primaryColor = config['color'] as Color;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.personality} Voice Chat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Status Display
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStatus,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  if (_confidence > 0)
                    Text(
                      'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Main Voice Button
          Expanded(
            flex: 3,
            child: Center(
              child: GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: _getActiveAnimation(),
                  builder: (context, child) {
                    return Container(
                      width: 140 + (_getActiveAnimation().value * 30),
                      height: 140 + (_getActiveAnimation().value * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getColorForState().withOpacity(0.8),
                            _getColorForState().withOpacity(0.4),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getColorForState().withOpacity(0.6),
                            blurRadius: 30 + (_getActiveAnimation().value * 20),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconForState(),
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Conversation Stats
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Conversation: ${_conversationHistory.length ~/ 2} exchanges",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  if (_lastAiResponse.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      "Last: ${_lastAiResponse.length > 40 ? _lastAiResponse.substring(0, 40) + '...' : _lastAiResponse}",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods for UI
  Animation<double> _getActiveAnimation() {
    switch (_currentState) {
      case VoiceState.listening:
        return _listeningPulse;
      case VoiceState.speaking:
        return _speakingBounce;
      case VoiceState.processing:
        return _thinkingRotation;
      default:
        return _pulseScale;
    }
  }

  Color _getColorForState() {
    final config = _personalityConfig[widget.personality] ?? _personalityConfig['Lana Croft']!;
    final baseColor = config['color'] as Color;
    
    switch (_currentState) {
      case VoiceState.listening:
        return Colors.blue;
      case VoiceState.processing:
        return Colors.orange;
      case VoiceState.speaking:
        return Colors.green;
      case VoiceState.error:
        return Colors.red;
      default:
        return baseColor;
    }
  }

  IconData _getIconForState() {
    switch (_currentState) {
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.psychology;
      case VoiceState.speaking:
        return Icons.volume_up;
      case VoiceState.error:
        return Icons.error_outline;
      default:
        return Icons.mic_none;
    }
  }
}