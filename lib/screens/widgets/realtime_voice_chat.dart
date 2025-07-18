// lib/screens/widgets/realtime_voice_chat.dart
// FIXED: Simple mic button version with API and audio fixes
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

// 🚥 Pipeline State
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
  
  // 🔊 Audio
  late AudioPlayer _audioPlayer;
  late FlutterTts _flutterTts;
  StreamSubscription? _audioSubscription; // Track audio completion
  
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
      'color': Colors.amber,
    },
    'Baxter Jordan': {
      'voiceId': 'pNInz6obpgDQGcFmaJgB',
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

  // 🎤 Initialize Speech Recognition
  Future<void> _initializeVoiceChat() async {
    _speechToText = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
    
    // Configure TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);
    
    // 🔧 FIX: Better TTS completion handling
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
      _currentStatus = "Speech error. Try again.";
    });
    _resetToIdle();
  }

  // 🎙️ FIXED: Voice Input Handling
  Future<void> _toggleListening() async {
    if (!_speechEnabled) return;

    // 🔧 FIX: Prevent multiple taps during processing
    if (_currentState == VoiceState.processing || _currentState == VoiceState.speaking) {
      print("⚠️ Already processing, ignoring tap");
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
        listenFor: Duration(seconds: 12),
        pauseFor: Duration(seconds: 2),
        partialResults: true,
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

  // 🧠 Process User Input
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
      
      // Get AI response from backend
      final backendResponse = await _callBackendAPI(userText);
      
      if (backendResponse != null && backendResponse['success'] == true) {
        final aiResponse = backendResponse['aiResponse'];
        final audioUrl = backendResponse['audioUrl'];
        
        setState(() {
          _lastAiResponse = aiResponse;
        });
        
        print("🎯 AI Response: '$aiResponse'");
        print("🔊 Audio URL received: ${audioUrl != null ? 'Yes' : 'No'}");
        
        // Play real ElevenLabs voice or fallback to TTS
        if (audioUrl != null) {
          await _playElevenLabsAudio(audioUrl);
        } else {
          print("🎵 No audio URL, using fallback TTS");
          await _simulateVoice(aiResponse);
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

  // 🤖 FIXED: Call Backend API
  Future<Map<String, dynamic>?> _callBackendAPI(String userText) async {
    try {
      // 🔧 FIX: Backend expects 'userMessage' parameter
      final requestBody = {
        'userId': widget.userId,
        'personality': widget.personality,
        'userMessage': userText, // ✅ CORRECT: Backend expects userMessage
      };

      print("📡 Request: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse('https://motivator-ai-backend.onrender.com/voice-conversation/text-only'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Backend API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("❌ Backend API error: $e");
      return null;
    }
  }

  // 🧠 Smart Mock Responses (unchanged - working fine)
  String _getSmartMockResponse(String userText) {
    final text = userText.toLowerCase();
    
    if (text.contains('how') && (text.contains('going') || text.contains('doing'))) {
      return "Going great! Ready to tackle some epic challenges together!";
    } else if (text.contains('hello') || text.contains('hi')) {
      return "Hey there, adventurer! What's our next mission?";
    } else if (text.contains('help') || text.contains('stuck')) {
      return "No mountain too high! Let's break this down step by step.";
    } else if (text.contains('tired') || text.contains('exhausted')) {
      return "Rest is part of the journey, but you've got more strength than you know!";
    } else if (text.contains('thanks') || text.contains('thank')) {
      return "That's what adventure partners are for! What's next?";
    } else {
      final responses = [
        "Love that energy! Tell me more about what you're working on.",
        "You're speaking my language! Let's dive deeper into this challenge.",
        "Now we're talking! What's the biggest obstacle you're facing?",
        "I can hear the determination in your voice! What's your next move?",
        "That's the explorer spirit I love! How can we push this further?"
      ];
      return responses[math.Random().nextInt(responses.length)];
    }
  }

  // 🔊 FIXED: Play Real ElevenLabs Audio
  Future<void> _playElevenLabsAudio(String audioUrl) async {
    print("🎵 Playing ElevenLabs audio...");
    
    setState(() {
      _currentState = VoiceState.speaking;
      _currentStatus = "${widget.personality}: $_lastAiResponse";
    });

    _thinkingController.stop();
    _speakingController.repeat(reverse: true);
    HapticFeedback.selectionClick();

    try {
      // 🔧 FIX: Properly handle base64 audio data
      if (audioUrl.startsWith('data:audio/mpeg;base64,')) {
        final base64Audio = audioUrl.split(',')[1];
        final audioBytes = base64Decode(base64Audio);
        await _playAudioFromBytes(audioBytes);
      } else {
        throw Exception('Invalid audio format');
      }
      
    } catch (e) {
      print("❌ ElevenLabs audio playback error: $e");
      // Fallback to TTS
      await _simulateVoice(_lastAiResponse);
    }
  }

  // 🔊 FIXED: Play Audio from Bytes
  Future<void> _playAudioFromBytes(Uint8List audioBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
      
      await tempFile.writeAsBytes(audioBytes);
      await _audioPlayer.setFilePath(tempFile.path);
      
      print("🎵 ElevenLabs audio started playing");
      
      // 🔧 FIX: Better audio completion handling
      _audioSubscription?.cancel();
      _audioSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          print("✅ ElevenLabs audio playback completed");
          _speakingController.stop();
          tempFile.delete().catchError((_) {}); // Clean up
          _resetToIdle();
        }
      });
      
      await _audioPlayer.play();
      
    } catch (e) {
      print("❌ Audio playback error: $e");
      _speakingController.stop();
      _resetToIdle();
    }
  }

  // 🔊 Fallback: Device TTS when ElevenLabs fails
  Future<void> _simulateVoice(String text) async {
    print("🎵 Using fallback TTS for: '$text'");
    
    setState(() {
      _currentState = VoiceState.speaking;
      _currentStatus = "${widget.personality}: $text";
    });

    _thinkingController.stop();
    _speakingController.repeat(reverse: true);
    HapticFeedback.selectionClick();

    try {
      await _flutterTts.speak(text);
      print("🎵 Fallback TTS started speaking");
      
    } catch (e) {
      print("❌ TTS fallback error: $e");
      // Final fallback - timed simulation
      final durationSeconds = math.max(2, (text.length / 10).round());
      await Future.delayed(Duration(seconds: durationSeconds));
      _speakingController.stop();
      _resetToIdle();
    }
  }

  // 🔧 FIXED: Reset to Idle
  void _resetToIdle() {
    if (!mounted) return;
    
    setState(() {
      _currentState = VoiceState.idle;
      _currentStatus = "Tap to continue conversation";
      _isListening = false;
    });
    
    // Clean up animations
    _listeningController.stop();
    _speakingController.stop();
    _thinkingController.stop();
    _audioSubscription?.cancel();
    
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
    _flutterTts.stop();
    _audioSubscription?.cancel();
    
    _pulseController.dispose();
    _listeningController.dispose();
    _speakingController.dispose();
    _thinkingController.dispose();
    
    super.dispose();
  }

  // 🎨 UI Build Method (unchanged - working fine)
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
                    "Exchanges: ${_conversationHistory.length ~/ 2}",
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

  // Helper Methods for UI (unchanged - working fine)
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