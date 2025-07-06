// lib/screens/reflection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import '../services/simple_learning_service.dart';
import '../services/elevenlabs_api.dart'; // Your existing ElevenLabs service
import 'widgets/app_bottom_navbar.dart';

class ReflectionScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String notificationId;

  const ReflectionScreen({
    Key? key,
    required this.task,
    required this.notificationId,
  }) : super(key: key);

  @override
  _ReflectionScreenState createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen>
    with TickerProviderStateMixin {
  
  // Controllers
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // State
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isRecording = false;
  String _aiQuestion = '';
  String _userResponse = '';
  bool _hasResponded = false;
  
  // Text controller for typed responses
  final TextEditingController _responseController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateInitialReflection();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _fadeController.forward();
  }
  
  Future<void> _generateInitialReflection() async {
    setState(() => _isLoading = true);
    
    try {
      // Generate AI reflection question using your backend
      final response = await _generateAIResponse();
      
      setState(() {
        _aiQuestion = response['text'] ?? '';
        _isLoading = false;
      });
      
      // Play the audio if available
      if (response['audioUrl'] != null) {
        await _playAudio(response['audioUrl']);
      }
    } catch (e) {
      print('Error generating reflection: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<Map<String, dynamic>> _generateAIResponse() async {
    // Get base prompt from your backend
    final basePrompt = '''
    Generate a caring, contextual check-in question for a task: "${widget.task['description']}".
    The task was scheduled for ${widget.task['scheduledTime']}.
    Be conversational and show genuine interest in how it went.
    ''';
    
    // 🧠 LEARNING INTEGRATION: Enhance prompt with learned patterns
    final personalizedPrompt = await SimpleLearningService.generatePersonalizedPrompt(
      basePrompt,
      widget.task['taskType'] ?? 'general'
    );
    
    // Call your backend API with the personalized prompt
    // This is where you'd use your existing backend service
    // For now, returning a mock response
    return {
      'text': _getMockReflectionQuestion(),
      'audioUrl': null, // Your ElevenLabs audio URL would go here
    };
  }
  
  String _getMockReflectionQuestion() {
    final taskType = widget.task['taskType'] ?? 'general';
    
    switch (taskType) {
      case 'medical':
        return "Hey! How did your appointment go? I've been thinking about you. 💙";
      case 'work':
        return "Just checking in - how did the meeting turn out? Hope it went well!";
      case 'exercise':
        return "Great job getting that workout done! How are you feeling now? 💪";
      default:
        return "Hi there! How did \"${widget.task['description']}\" go? I'd love to hear about it!";
    }
  }
  
  Future<void> _sendUserResponse() async {
    if (_userResponse.trim().isEmpty) return;
    
    setState(() => _hasResponded = true);
    
    // 🧠 LEARNING INTEGRATION: Learn from user's response
    await SimpleLearningService.learnFromResponse(_userResponse);
    
    // Show learning stats in debug mode
    final stats = await SimpleLearningService.getLearningStats();
    print('🧠 Learning Stats: ${jsonEncode(stats)}');
    
    // Mark task as complete
    _markTaskComplete();
    
    // Show success feedback
    _showSuccessAnimation();
  }
  
  void _markTaskComplete() {
    // Update task status in your storage
    // This would integrate with your existing TaskStorage service
    print('✅ Task marked complete: ${widget.task['id']}');
  }
  
  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFFD4AF37),
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Great job! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Task completed and I\'m learning your style!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pop(); // Return to previous screen
    });
  }
  
  Future<void> _playAudio(String audioUrl) async {
    try {
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      setState(() => _isPlaying = true);
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _audioPlayer.dispose();
    _responseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildContent(),
              ),
            ),
            if (!_hasResponded) _buildResponseInput(),
            AppBottomNavBar(currentScreen: AppScreen.home),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.psychology,
            color: Color(0xFFD4AF37),
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'AI Reflection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTaskCard(),
          const SizedBox(height: 24),
          _buildAIMessage(),
          if (_hasResponded) _buildUserResponseCard(),
        ],
      ),
    );
  }
  
  Widget _buildTaskCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTaskIcon(),
            color: const Color(0xFFD4AF37),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task['scheduledTime'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAIMessage() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4AF37),
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.1),
                  const Color(0xFFD4AF37).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                if (_isPlaying)
                  const Icon(
                    Icons.volume_up,
                    color: Color(0xFFD4AF37),
                    size: 32,
                  )
                else
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFFD4AF37),
                    size: 32,
                  ),
                const SizedBox(height: 12),
                Text(
                  _aiQuestion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildUserResponseCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your response:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _userResponse,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _responseController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your response or tap the mic...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => _userResponse = value,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: const Color(0xFFD4AF37),
            ),
            onPressed: () {
              // Implement voice recording
              HapticFeedback.lightImpact();
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
            onPressed: _userResponse.isNotEmpty ? _sendUserResponse : null,
          ),
        ],
      ),
    );
  }
  
  IconData _getTaskIcon() {
    switch (widget.task['taskType']) {
      case 'medical':
        return Icons.medical_services;
      case 'work':
        return Icons.work;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.task_alt;
    }
  }
}