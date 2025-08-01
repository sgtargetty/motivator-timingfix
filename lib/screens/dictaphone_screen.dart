import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../services/motivator_api.dart';
import '../services/task_scheduler.dart';
import '../services/task_storage.dart';
import 'widgets/app_bottom_navbar.dart';

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
  String? _currentRecordingPath;
  
  // Audio recorder
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  // History data
  List<Map<String, dynamic>> _recordingHistory = [];
  
  // Services
  final MotivatorApi _api = MotivatorApi();
  final TaskScheduler _taskScheduler = TaskScheduler();

  // 🚨 Emergency alert keywords for AI auto-suggestion
  final List<String> _emergencyKeywords = [
    'medication', 'medicine', 'pill', 'doctor', 'appointment', 'medical',
    'pick up kids', 'children', 'school pickup', 'daycare',
    'flight', 'airport', 'plane', 'boarding',
    'meeting with boss', 'important meeting', 'presentation',
    'deadline', 'urgent', 'emergency', 'critical', 'asap',
    'court', 'legal', 'interview', 'exam', 'surgery'
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRecorder();
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

  Future<void> _initializeRecorder() async {
    try {
      _recorder = FlutterSoundRecorder();
      
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      // Initialize recorder
      await _recorder!.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
      
      print('🎤 Audio recorder initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize recorder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to initialize microphone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<String> _getRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/recording_$timestamp.m4a';
  }

  Future<void> _startRecording() async {
    if (_isRecording || !_isRecorderInitialized) return;
    
    try {
      // Get recording path
      _currentRecordingPath = await _getRecordingPath();
      
      // Start recording with M4A format
      await _recorder!.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
      );
      
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
      print('🎤 Recording started (M4A): $_currentRecordingPath');
      
    } catch (e) {
      print('❌ Failed to start recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || !_isRecorderInitialized) return;
    
    try {
      // Stop recording
      await _recorder!.stopRecorder();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });
      
      _pulseController.stop();
      _waveController.stop();
      _recordingTimer?.cancel();
      
      HapticFeedback.lightImpact();
      print('🛑 Recording stopped: $_currentRecordingPath');
      
      // Process the recording with your backend
      await _processRecording();
      
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      setState(() {
        _isProcessing = false;
        _recordingDuration = Duration.zero;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to stop recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔄 FIX 1: Updated _processRecording to return success result
  Future<void> _processRecording() async {
    if (_currentRecordingPath == null) {
      setState(() {
        _isProcessing = false;
        _recordingDuration = Duration.zero;
      });
      return;
    }

    try {
      print('🔄 Processing recording...');
      
      // Call your backend API to process the speech
      final result = await _api.processSpeech(
        _currentRecordingPath!,
        durationSeconds: _recordingDuration.inSeconds,
      );
      
      // Create history entry with real data from backend
      final historyEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'duration': _recordingDuration.inSeconds,
        'transcribedText': result['transcribedText'],
        'extractedData': result['extractedData'],
        'audioFilePath': _currentRecordingPath,
      };
      
      setState(() {
        _recordingHistory.insert(0, historyEntry);
        _isProcessing = false;
        _recordingDuration = Duration.zero;
      });
      
      await _saveHistory();
      
      // 🚀 Auto-create task with smart emergency detection
      await _autoCreateTask(result['extractedData'], result['transcribedText']);
      
      print('✅ Recording processed successfully');
      
    } catch (e) {
      print('❌ Error processing recording: $e');
      setState(() {
        _isProcessing = false;
        _recordingDuration = Duration.zero;
      });
      
      // 🔧 FIX: Return false on error
      if (mounted) {
        Navigator.of(context).pop(false); // ❌ Return false on error
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error processing recording: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🧠 AI-powered emergency detection
  bool _shouldSuggestEmergencyAlert(String transcribedText, Map<String, dynamic> extractedData) {
    final text = transcribedText.toLowerCase();
    final what = (extractedData['what'] ?? '').toString().toLowerCase();
    final allText = '$text $what';
    
    // Check for emergency keywords
    for (final keyword in _emergencyKeywords) {
      if (allText.contains(keyword)) {
        print('🚨 Emergency keyword detected: $keyword');
        return true;
      }
    }
    
    return false;
  }

  // 🚀 NEW: Auto-create task with smart emergency popup
  Future<void> _autoCreateTask(Map<String, dynamic> extractedData, String transcribedText) async {
    // Check if we should suggest emergency alert
    final suggestEmergency = _shouldSuggestEmergencyAlert(transcribedText, extractedData);
    
    if (suggestEmergency) {
      // Show emergency alert "upsell" popup
      _showEmergencyAlertPopup(extractedData, transcribedText);
    } else {
      // Create regular task immediately
      await _createTaskWithSettings(extractedData, transcribedText, false, 'male:Default Male', 'Balanced');
    }
  }

  // 🚨 Smart "Upsell" Emergency Alert Popup
  void _showEmergencyAlertPopup(Map<String, dynamic> extractedData, String transcribedText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EmergencyAlertDialog(
          extractedData: extractedData,
          transcribedText: transcribedText,
          onChoice: (isEmergency, voiceStyle, toneStyle) {
            _createTaskWithSettings(extractedData, transcribedText, isEmergency, voiceStyle, toneStyle);
          },
        );
      },
    );
  }

  // 🔄 FIX 1: Updated _createTaskWithSettings to handle navigation properly
  Future<void> _createTaskWithSettings(
    Map<String, dynamic> extractedData, 
    String transcribedText,
    bool isEmergency,
    String voiceStyle,
    String toneStyle,
  ) async {
    try {
      // Parse the "when" field to set smart default time
      DateTime scheduledTime = _parseWhenField(extractedData['when'], transcribedText);
      
      // Create task data in TaskScheduler format
      final taskData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'description': extractedData['what'] ?? 'Dictated Task',
        'dateTime': scheduledTime,
        'isRecurring': false,
        'isAmberAlert': isEmergency,
        'toneStyle': toneStyle,
        'voiceStyle': voiceStyle,
        'forceOverrideSilent': isEmergency,
        
        // Add TaskStorage required fields
        'isCompleted': false,
        'isArchived': false,
        'completedAt': null,
        'archivedAt': null,
        
        // Add AI context for better motivational lines
        'aiContext': {
          'transcribedText': transcribedText,
          'extractedData': extractedData,
          'when': extractedData['when'],
          'where': extractedData['where'],
          'why': extractedData['why'],
          'how': extractedData['how'],
        },
      };

      print('📅 Auto-creating task: ${taskData['description']}');
      print('🚨 Emergency: $isEmergency');
      print('🕒 Scheduled for: $scheduledTime');
      
      // 🚀 STEP 1: Save task to TaskStorage (for calendar display)
      final TaskStorage taskStorage = TaskStorage();
      await taskStorage.saveTask(taskData);
      print('✅ Task saved to TaskStorage for calendar display');
      
      // 🚀 STEP 2: Schedule notifications with TaskScheduler
      await _taskScheduler.scheduleTask(taskData);
      print('✅ Notifications scheduled with TaskScheduler');
      
      // 🔧 FIX: After successful task creation, signal success to parent
      if (mounted) {
        // Pop back to main screen with success signal
        Navigator.of(context).pop(true); // ✅ Return true on success
        
        // Optional: Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task "${extractedData['what']}" added to calendar!'),
            backgroundColor: const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      print('❌ Error creating scheduled task: $e');
      
      // 🔧 FIX: Return false on error
      if (mounted) {
        Navigator.of(context).pop(false); // ❌ Return false on error
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error scheduling task: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🕒 Smart time parsing from AI data
  // 🔧 FIXED _parseWhenField - REPLACE in dictaphone_screen.dart
DateTime _parseWhenField(String? when, String transcribedText) {
  print('🔍 Parsing when field: "$when"');
  print('🔍 Transcribed text: "$transcribedText"');
  
  // 🚀 PRIORITY: If GPT-4.1 provided a valid ISO date, use it directly
  if (when != null && when != "Not specified" && when.trim().isNotEmpty) {
    try {
      // 🔧 FIXED: Check for ISO date format including timezone offsets
      // Valid formats: "2025-07-29T09:00:00Z" OR "2025-07-29T09:00:00-04:00" OR "2025-07-29T09:00:00+09:00"
      if (when.contains('T') && (when.contains('Z') || when.contains('+') || when.contains('-'))) {
        
        // 🔧 ADDITIONAL CHECK: Ensure it has the timezone part at the end
        final hasTimezone = when.endsWith('Z') || 
                           (when.length > 19 && (when.substring(19).contains('+') || when.substring(19).contains('-')));
        
        if (hasTimezone) {
          final parsedDate = DateTime.parse(when);
          final localDate = parsedDate.toLocal();
          print('✅ Successfully parsed timezone-aware ISO date: $when → ${localDate.toString()}');
          print('📅 Scheduled for: ${localDate.day}/${localDate.month}/${localDate.year} at ${localDate.hour}:${localDate.minute.toString().padLeft(2, '0')}');
          return localDate;
        } else {
          print('⚠️ Date has T but no timezone info: "$when"');
        }
      } else {
        print('⚠️ Date format doesn\'t look like ISO: "$when"');
      }
    } catch (e) {
      print('❌ Failed to parse ISO date "$when": $e');
    }
  }
  
  print('🔄 Falling back to manual date parsing...');
  
  // Fallback for legacy dates or parsing failures
  final whenLower = when?.toLowerCase() ?? '';
  final textLower = transcribedText.toLowerCase();
  
  DateTime baseTime = DateTime.now().add(const Duration(hours: 1)); // Default: 1 hour from now
  
  // Handle simple cases as fallback
  if (whenLower.contains('tomorrow') || textLower.contains('tomorrow')) {
    baseTime = DateTime.now().add(const Duration(days: 1));
    
    // Try to extract specific time from transcribed text
    if (textLower.contains('10 o\'clock') || textLower.contains('10am') || textLower.contains('10 a.m')) {
      baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 10, 0);
    } else if (textLower.contains('2 o\'clock') || textLower.contains('2pm') || textLower.contains('2 p.m')) {
      baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 14, 0);
    } else if (textLower.contains('3 o\'clock') || textLower.contains('3pm') || textLower.contains('3 p.m')) {
      baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 15, 0);
    } else {
      // Default tomorrow time
      baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 9, 0);
    }
    print('📅 Detected "tomorrow" - scheduled for: $baseTime');
  }
  else if (whenLower.contains('today') || textLower.contains('today')) {
    baseTime = DateTime.now().add(const Duration(hours: 2)); // 2 hours from now
    print('📅 Detected "today" - scheduled for: $baseTime');
  }
  else if (whenLower.contains('next week')) {
    baseTime = DateTime.now().add(const Duration(days: 7));
    baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 9, 0);
    print('📅 Detected "next week" - scheduled for: $baseTime');
  }
  else {
    // Enhanced weekday detection as fallback
    final now = DateTime.now();
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    bool foundWeekday = false;
    for (int i = 0; i < weekdays.length; i++) {
      if (whenLower.contains(weekdays[i]) || textLower.contains(weekdays[i])) {
        // Find the next occurrence of this weekday
        final targetWeekday = i + 1; // DateTime.weekday is 1-based (Monday=1)
        int daysUntilTarget = (targetWeekday - now.weekday) % 7;
        if (daysUntilTarget == 0) daysUntilTarget = 7; // If today is the target day, schedule for next week
        
        baseTime = DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilTarget));
        
        // Try to extract time from text
        if (textLower.contains('3pm') || textLower.contains('3 pm') || textLower.contains('3 o\'clock')) {
          baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 15, 0);
        } else {
          baseTime = DateTime(baseTime.year, baseTime.month, baseTime.day, 9, 0); // Default 9 AM
        }
        
        print('📅 Detected weekday "${weekdays[i]}" - scheduled for: $baseTime');
        foundWeekday = true;
        break;
      }
    }
    
    if (!foundWeekday) {
      print('📅 No specific date detected - using default: $baseTime');
    }
  }
  
  print('🕒 Final parsed time: $baseTime');
  return baseTime;
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
    
    // Close recorder
    if (_recorder != null) {
      _recorder!.closeRecorder();
    }
    
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
            Color(0xFF0a1428),
            Color(0xFF1a2332), 
            Color(0xFF0f1419),
            Color(0xFF000000),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
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
                    const SizedBox(height: 40),
                    _buildHistorySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // ADD THIS NEW LINE:
            AppBottomNavBar(currentScreen: AppScreen.dictaphone),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        // 🔧 FIX: Wrap Column in Expanded to prevent overflow
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Dictaphone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              // 🔧 FIX: Add flexible text wrapping
              const Text(
                'Speak your tasks, automatically added to calendar',
                style: TextStyle(
                  color: Color(0xFF8B9DC3),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
                maxLines: 2, // Allow text to wrap to 2 lines if needed
                overflow: TextOverflow.ellipsis, // Add ellipsis if still too long
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildRecordingInterface() {
    return Column(
      children: [
        // Recording timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (_isRecording ? const Color(0xFFD4AF37) : const Color(0xFF8B9DC3)).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              color: _isRecording ? const Color(0xFFD4AF37) : const Color(0xFF8B9DC3),
              fontSize: 18,
              fontWeight: FontWeight.w300,
              fontFamily: 'monospace',
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Recording button with animation
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
                    gradient: _isProcessing
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF8B9DC3).withOpacity(0.3),
                              const Color(0xFF8B9DC3).withOpacity(0.1),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37),
                              const Color(0xFFD4AF37).withOpacity(0.8),
                            ],
                          ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isProcessing
                        ? Icons.hourglass_empty_rounded
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
              ? 'AI is extracting and scheduling your task...'
              : _isRecording
                  ? 'Tap to stop recording'
                  : _isRecorderInitialized 
                      ? 'Tap to record your task - it will be automatically added to calendar!'
                      : 'Initializing microphone...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF8B9DC3).withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
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
                  Icons.auto_awesome_rounded,
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
                  'Start recording to automatically create calendar tasks!',
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
    final transcribedText = recording['transcribedText'] ?? '';
    
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
              Icons.auto_awesome_rounded,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
          ),
          title: Text(
            extractedData['what'] ?? 'Auto-Created Task',
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
                _formatTimestamp(timestamp),
                style: TextStyle(
                  color: const Color(0xFF8B9DC3).withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: const Color(0xFFD4AF37).withOpacity(0.8),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-added to calendar',
                    style: TextStyle(
                      color: const Color(0xFFD4AF37).withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
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
            _buildExtractionSection(extractedData),
            const SizedBox(height: 16),
            _buildTranscriptionSection(transcribedText),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractionSection(Map<String, dynamic> extractedData) {
    final items = [
      {'icon': Icons.task_alt_rounded, 'label': 'What', 'value': extractedData['what']},
      {'icon': Icons.schedule_rounded, 'label': 'When', 'value': extractedData['when']},
      {'icon': Icons.location_on_rounded, 'label': 'Where', 'value': extractedData['where']},
      {'icon': Icons.help_outline_rounded, 'label': 'Why', 'value': extractedData['why']},
      {'icon': Icons.build_rounded, 'label': 'How', 'value': extractedData['how']},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Extraction',
          style: TextStyle(
            color: const Color(0xFFD4AF37).withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item['icon'] as IconData,
                color: const Color(0xFF8B9DC3),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item['label']}: ',
                        style: TextStyle(
                          color: const Color(0xFF8B9DC3).withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: item['value'] ?? 'Not specified',
                        style: TextStyle(
                          color: const Color(0xFF8B9DC3).withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildTranscriptionSection(String transcribedText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transcribed Text',
          style: TextStyle(
            color: const Color(0xFFD4AF37).withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF8B9DC3).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            transcribedText.isNotEmpty ? transcribedText : 'No transcription available',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              fontStyle: transcribedText.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds % 60);
    return '$minutes:$seconds';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// 🚨 EMERGENCY ALERT "UPSELL" DIALOG

class EmergencyAlertDialog extends StatefulWidget {
  final Map<String, dynamic> extractedData;
  final String transcribedText;
  final Function(bool isEmergency, String voiceStyle, String toneStyle) onChoice;

  const EmergencyAlertDialog({
    Key? key,
    required this.extractedData,
    required this.transcribedText,
    required this.onChoice,
  }) : super(key: key);

  @override
  _EmergencyAlertDialogState createState() => _EmergencyAlertDialogState();
}

class _EmergencyAlertDialogState extends State<EmergencyAlertDialog> {
  String _selectedVoice = 'male:Default Male';
  String _selectedTone = 'Balanced';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0a1428),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a1428),
              Color(0xFF000000),
            ],
          ),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emergency Icon + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make this an EMERGENCY ALERT?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get voice notifications with vibration',
                        style: TextStyle(
                          color: Color(0xFF8B9DC3),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Task Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"${widget.extractedData['what'] ?? 'Critical Task'}"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Emergency Alert Options (Voice & Tone)
            ExpansionTile(
              title: const Text(
                'Emergency Alert Options',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                const SizedBox(height: 12),
                
                // Voice Selection
                Text(
                  'Voice Style:',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedVoice,
                  dropdownColor: const Color(0xFF0a1428),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    // 🎭 YOUR 3 CUSTOM FAVORITES ONLY
                    DropdownMenuItem(value: 'characters:Lana Croft', child: Text('🗂️ Lana Croft')),
                    DropdownMenuItem(value: 'characters:Baxter Jordan', child: Text('🔍 Baxter Jordan')),
                    DropdownMenuItem(value: 'characters:Argent', child: Text('🤖 Argent')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedVoice = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Tone Selection
                Text(
                  'Tone Style:',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTone,
                  dropdownColor: const Color(0xFF0a1428),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
                    DropdownMenuItem(value: 'Drill Instructor', child: Text('Drill Instructor')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTone = value!;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.onChoice(false, 'male:Default Male', 'Balanced');
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFF8B9DC3).withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      'Regular Alert',
                      style: TextStyle(
                        color: const Color(0xFF8B9DC3).withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onChoice(true, _selectedVoice, _selectedTone);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '🚨 EMERGENCY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}