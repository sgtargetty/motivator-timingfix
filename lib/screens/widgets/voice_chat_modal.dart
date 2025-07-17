// lib/screens/widgets/voice_chat_modal.dart - ChatGPT Voice Style
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';

class VoiceChatModal extends StatefulWidget {
  final String personality;
  final String userId;
  
  const VoiceChatModal({
    Key? key,
    required this.personality,
    required this.userId,
  }) : super(key: key);

  @override
  _VoiceChatModalState createState() => _VoiceChatModalState();
}

class _VoiceChatModalState extends State<VoiceChatModal>
    with TickerProviderStateMixin {
  
  // 🎤 Audio Recording & Playback
  FlutterSoundRecorder? _audioRecord;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecorderInitialized = false;
  
  // 🎭 Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _listeningController; 
  late AnimationController _thinkingController;
  late AnimationController _speakingController;
  
  // 🎨 Animations
  late Animation<double> _pulseScale;
  late Animation<double> _listeningPulse;
  late Animation<double> _thinkingRotation;
  late Animation<double> _speakingBounce;
  late Animation<Color?> _bubbleColor;

  // 💬 Conversation State
  String? _conversationId;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _aiIsSpeaking = false;
  String _recordingPath = '';
  String _currentStatus = '';
  
  // 🎵 Visual State
  List<double> _waveHeights = List.generate(12, (index) => 0.2);
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRecorder();
    _currentStatus = "Ready to chat with ${widget.personality}";
  }

  void _initializeAnimations() {
    // Main pulse animation (always running)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Listening animation
    _listeningController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Thinking animation  
    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Speaking animation
    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Pulse scale animation
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Listening pulse
    _listeningPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _listeningController, curve: Curves.easeInOut),
    );
    
    // Thinking rotation
    _thinkingRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _thinkingController,
    );
    
    // Speaking bounce
    _speakingBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _speakingController, curve: Curves.elasticOut),
    );
    
    // Bubble color animation
    _bubbleColor = ColorTween(
      begin: Color(0xFFFFD700),
      end: Color(0xFF64FFDA),
    ).animate(_pulseController);

    // Start continuous pulse
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeRecorder() async {
    try {
      _audioRecord = FlutterSoundRecorder();
      final status = await Permission.microphone.request();
      if (status == PermissionStatus.granted) {
        await _audioRecord!.openRecorder();
        setState(() {
          _isRecorderInitialized = true;
        });
        print("🎤 Audio recorder initialized");
      }
    } catch (e) {
      print("❌ Recorder init error: $e");
      setState(() {
        _currentStatus = "Microphone permission needed";
      });
    }
  }

  // 🎤 RECORDING FUNCTIONS
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized || _isRecording || _isProcessing) return;
    
    try {
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _audioRecord!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacMP4,
      );
      
      setState(() {
        _isRecording = true;
        _currentStatus = "Listening...";
      });
      
      _listeningController.repeat(reverse: true);
      _startWaveAnimation();
      HapticFeedback.mediumImpact();
      
    } catch (e) {
      print("❌ Recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    try {
      await _audioRecord!.stopRecorder();
      _listeningController.stop();
      _stopWaveAnimation();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _currentStatus = "${widget.personality} is thinking...";
      });

      _thinkingController.repeat();
      HapticFeedback.lightImpact();
      
      if (_recordingPath.isNotEmpty) {
        await _sendVoiceMessage(_recordingPath);
      }
      
    } catch (e) {
      print("❌ Stop recording error: $e");
      _resetState();
    }
  }

  void _startWaveAnimation() {
    // Animate wave heights for visual feedback
    for (int i = 0; i < _waveHeights.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (_isRecording && mounted) {
          setState(() {
            _waveHeights[i] = 0.3 + (math.Random().nextDouble() * 0.7);
          });
        }
      });
    }
    
    if (_isRecording) {
      Future.delayed(Duration(milliseconds: 200), _startWaveAnimation);
    }
  }

  void _stopWaveAnimation() {
    setState(() {
      _waveHeights = List.generate(12, (index) => 0.2);
    });
  }

  // 🧠 AI CONVERSATION
  Future<void> _sendVoiceMessage(String audioPath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://motivator-ai-backend.onrender.com/voice-conversation/voice-message'),
      );
      
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      request.fields['userId'] = widget.userId;
      request.fields['personality'] = widget.personality;
      if (_conversationId != null) {
        request.fields['conversationId'] = _conversationId!;
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _handleAIResponse(data);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
      
    } catch (e) {
      print("❌ Voice message error: $e");
      setState(() {
        _currentStatus = "Sorry, connection failed. Try again.";
      });
      _resetState();
    }
  }

  Future<void> _handleAIResponse(Map<String, dynamic> data) async {
    try {
      _thinkingController.stop();
      
      final aiResponse = data['aiResponse'];
      if (data['conversationId'] != null) {
        _conversationId = data['conversationId'];
      }
      
      setState(() {
        _isProcessing = false;
        _aiIsSpeaking = true;
        _currentStatus = "${widget.personality} is speaking...";
      });
      
      _speakingController.repeat(reverse: true);
      
      // For now, simulate AI speaking (since audio serving isn't implemented yet)
      await _simulateAISpeaking(aiResponse);
      
    } catch (e) {
      print("❌ Handle AI response error: $e");
      _resetState();
    }
  }

  Future<void> _simulateAISpeaking(String text) async {
    // Simulate speaking duration based on text length
    final speakingDuration = Duration(milliseconds: (text.length * 80).clamp(2000, 8000));
    
    await Future.delayed(speakingDuration);
    
    _speakingController.stop();
    setState(() {
      _aiIsSpeaking = false;
      _currentStatus = "Ready to chat with ${widget.personality}";
    });
  }

  void _resetState() {
    _thinkingController.stop();
    _listeningController.stop();
    _speakingController.stop();
    
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _aiIsSpeaking = false;
      _currentStatus = "Ready to chat with ${widget.personality}";
    });
  }

  // 🎨 UI BUILD METHODS
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1419),
              Color(0xFF1A1F2E),
              Color(0xFF0F1419),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildChatGPTVoiceInterface()),
              _buildVoiceControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.personality,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "AI Voice Assistant",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatGPTVoiceInterface() {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main AI Bubble (ChatGPT Style)
            AnimatedBuilder(
              animation: Listenable.merge([
                _pulseScale,
                _listeningPulse,
                _speakingBounce,
                _thinkingRotation,
                _bubbleColor,
              ]),
              builder: (context, child) {
                double scale = _pulseScale.value;
                if (_isRecording) scale *= _listeningPulse.value;
                if (_aiIsSpeaking) scale *= _speakingBounce.value;
                
                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: _isProcessing ? _thinkingRotation.value * 2 * math.pi : 0,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _getBubbleColor().withOpacity(0.9),
                            _getBubbleColor().withOpacity(0.4),
                            _getBubbleColor().withOpacity(0.1),
                          ],
                          stops: [0.3, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getBubbleColor().withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getBubbleColor(),
                        ),
                        child: Icon(
                          _getBubbleIcon(),
                          color: Colors.black,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 50),
            
            // Wave Visualization
            if (_isRecording || _aiIsSpeaking) _buildWaveVisualization(),
            
            SizedBox(height: 30),
            
            // Status Text
            Text(
              _currentStatus,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 10),
            
            // Subtitle
            Text(
              _getSubtitle(),
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveVisualization() {
    return Container(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_waveHeights.length, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 3,
            height: 60 * _waveHeights[index],
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _isRecording 
                ? Color(0xFF64FFDA) 
                : Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          // Main Voice Button
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () => _stopRecording(),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: _isRecording ? 100 : 80,
              height: _isRecording ? 100 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getControlButtonColor(),
                boxShadow: [
                  BoxShadow(
                    color: _getControlButtonColor().withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: _isRecording ? 15 : 8,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none_rounded,
                color: Colors.white,
                size: _isRecording ? 45 : 35,
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          Text(
            _getControlText(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 HELPER METHODS
  Color _getBubbleColor() {
    if (_isProcessing) return Color(0xFFFF6B6B);
    if (_isRecording) return Color(0xFF64FFDA);
    if (_aiIsSpeaking) return Color(0xFF9C27B0);
    return Color(0xFFFFD700);
  }

  IconData _getBubbleIcon() {
    if (_isProcessing) return Icons.psychology_rounded;
    if (_isRecording) return Icons.hearing_rounded;
    if (_aiIsSpeaking) return Icons.volume_up_rounded;
    return Icons.chat_bubble_rounded;
  }

  Color _getControlButtonColor() {
    if (_isProcessing) return Color(0xFF666666);
    if (_isRecording) return Color(0xFFFF4444);
    return Color(0xFF64FFDA);
  }

  String _getControlText() {
    if (_isProcessing) return "Processing...";
    if (_isRecording) return "Release to send";
    return "Hold to speak";
  }

  String _getSubtitle() {
    if (_isProcessing) return "Analyzing your message...";
    if (_isRecording) return "Speak now";
    if (_aiIsSpeaking) return "Listen carefully";
    return "Tap and hold the button to start";
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _listeningController.dispose();
    _thinkingController.dispose();
    _speakingController.dispose();
    _audioRecord?.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }
}