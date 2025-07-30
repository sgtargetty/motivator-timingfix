import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data'; // 🎤 NEW: Added for voice sample integration

import '../services/motivator_api.dart';
import '../services/immediate_unlimited_voice_system.dart';
import '../services/notification_manager.dart';
import '../services/task_scheduler.dart';
import '../services/task_storage.dart';
import 'settings_screen.dart';
import 'amber_alert_screen.dart';
import 'widgets/motivator_dashboard.dart';
import 'widgets/motivator_calendar.dart';
import 'dictaphone_screen.dart';
import 'widgets/app_bottom_navbar.dart'; // 📱 NEW IMPORT
import '../services/complete_voice_manager.dart';
import 'memory_management_screen.dart';

// ✅ ViewMode enum
enum ViewMode { calendar, dashboard, dictaphone }

class MotivatorHome extends StatefulWidget {
  final String? initialTaskType;
  final Map<String, dynamic>? taskTypeConfig;
  final ViewMode? initialView;  // 🔧 ADD THIS LINE

  const MotivatorHome({
    Key? key,
    this.initialTaskType,
    this.taskTypeConfig,
    this.initialView,  // 🔧 ADD THIS LINE
  }) : super(key: key);

  @override
  _MotivatorHomeState createState() => _MotivatorHomeState();
}

class _MotivatorHomeState extends State<MotivatorHome>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final MotivatorApi _api = MotivatorApi();
  final AudioPlayer _player = AudioPlayer();
  final TaskStorage _taskStorage = TaskStorage();

  // 🎤 NEW: Replace the old voice sample method with complete voice manager
  final ImmediateUnlimitedVoiceSystem _unlimitedVoice = ImmediateUnlimitedVoiceSystem();
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
  String _userName = "Champion";

  // 🎛️ User preferences - FIXED VARIABLE NAMES
  String? _currentTaskType;
  Map<String, dynamic>? _currentTaskConfig;
  String _selectedVoice = 'male:Default Male';
  String _selectedToneStyle = 'Balanced';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cardController.forward();
    
    _loadUserPreferences();
    _loadTasks();
    
    _currentTaskType = widget.initialTaskType;
    _currentTaskConfig = widget.taskTypeConfig;

    if (widget.initialView != null) {
      _currentView = widget.initialView!;
    }
    
    if (_currentTaskType != null) {
      _updateQuickActionsForTaskType();
    }

  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Champion';
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

  void _handleTasksChanged() {
    _loadTasks();
  }

  // 🔧 FIXED: Navigation handler with correct variable names
  void _handleAppNavigation(AppScreen targetScreen) {
    switch (targetScreen) {
      case AppScreen.dashboard:
        setState(() {
          _currentView = ViewMode.dashboard;
        });
        break;
    
      case AppScreen.calendar:
        setState(() {
          _currentView = ViewMode.calendar;
        });
        break;

      case AppScreen.dictaphone:
        setState(() {
          _currentView = ViewMode.dictaphone;
        });
        break;
    
      case AppScreen.memory:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MemoryManagementScreen(),
          ),
          (route) => false,
        );
        break;
    
      case AppScreen.settings:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              currentTaskType: _currentTaskType,        // ✅ FIXED: Use existing variable
              currentTaskConfig: _currentTaskConfig,    // ✅ FIXED: Use existing variable
              currentVoice: _selectedVoice,             // ✅ FIXED: Use existing variable
              currentToneStyle: _selectedToneStyle,     // ✅ FIXED: Use existing variable
              onSettingsChanged: (taskType, config, voice, toneStyle) {
                setState(() {
                  _currentTaskType = taskType;           // ✅ FIXED: Use existing variable
                  _currentTaskConfig = config;           // ✅ FIXED: Use existing variable
                  _selectedVoice = voice ?? _selectedVoice;              // ✅ FIXED: Use existing variable
                  _selectedToneStyle = toneStyle ?? _selectedToneStyle; // ✅ FIXED: Use existing variable
                });
              },
            ),
          ),
        );
        break;
    }
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

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _addTaskToDay(DateTime day, Map<String, dynamic> taskData) async {
    try {
      if (taskData['id'] == null) {
        taskData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      await _taskStorage.saveTask(taskData);
      
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

  // 🚀 REPLACE your existing _generateMotivation method with this:
  Future<void> _generateMotivation([String? customTask]) async {
    print('🚀 Using ASYNC system - instant response!');
    await _loadUserPreferences();
    
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    
    try {
      final task = customTask ?? _controller.text.trim();
      if (task.isEmpty && customTask == null) return;
      
      print('🎯 Creating async task - Voice: $_selectedVoice, Tone: $_selectedToneStyle');
      
      // 🚀 NEW: Use async system instead of old slow method
      final result = await _api.createTaskAsync(
        taskText: task,
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        voiceStyle: _selectedVoice,
        toneStyle: _selectedToneStyle,
        userName: _userName,
      );
      
      if (result['success'] == true) {
        // ⚡ INSTANT SUCCESS!
        setState(() {
          _generatedLine = result['motivationalText'] ?? 'Task created!';
          _totalMotivations++;
          _motivationStreak++;
          if (_recentMotivations.length >= 5) {
            _recentMotivations.removeAt(0);
          }
          _recentMotivations.add(_generatedLine);
        });

        _motivationController.forward();
        _streakController.forward();
        HapticFeedback.heavyImpact();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Task created instantly! Audio generating in background...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
      } else {
        throw Exception(result['error'] ?? 'Failed to create task');
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🗺️ Helper method to map current voice selection to personalities
  String _mapVoiceToPersonality(String currentVoice) {
    switch (currentVoice) {
      // ✅ EXISTING WORKING MAPPINGS (Keep unchanged)
      case 'male:Professional Male': return 'drill_sergeant';
      case 'male:Default Male': return 'wise_mentor';
      case 'male:Energetic Male': return 'hype_beast';
      case 'female:Energetic Female': return 'sassy_diva';
      case 'female:Default Female': return 'supportive_mom';
      case 'female:Professional Female': return 'queen_boss';
      case 'characters:Lana Croft': return 'lana_croft';
      case 'characters:Argent': return 'argent';
      case 'characters:Baxter Jordan': return 'baxter_jordan';
      case 'characters:Robot Assistant': return 'robot_assistant';

      // 🆕 NEW PERSONALITY MAPPINGS
      // New Male Personalities
      case 'male:Calm Male': return 'chill_surfer';
      case 'characters:British Butler': return 'british_butler';
      case 'male:Sports Announcer': return 'sports_coach';
      
      // New Female Personalities  
      case 'female:Calm Female': return 'zen_goddess';
      case 'female:News Anchor': return 'news_anchor';
      
      // New Character Personalities
      case 'characters:Superhero': return 'superhero';
      case 'characters:Pirate Captain': return 'pirate_captain';
      case 'characters:Game Show Host': return 'game_show_host';
      case 'characters:Wizard Sage': return 'shakespeare';
      case 'characters:Meditation Guru': return 'meditation_guru';
      case 'characters:Drill Instructor': return 'drill_instructor';
      case 'characters:Cheerleader Coach': return 'cheerleader_coach';

      default: return 'drill_sergeant';
    }
  }

  void _selectQuickAction(String action) {
    HapticFeedback.selectionClick();
    _controller.text = action;
    _generateMotivation(action);
  }

  Widget _buildSophisticatedHeader() {
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
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _geometryController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseBeat.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motivator.AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Your AI motivation companion',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                width: 1,
              ),
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
          color: const Color(0xFFD4AF37).withOpacity(0.2),
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
                            Color(0xFFD4AF37),
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
                        fontSize: 11,
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
                            Color(0xFFD4AF37),
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
                        fontSize: 11,
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
    // Unlimited voice system doesn't need manual disposal // 
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
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _geometryController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GeometricPatternPainter(_geometryRotation.value),
                  size: Size.infinite,
                );
              },
            ),
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
                  _buildSophisticatedHeader(),
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
                                          controller: _controller,
                                          currentTaskType: _currentTaskType,
                                          currentTaskConfig: _currentTaskConfig,
                                          loading: _loading,
                                          onGenerateMotivation: _generateMotivation,
                                          generatedLine: _generatedLine,
                                          motivationScale: _motivationScale,
                                          streakBounce: _streakBounce,           // ✅ ADD THIS LINE
                                          streakController: _streakController,   // ✅ ADD THIS LINE TOO  
                                          totalMotivations: _totalMotivations,
                                          motivationStreak: _motivationStreak,
                                          recentMotivations: _recentMotivations,
                                          quickActions: _quickActions,
                                          dailyQuote: _dailyQuote,
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
                                            setState(() => _selectedDay = selectedDay);
                                          },
                                          onTaskAdded: _addTaskToDay,
                                          onGenerateMotivationForTask: _generateMotivationForTask,
                                          onTasksChanged: _handleTasksChanged,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // ✅ NEW: AppBottomNavBar replaces old footer
                  AppBottomNavBar(
                    currentScreen: _currentView == ViewMode.dashboard 
                        ? AppScreen.dashboard 
                        : _currentView == ViewMode.calendar
                            ? AppScreen.calendar
                            : AppScreen.dictaphone,
                    onScreenChanged: _handleAppNavigation, // 🚀 Use the new method
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep your existing GeometricPatternPainter and RefinedParticlePainter classes
class GeometricPatternPainter extends CustomPainter {
  final double progress;
  
  GeometricPatternPainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    for (int i = 0; i < 3; i++) {
      final radius = 50.0 + (i * 80);
      final rotation = progress * 2 * math.pi + (i * math.pi / 4);
      
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(rotation);
      
      final path = Path();
      for (int j = 0; j < 6; j++) {
        final angle = (j * math.pi * 2) / 6;
        final x = radius * math.cos(angle);
        final y = radius * math.sin(angle);
        
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RefinedParticlePainter extends CustomPainter {
  final double progress;
  
  RefinedParticlePainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1) + (i * size.width * 0.04);
      final y = (size.height * 0.3) + 
                (math.sin(progress * 2 * math.pi + i * 0.5) * 40);
      
      canvas.drawCircle(
        Offset(x, y), 
        1.5 + math.sin(progress * 4 * math.pi + i) * 0.5, 
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}