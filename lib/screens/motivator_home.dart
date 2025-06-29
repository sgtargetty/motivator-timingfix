import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import '../services/motivator_api.dart';
import '../services/notification_manager.dart';
import '../services/task_scheduler.dart';
import '../services/task_storage.dart'; // 📋 ADDED - TaskStorage import
import 'settings_screen.dart';
import 'amber_alert_screen.dart';
import 'widgets/motivator_dashboard.dart';
import 'widgets/motivator_calendar.dart';

// ✅ ViewMode enum
enum ViewMode { calendar, dashboard }

class MotivatorHome extends StatefulWidget {
  final String? initialTaskType;
  final Map<String, dynamic>? taskTypeConfig;

  const MotivatorHome({
    Key? key,
    this.initialTaskType,
    this.taskTypeConfig,
  }) : super(key: key);

  @override
  _MotivatorHomeState createState() => _MotivatorHomeState();
}

class _MotivatorHomeState extends State<MotivatorHome>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final MotivatorApi _api = MotivatorApi();
  final AudioPlayer _player = AudioPlayer();
  final TaskStorage _taskStorage = TaskStorage(); // 📋 ADDED - TaskStorage instance

  late AnimationController _motivationController;
  late AnimationController _streakController;
  late AnimationController _pulseController;
  late AnimationController _cardController;
  late AnimationController _geometryController;
  late AnimationController _particleController;

  late Animation<double> _motivationScale;
  late Animation<double> _streakBounce;
  late Animation<double> _pulseBeat;
  late Animation<double> _cardSlide;
  late Animation<double> _cardOpacity;
  late Animation<double> _geometryRotation;
  late Animation<double> _glowOpacity;

  String _generatedLine = '';
  bool _loading = false;
  ViewMode _currentView = ViewMode.dashboard;

  // ✅ Calendar-specific state
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _tasks = {};

  // 🚀 Dashboard features
  int _motivationStreak = 5;
  int _totalMotivations = 23;
  List<String> _recentMotivations = [
    "You've got the power to make it happen! 💪",
    "Every step forward is progress worth celebrating! 🎉",
    "Your determination will carry you through! 🚀",
  ];
  
  List<String> _quickActions = [
    "Morning Motivation",
    "Workout Boost", 
    "Work Focus",
    "Evening Reflection",
    "Study Session",
    "Creative Flow",
  ];

  String _dailyQuote = "Success is not final, failure is not fatal: it is the courage to continue that counts.";
  String _userName = "Champion"; // Will be loaded from SharedPreferences

  // 🎛️ User preferences from onboarding
  String? _currentTaskType;
  Map<String, dynamic>? _currentTaskConfig;
  String _selectedVoice = 'male:Default Male';
  String _selectedToneStyle = 'Balanced';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cardController.forward();
    
    // Load user preferences including name
    _loadUserPreferences();
    
    // 📋 ADDED - Load tasks from storage
    _loadTasks();
    
    // Set initial preferences from onboarding
    _currentTaskType = widget.initialTaskType;
    _currentTaskConfig = widget.taskTypeConfig;
    
    // Update quick actions based on selected task type
    if (_currentTaskType != null) {
      _updateQuickActionsForTaskType();
    }
    
    // ✅ Setup notification listeners after widget tree is initialized
    NotificationManager.instance.setupNotificationListeners();
    
    // ✅ Request enhanced notification permissions after initialization
    NotificationManager.instance.requestAwesomeNotificationPermissions();
  }

  // Load user preferences from SharedPreferences
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Champion';
      
      // 🎯 NEW: Load voice and tone settings with proper defaults
      _selectedVoice = prefs.getString('selected_voice') ?? 'male:Default Male'; 
      _selectedToneStyle = prefs.getString('selected_tone') ?? 'Balanced';
      _currentTaskType = prefs.getString('selected_task_type')?.isNotEmpty == true 
          ? prefs.getString('selected_task_type') 
          : null;
    });
    print('🔄 Loaded user preferences:');
    print('  Name: $_userName');
    print('  Voice: $_selectedVoice');
    print('  Tone: $_selectedToneStyle');
    print('  Task Type: $_currentTaskType');
  }

  // 📋 ADDED - Load tasks from storage
  Future<void> _loadTasks() async {
    try {
      final allTasks = await _taskStorage.loadAllTasks();
      final Map<DateTime, List<Map<String, dynamic>>> groupedTasks = {};
      
      for (final task in allTasks) {
        final taskDate = task['dateTime'] as DateTime?;
        if (taskDate != null) {
          final normalizedDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
          groupedTasks[normalizedDate] = groupedTasks[normalizedDate] ?? [];
          groupedTasks[normalizedDate]!.add(task);
        }
      }
      
      setState(() {
        _tasks = groupedTasks;
      });
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  // 📋 ADDED - Handle task changes (for swipe actions)
  void _handleTasksChanged() {
    _loadTasks(); // Reload tasks when changes occur
  }

  void _updateQuickActionsForTaskType() {
    switch (_currentTaskType) {
      case 'Study':
        _quickActions = ["Focus Session", "Reading Time", "Note Review", "Quiz Prep", "Research Deep Dive", "Memory Practice"];
        break;
      case 'Exercise':
        _quickActions = ["Pre-Workout", "Cardio Boost", "Strength Push", "Cool Down", "Yoga Flow", "Recovery"];
        break;
      case 'Work':
        _quickActions = ["Project Focus", "Meeting Prep", "Email Clear", "Creative Think", "Problem Solve", "Team Sync"];
        break;
      case 'Eat':
        _quickActions = ["Meal Prep", "Healthy Choice", "Portion Control", "Mindful Eating", "Hydration", "Nutrition Plan"];
        break;
      case 'Sleep':
        _quickActions = ["Wind Down", "Relaxation", "Sleep Prep", "Dream Well", "Recovery Rest", "Morning Rise"];
        break;
      default:
        _quickActions = ["Morning Motivation", "Workout Boost", "Work Focus", "Evening Reflection", "Study Session", "Creative Flow"];
    }
  }

  void _setupAnimations() {
    _motivationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _streakController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _geometryController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _motivationScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _motivationController, curve: Curves.elasticOut),
    );

    _streakBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streakController, curve: Curves.bounceOut),
    );

    _pulseBeat = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOut),
    );

    _geometryRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _geometryController,
    );

    _glowOpacity = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  // Helper functions for calendar
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 📋 UPDATED - Enhanced task addition with storage
  void _addTaskToDay(DateTime day, Map<String, dynamic> taskData) async {
    try {
      // Ensure task has an ID
      if (taskData['id'] == null) {
        taskData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      // Save to storage
      await _taskStorage.saveTask(taskData);
      
      // Update local state
      final normalizedDay = _normalizeDate(day);
      setState(() {
        if (_tasks[normalizedDay] == null) {
          _tasks[normalizedDay] = [];
        }
        _tasks[normalizedDay]!.add(taskData);
      });
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> _generateMotivationForTask(String task) async {
    await _generateMotivation(task);
  }

  Future<void> _generateMotivation([String? customTask]) async {
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    
    try {
      final task = customTask ?? _controller.text.trim();
      if (task.isEmpty && customTask == null) return;
      
      print('🎯 Using settings - Voice: $_selectedVoice, Tone: $_selectedToneStyle, Task Type: $_currentTaskType');
      
      final line = await _api.generateLine(
        task,
        toneStyle: _selectedToneStyle,
        voiceStyle: _selectedVoice, 
        taskType: _currentTaskType,
      );
      
      final audioBytes = await _api.generateVoice(
        line,
        voiceStyle: _selectedVoice,
        toneStyle: _selectedToneStyle,
      );

      setState(() {
        _generatedLine = line;
        _totalMotivations++;
        _motivationStreak++;
        if (_recentMotivations.length >= 5) {
          _recentMotivations.removeAt(0);
        }
        _recentMotivations.add(line);
      });

      _motivationController.forward();
      _streakController.forward();

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse('data:audio/mpeg;base64,${base64Encode(audioBytes)}'),
        ),
      );
      _player.play();

      HapticFeedback.heavyImpact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _selectQuickAction(String action) {
    HapticFeedback.selectionClick();
    _controller.text = action;
    _generateMotivation(action);
  }

  void _navigateToSettings() async {
    HapticFeedback.lightImpact();
    // 🎯 Ensure voice is in correct format before passing to settings
    String currentVoice = _selectedVoice;
    if (!currentVoice.contains(':')) {
      // Convert legacy format to new format
      if (currentVoice.contains('Female') || currentVoice.contains('Woman') || 
          currentVoice.contains('Belle') || currentVoice.contains('Girl')) {
        currentVoice = 'female:$currentVoice';
      } else if (currentVoice.contains('Robot') || currentVoice.contains('Pirate') || 
                 currentVoice.contains('Wizard') || currentVoice.contains('Superhero') || 
                 currentVoice.contains('Lana') || currentVoice.contains('Baxter') || 
                 currentVoice.contains('Argent')) {
        currentVoice = 'characters:$currentVoice';
      } else {
        currentVoice = 'male:$currentVoice';
      }
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentTaskType: _currentTaskType,
          currentTaskConfig: _currentTaskConfig,
          currentVoice: currentVoice,
          currentToneStyle: _selectedToneStyle,
          onSettingsChanged: (taskType, config, voice, tone) {
            setState(() {
              _currentTaskType = taskType;
              _currentTaskConfig = config;
              _selectedVoice = voice ?? 'male:Default Male';
              _selectedToneStyle = tone ?? 'Balanced';
              _updateQuickActionsForTaskType();
              
              print('🔄 Settings updated - Voice: $_selectedVoice, Tone: $_selectedToneStyle');
            
            // 🎯 IMMEDIATELY test voice persistence by saving to SharedPreferences
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString('selected_voice', _selectedVoice);
              prefs.setString('selected_tone', _selectedToneStyle);
              print('💾 Voice settings persisted immediately: $_selectedVoice');
            });
            });
          },
        ),
      ),
    );
    
    // 🎯 FIXED: Only reload the name (not voice settings which would overwrite the callback)
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Champion';
    });
    print('🔄 Reloaded user name: $_userName');
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    _motivationController.dispose();
    _streakController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _geometryController.dispose();
    _particleController.dispose();
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
              Color(0xFF0a1428), // Deep navy - MATCH splash/onboarding
              Color(0xFF1a2332), // Navy blue
              Color(0xFF0f1419), // Dark slate
              Color(0xFF000000), // Black
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // EXACT same geometric background as splash/onboarding
            AnimatedBuilder(
              animation: _geometryController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GeometricPatternPainter(_geometryRotation.value),
                  size: Size.infinite,
                );
              },
            ),

            // EXACT same refined particles as splash/onboarding
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RefinedParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            SafeArea(
              child: Column(
                children: [
                  // 🔝 Sophisticated Fixed Header
                  _buildSophisticatedHeader(),
                  
                  // 📱 Main Content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _cardController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _cardSlide.value),
                          child: Opacity(
                            opacity: _cardOpacity.value,
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                _buildSophisticatedViewToggle(),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: _currentView == ViewMode.dashboard
                                      ? MotivatorDashboard(
                                          userName: _userName,
                                          motivationStreak: _motivationStreak,
                                          totalMotivations: _totalMotivations,
                                          recentMotivations: _recentMotivations,
                                          quickActions: _quickActions,
                                          dailyQuote: _dailyQuote,
                                          generatedLine: _generatedLine,
                                          loading: _loading,
                                          currentTaskType: _currentTaskType,
                                          currentTaskConfig: _currentTaskConfig,
                                          controller: _controller,
                                          motivationScale: _motivationScale,
                                          streakBounce: _streakBounce,
                                          streakController: _streakController,
                                          onGenerateMotivation: () => _generateMotivation(),
                                          onSelectQuickAction: _selectQuickAction,
                                          onGenerateMotivationForTask: _generateMotivationForTask,
                                        )
                                      : MotivatorCalendar(
                                          selectedDay: _selectedDay,
                                          tasks: _tasks,
                                          generatedLine: _generatedLine,
                                          loading: _loading,
                                          currentTaskType: _currentTaskType,
                                          onDaySelected: (selectedDay) {
                                            setState(() {
                                              _selectedDay = selectedDay;
                                            });
                                          },
                                          onTaskAdded: _addTaskToDay,
                                          onGenerateMotivationForTask: _generateMotivationForTask,
                                          onTasksChanged: _handleTasksChanged, // 📋 ADDED - Task history callback
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // 🔽 Sophisticated Fixed Footer Navigation
                  _buildSophisticatedFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSophisticatedHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.1), // Gold accent
            width: 1,
          ),
        ),
        // Add subtle backdrop blur effect
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sophisticated animated logo
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _geometryController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseBeat.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer geometric ring - smaller version of splash logo
                    Transform.rotate(
                      angle: _geometryRotation.value * 2 * math.pi,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(_glowOpacity.value * 0.4),
                            width: 1,
                          ),
                        ),
                        child: CustomPaint(
                          painter: GeometricRingPainter(_geometryRotation.value),
                        ),
                      ),
                    ),
                    // Inner glow
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(_glowOpacity.value * 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Main icon with task type context
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFD4AF37).withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        _currentTaskConfig?['icon'] ?? Icons.auto_awesome,
                        color: const Color(0xFFD4AF37), // Gold instead of teal
                        size: 24,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(width: 16),
          
          // Sophisticated title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App title with gold gradient
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFD700), // Bright gold
                      Color(0xFFD4AF37), // Rich gold
                      Color(0xFFB8860B), // Deep gold
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    'Motivator.AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w200, // Ultra-light like splash
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Color(0xFFD4AF37),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_currentTaskType != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '$_currentTaskType Mode',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37), // Gold accent
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Sophisticated streak counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.1),
                  const Color(0xFFD4AF37).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: const Color(0xFFD4AF37),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_motivationStreak',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSophisticatedViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2), // Gold border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentView = ViewMode.dashboard);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _currentView == ViewMode.dashboard
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37), // Gold gradient
                            Color(0xFFFFD700),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _currentView == ViewMode.dashboard
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dashboard_rounded,
                      color: _currentView == ViewMode.dashboard
                          ? Colors.black
                          : const Color(0xFF8B9DC3),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: _currentView == ViewMode.dashboard
                            ? Colors.black
                            : const Color(0xFF8B9DC3),
                        fontWeight: _currentView == ViewMode.dashboard
                            ? FontWeight.w600
                            : FontWeight.w300,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentView = ViewMode.calendar);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _currentView == ViewMode.calendar
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37), // Gold gradient
                            Color(0xFFFFD700),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _currentView == ViewMode.calendar
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: _currentView == ViewMode.calendar
                          ? Colors.black
                          : const Color(0xFF8B9DC3),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calendar',
                      style: TextStyle(
                        color: _currentView == ViewMode.calendar
                            ? Colors.black
                            : const Color(0xFF8B9DC3),
                        fontWeight: _currentView == ViewMode.calendar
                            ? FontWeight.w600
                            : FontWeight.w300,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSophisticatedFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.1), // Gold border
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSophisticatedFooterButton(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isActive: _currentView == ViewMode.dashboard,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _currentView = ViewMode.dashboard);
            },
          ),
          _buildSophisticatedFooterButton(
            icon: Icons.calendar_today_rounded,
            label: 'Calendar',
            isActive: _currentView == ViewMode.calendar,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _currentView = ViewMode.calendar);
            },
          ),
          _buildSophisticatedFooterButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isActive: false,
            onTap: _navigateToSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildSophisticatedFooterButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive 
              ? Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3))
              : null,
          boxShadow: isActive 
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive 
                  ? const Color(0xFFD4AF37) 
                  : const Color(0xFF8B9DC3).withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive 
                    ? const Color(0xFFD4AF37) 
                    : const Color(0xFF8B9DC3).withOpacity(0.7),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w300,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// EXACT same painters as splash/onboarding for perfect visual consistency
class GeometricPatternPainter extends CustomPainter {
  final double animationValue;

  GeometricPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw subtle geometric lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animationValue * math.pi / 4);
      final startX = centerX + math.cos(angle) * 100;
      final startY = centerY + math.sin(angle) * 100;
      final endX = centerX + math.cos(angle) * 200;
      final endY = centerY + math.sin(angle) * 200;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GeometricRingPainter extends CustomPainter {
  final double animationValue;

  GeometricRingPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = 20.0; // Smaller radius for header logo

    // Draw rotating geometric points
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + (animationValue * 2 * math.pi);
      final x = centerX + math.cos(angle) * radius;
      final y = centerY + math.sin(angle) * radius;

      canvas.drawCircle(
        Offset(x, y),
        1.5,
        paint..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RefinedParticlePainter extends CustomPainter {
  final double animationValue;
  final List<RefinedParticle> particles = [];

  RefinedParticlePainter(this.animationValue) {
    // Generate fewer, more elegant particles
    for (int i = 0; i < 30; i++) {
      particles.add(RefinedParticle());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = (particle.x * size.width + 
                 math.sin(animationValue * math.pi + particle.phase) * 20) % size.width;
      final y = (particle.y * size.height + 
                 animationValue * particle.speed * size.height) % size.height;
      
      final opacity = (math.sin(animationValue * math.pi + particle.phase) + 1) / 2;
      paint.color = const Color(0xFFD4AF37).withOpacity(opacity * 0.15);
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RefinedParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  RefinedParticle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 1.5 + 0.5,
        speed = math.Random().nextDouble() * 0.3 + 0.05,
        phase = math.Random().nextDouble() * 2 * math.pi;
}