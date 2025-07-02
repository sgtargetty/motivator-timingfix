import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../services/motivator_api.dart'; // Use your existing API service

class DictaphoneScreen extends StatefulWidget {
  const DictaphoneScreen({Key? key}) : super(key: key);

  @override
  _DictaphoneScreenState createState() => _DictaphoneScreenState();
}

class _DictaphoneScreenState extends State<DictaphoneScreen>
    with TickerProviderStateMixin {
  
  // Recording state
  bool _isRecording = false;
  bool _isProcessing = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  // History data
  List<Map<String, dynamic>> _recordingHistory = [];
  
  // API service
  final MotivatorApi _api = MotivatorApi();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHistory();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('dictaphone_history') ?? '[]';
    setState(() {
      _recordingHistory = List<Map<String, dynamic>>.from(json.decode(historyJson));
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dictaphone_history', json.encode(_recordingHistory));
  }

  void _startRecording() {
    if (_isRecording) return;
    
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
    
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
    
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });
    
    _pulseController.stop();
    _waveController.stop();
    _recordingTimer?.cancel();
    
    HapticFeedback.lightImpact();
    
    // Process the mock recording with your backend
    await _processRecording();
  }

  Future<void> _processRecording() async {
    try {
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // For now, create mock data - later we'll integrate with your speech processing backend
      final mockData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'duration': _recordingDuration.inSeconds,
        'originalText': 'I need to finish the project report by Friday afternoon and schedule a team meeting to discuss the quarterly results.',
        'extractedData': {
          'what': 'Finish project report and schedule team meeting',
          'when': 'Friday afternoon',
          'where': 'Office/Team meeting room',
          'why': 'Discuss quarterly results',
          'how': 'Complete report writing and send meeting invites'
        },
        'calendarEntry': {
          'title': 'Project Report & Team Meeting',
          'date': 'Friday',
          'time': 'Afternoon',
          'description': 'Complete project report and schedule quarterly results discussion'
        },

      };
      
      setState(() {
        _recordingHistory.insert(0, mockData);
        _isProcessing = false;
        _recordingDuration = Duration.zero;
      });
      
      await _saveHistory();
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎯 Recording processed and calendar entry created!'),
          backgroundColor: const Color(0xFFD4AF37),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _recordingDuration = Duration.zero;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error processing recording: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteHistoryItem(String id) {
    setState(() {
      _recordingHistory.removeWhere((item) => item['id'] == id);
    });
    _saveHistory();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a1428), // Navy
              Color(0xFF000000), // Black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildRecordingInterface(),
                      const SizedBox(height: 30),
                      _buildHistorySection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF8B9DC3),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AI Dictaphone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Recording status
          Text(
            _isProcessing 
                ? 'Processing with AI...' 
                : _isRecording 
                    ? 'Recording...' 
                    : 'Ready to Record',
            style: TextStyle(
              color: _isRecording ? const Color(0xFFD4AF37) : const Color(0xFF8B9DC3),
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Recording timer
          if (_isRecording || _recordingDuration.inSeconds > 0)
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 32,
                fontWeight: FontWeight.w300,
                fontFamily: 'monospace',
              ),
            ),
          
          const SizedBox(height: 30),
          
          // Recording button
          GestureDetector(
            onTap: _isProcessing 
                ? null 
                : _isRecording 
                    ? _stopRecording 
                    : _startRecording,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: _isProcessing
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF8B9DC3).withOpacity(0.3),
                                const Color(0xFF8B9DC3).withOpacity(0.1),
                              ],
                            )
                          : _isRecording
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF6B6B), Color(0xFFE74C3C)],
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                                ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : const Color(0xFFD4AF37))
                              .withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: _isRecording ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isProcessing 
                          ? Icons.auto_awesome_rounded
                          : _isRecording 
                              ? Icons.stop_rounded 
                              : Icons.mic_rounded,
                      color: _isProcessing ? const Color(0xFF8B9DC3) : Colors.black,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Instructions
          Text(
            _isProcessing
                ? 'AI is extracting What, When, Where, Why, How...'
                : _isRecording
                    ? 'Tap to stop recording'
                    : 'Tap to start recording your task',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recording History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '${_recordingHistory.length} recordings',
              style: TextStyle(
                color: const Color(0xFF8B9DC3).withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_recordingHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF8B9DC3).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: const Color(0xFF8B9DC3).withOpacity(0.5),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recordings yet',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start recording to see your AI-processed tasks here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recordingHistory.length,
            itemBuilder: (context, index) {
              final recording = _recordingHistory[index];
              return _buildHistoryItem(recording);
            },
          ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> recording) {
    final timestamp = DateTime.parse(recording['timestamp']);
    final extractedData = recording['extractedData'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
          ),
          title: Text(
            extractedData['what'] ?? 'Recorded Task',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${_formatDateTime(timestamp)} • ${recording['duration']}s',
                style: TextStyle(
                  color: const Color(0xFF8B9DC3).withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            onPressed: () => _deleteHistoryItem(recording['id']),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: const Color(0xFF8B9DC3).withOpacity(0.6),
              size: 20,
            ),
          ),
          children: [
            _buildExtractedDataView(extractedData),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedDataView(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI-Extracted Information:',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildDataRow('What', data['what'], Icons.task_alt_rounded),
          _buildDataRow('When', data['when'], Icons.schedule_rounded),
          _buildDataRow('Where', data['where'], Icons.location_on_rounded),
          _buildDataRow('Why', data['why'], Icons.psychology_rounded),
          _buildDataRow('How', data['how'], Icons.engineering_rounded),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFD4AF37),
            size: 16,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '$label:',
              style: TextStyle(
                color: const Color(0xFF8B9DC3).withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}