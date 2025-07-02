import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../services/motivator_api.dart'; // Use your existing API service
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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
  
  // Real recording
  FlutterSoundRecorder? _audioRecorder;
  String? _currentRecordingPath;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRecorder();
    _loadHistory();
  }

  Future<void> _initializeRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
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
    final historyList = jsonDecode(historyJson) as List;
    
    setState(() {
      _recordingHistory = historyList.map((item) => Map<String, dynamic>.from(item)).toList();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dictaphone_history', jsonEncode(_recordingHistory));
  }

  void _startRecording() async {
    // Request microphone permission
    final permission = await Permission.microphone.request();
    if (permission != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Microphone permission required for recording'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Get the app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/recordings');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${audioDir.path}/recording_$timestamp.aac';

      // Start recording
      await _audioRecorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start animations
      _pulseController.repeat(reverse: true);
      _waveController.repeat();

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });

      HapticFeedback.mediumImpact();
      print('🎤 Started recording to: $_currentRecordingPath');
      
    } catch (e) {
      print('❌ Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error starting recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;

    try {
      // Stop recording
      final path = await _audioRecorder!.stopRecorder();
      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      // Stop animations
      _pulseController.stop();
      _waveController.stop();

      HapticFeedback.mediumImpact();
      print('🔴 Stopped recording. File saved to: $path');

      // Process the recording with AI (mock for now)
      await _processRecording(path);

    } catch (e) {
      print('❌ Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error stopping recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processRecording(String? filePath) async {
    if (filePath == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      print('📊 Processing recording: $filePath');
      
      // For now, simulate AI processing with mock data
      // In the next step, we'll connect this to your real backend
      await Future.delayed(const Duration(seconds: 2));

      // Mock AI extraction (replace with real API call later)
      final extractedData = {
        'what': 'Schedule team meeting to discuss project milestones',
        'when': 'Tomorrow at 2 PM',
        'where': 'Conference Room B or Zoom',
        'why': 'Need to align on Q1 deliverables and timeline',
        'how': 'Send calendar invite and prepare agenda',
      };

      final recording = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'duration': _recordingDuration.inSeconds,
        'filePath': filePath,
        'originalText': 'Mock transcription: Schedule a team meeting tomorrow at 2 PM to discuss project milestones and Q1 deliverables.',
        'extractedData': extractedData,
      };

      setState(() {
        _recordingHistory.insert(0, recording);
        _isProcessing = false;
        _recordingDuration = Duration.zero;
      });

      await _saveHistory();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Recording processed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ Recording processed and saved to history');

    } catch (e) {
      print('❌ Error processing recording: $e');
      setState(() => _isProcessing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error processing recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteRecording(String id) async {
    setState(() {
      _recordingHistory.removeWhere((recording) => recording['id'] == id);
    });
    await _saveHistory();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Recording deleted'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder?.closeRecorder();
    _pulseController.dispose();
    _waveController.dispose();
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
              Color(0xFF0a1428), // Deep navy
              Color(0xFF1a2332), // Navy blue
              Color(0xFF0f1419), // Dark slate
              Color(0xFF000000), // Black
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Recording Interface
              Expanded(
                flex: 2,
                child: _buildRecordingInterface(),
              ),
              
              // History
              Expanded(
                flex: 3,
                child: _buildHistory(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFFD4AF37),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Dictaphone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Voice to Smart Tasks',
                style: TextStyle(
                  color: const Color(0xFF8B9DC3).withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Recording Button
          GestureDetector(
            onTap: _isProcessing ? null : (_isRecording ? _stopRecording : _startRecording),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isRecording
                            ? [Colors.red, Colors.red.shade700]
                            : _isProcessing
                                ? [Colors.orange, Colors.orange.shade700]
                                : [const Color(0xFFD4AF37), const Color(0xFFB8941F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isProcessing
                          ? Icons.hourglass_empty
                          : _isRecording
                              ? Icons.stop
                              : Icons.mic,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Status Text
          Text(
            _isProcessing
                ? 'Processing...'
                : _isRecording
                    ? 'Recording...'
                    : 'Tap to Record',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Timer
          if (_isRecording || _recordingDuration.inSeconds > 0)
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recording History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _recordingHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          color: const Color(0xFF8B9DC3).withOpacity(0.5),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recordings yet',
                          style: TextStyle(
                            color: const Color(0xFF8B9DC3).withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the mic to start recording',
                          style: TextStyle(
                            color: const Color(0xFF8B9DC3).withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _recordingHistory.length,
                    itemBuilder: (context, index) {
                      final recording = _recordingHistory[index];
                      return _buildHistoryItem(recording);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> recording) {
    final timestamp = DateTime.parse(recording['timestamp']);
    final extractedData = recording['extractedData'] as Map<String, dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.mic,
            color: Color(0xFFD4AF37),
            size: 20,
          ),
        ),
        title: Text(
          extractedData['what'] ?? 'Unknown Task',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: const Color(0xFF8B9DC3).withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _deleteRecording(recording['id']),
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red.withOpacity(0.7),
            size: 20,
          ),
        ),
        iconColor: const Color(0xFFD4AF37),
        collapsedIconColor: const Color(0xFFD4AF37),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataRow('What', extractedData['what']),
                _buildDataRow('When', extractedData['when']),
                _buildDataRow('Where', extractedData['where']),
                _buildDataRow('Why', extractedData['why']),
                _buildDataRow('How', extractedData['how']),
                
                const SizedBox(height: 12),
                
                Text(
                  'Original Text:',
                  style: TextStyle(
                    color: const Color(0xFFD4AF37),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recording['originalText'] ?? 'No transcription available',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                color: const Color(0xFFD4AF37),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(
                color: const Color(0xFF8B9DC3).withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}