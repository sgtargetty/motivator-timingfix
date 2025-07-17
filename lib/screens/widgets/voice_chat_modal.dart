// lib/screens/widgets/voice_chat_modal.dart - REAL AI CONVERSATIONS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ai_conversation_service.dart';

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
  final Record _audioRecord = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 🎭 UI Controllers
  late AnimationController _voiceWaveController;
  late AnimationController _listeningController;
  late AnimationController _thinkingController;
  late Animation<double> _waveAnimation;
  late Animation<double> _listeningScale;
  late Animation<double> _thinkingRotation;

  // 💬 Conversation State
  List<ConversationMessage> _messages = [];
  String? _conversationId;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _aiIsSpeaking = false;
  String _recordingPath = '';
  
  // 🎵 Voice Visualization
  List<double> _audioLevels = [0.2, 0.4, 0.6, 0.8, 0.6, 0.4, 0.2];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeConversation();
  }

  void _initializeAnimations() {
    _voiceWaveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _listeningController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _thinkingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _voiceWaveController, curve: Curves.easeInOut),
    );
    
    _listeningScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _listeningController, curve: Curves.easeInOut),
    );
    
    _thinkingRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _thinkingController,
    );

    // Start wave animation
    _voiceWaveController.repeat(reverse: true);
  }

  void _initializeConversation() {
    // Add welcome message from AI personality
    final welcomeMessage = _getWelcomeMessage();
    setState(() {
      _messages.add(ConversationMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
        personality: widget.personality,
      ));
    });
  }

  String _getWelcomeMessage() {
    switch (widget.personality) {
      case 'Lana Croft':
        return "Hey adventurer! Ready to tackle whatever's on your mind today? I'm here to help you conquer any challenge! 🗻";
      case 'Baxter Jordan':
        return "Hello! I'm here to help you optimize your approach and find strategic solutions. What would you like to work on?";
      default:
        return "Hi there! How can I motivate and support you today?";
    }
  }

  // 🎤 VOICE RECORDING FUNCTIONS
  Future<void> _startRecording() async {
    try {
      if (await _audioRecord.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordingPath = '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecord.start(
          path: _recordingPath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        
        setState(() {
          _isRecording = true;
        });
        
        _listeningController.repeat(reverse: true);
        HapticFeedback.mediumImpact();
        
        print("🎤 Recording started: $_recordingPath");
      }
    } catch (e) {
      print("❌ Recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecord.stop();
      _listeningController.stop();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      _thinkingController.repeat();
      
      if (path != null && path.isNotEmpty) {
        await _sendVoiceMessage(path);
      }
      
    } catch (e) {
      print("❌ Stop recording error: $e");
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  // 🧠 REAL AI CONVERSATION
  Future<void> _sendVoiceMessage(String audioPath) async {
    try {
      print("🚀 Sending voice message to AI...");
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://motivator-ai-backend.onrender.com/voice-conversation/voice-message'),
      );
      
      // Add audio file
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      
      // Add conversation data
      request.fields['userId'] = widget.userId;
      request.fields['personality'] = widget.personality;
      if (_conversationId != null) {
        request.fields['conversationId'] = _conversationId!;
      }
      
      // Send request
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
      _showErrorMessage("Sorry, I couldn't process that. Please try again.");
    } finally {
      _thinkingController.stop();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleAIResponse(Map<String, dynamic> data) async {
    try {
      final userMessage = data['userMessage'];
      final aiResponse = data['aiResponse'];
      final audioUrl = data['audioUrl'];
      
      // Update conversation ID
      if (data['conversationId'] != null) {
        _conversationId = data['conversationId'];
      }
      
      // Add user message to conversation
      setState(() {
        _messages.add(ConversationMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_user',
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        
        // Add AI response
        _messages.add(ConversationMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          personality: widget.personality,
          audioUrl: audioUrl,
        ));
      });
      
      // Play AI voice response
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await _playAIVoiceResponse(audioUrl);
      }
      
      // Scroll to bottom
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
      
    } catch (e) {
      print("❌ Handle AI response error: $e");
    }
  }

  Future<void> _playAIVoiceResponse(String audioUrl) async {
    try {
      setState(() {
        _aiIsSpeaking = true;
      });
      
      if (audioUrl.startsWith('data:audio')) {
        // Handle base64 audio data
        final base64Data = audioUrl.split(',')[1];
        final audioBytes = base64Decode(base64Data);
        
        // Save to temp file and play
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/ai_response_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(audioBytes);
        
        await _audioPlayer.setFilePath(tempFile.path);
      } else {
        // Handle URL
        await _audioPlayer.setUrl(audioUrl);
      }
      
      await _audioPlayer.play();
      
      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _aiIsSpeaking = false;
          });
        }
      });
      
    } catch (e) {
      print("❌ Play AI voice error: $e");
      setState(() {
        _aiIsSpeaking = false;
      });
    }
  }

  void _scrollToBottom() {
    // Implementation for scrolling to bottom of conversation
  }

  void _showErrorMessage(String message) {
    setState(() {
      _messages.add(ConversationMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_error',
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
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
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildConversation()),
              _buildVoiceControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFFFD700),
            child: Text(
              widget.personality[0],
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: Color(0xFF64FFDA),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_aiIsSpeaking) return "Speaking...";
    if (_isProcessing) return "Thinking...";
    if (_isRecording) return "Listening...";
    return "Ready to chat";
  }

  Widget _buildConversation() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ConversationMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: message.isUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: message.isError 
                ? Colors.red 
                : Color(0xFFFFD700),
              child: Icon(
                message.isError ? Icons.error : Icons.psychology,
                size: 16,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: message.isUser 
                  ? Color(0xFF64FFDA) 
                  : message.isError
                    ? Colors.red.withOpacity(0.3)
                    : Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.black : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (!message.isUser && message.audioUrl != null)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.volume_up,
                            color: Color(0xFF64FFDA),
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            "Voice response played",
                            style: TextStyle(
                              color: Color(0xFF64FFDA),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 10),
            CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFF64FFDA),
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Container(
      padding: EdgeInsets.all(30),
      child: Column(
        children: [
          // Voice visualization
          if (_isRecording || _aiIsSpeaking) _buildVoiceVisualization(),
          
          SizedBox(height: 20),
          
          // Main voice button
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () => _stopRecording(),
            child: AnimatedBuilder(
              animation: _listeningScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _listeningScale.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getButtonColor(),
                      boxShadow: [
                        BoxShadow(
                          color: _getButtonColor().withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: _isRecording ? 10 : 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getButtonIcon(),
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: 15),
          
          Text(
            _getButtonText(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceVisualization() {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_audioLevels.length, (index) {
          return AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return Container(
                width: 4,
                height: 50 * _audioLevels[index] * _waveAnimation.value,
                margin: EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF64FFDA),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Color _getButtonColor() {
    if (_isProcessing) return Color(0xFFFF6B6B);
    if (_isRecording) return Color(0xFF64FFDA);
    return Color(0xFFFFD700);
  }

  IconData _getButtonIcon() {
    if (_isProcessing) return Icons.psychology;
    if (_isRecording) return Icons.mic;
    return Icons.mic_none;
  }

  String _getButtonText() {
    if (_isProcessing) return "AI is thinking...";
    if (_isRecording) return "Release to send";
    return "Hold to speak";
  }

  @override
  void dispose() {
    _voiceWaveController.dispose();
    _listeningController.dispose();
    _thinkingController.dispose();
    _audioRecord.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// 💬 CONVERSATION MESSAGE MODEL
class ConversationMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? personality;
  final String? audioUrl;
  final bool isError;

  ConversationMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.personality,
    this.audioUrl,
    this.isError = false,
  });
}