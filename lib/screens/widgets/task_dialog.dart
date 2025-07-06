import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/task_scheduler.dart';
import '../../services/amber_alert_service.dart';
import '../amber_alert_screen.dart';

// 🚨 NUCLEAR OPTION: Global overlay that ALWAYS works
class NuclearLoadingOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, {required bool isAmberAlert}) {
    hide(); // Remove any existing overlay
    
    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isAmberAlert ? Colors.red.shade900 : const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spinning indicator
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAmberAlert ? '🚨 CREATING CRITICAL ALERT' : '⏱️ CREATING REMINDER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isAmberAlert 
                      ? 'Generating emergency-level\nmotivational content...'
                      : 'Generating personalized\nmotivational content...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    '⚠️ Please wait - this may take 5-10 seconds',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Insert the overlay
    Overlay.of(context).insert(_currentOverlay!);
    print('🚨 NUCLEAR OVERLAY: Shown successfully!');
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    print('🚨 NUCLEAR OVERLAY: Hidden successfully!');
  }
}

class UltraResponsiveTaskDialog extends StatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime, Map<String, dynamic>) onTaskAdded;
  final String? currentTaskType;

  const UltraResponsiveTaskDialog({
    Key? key,
    required this.selectedDay,
    required this.onTaskAdded,
    this.currentTaskType,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    DateTime selectedDay,
    Function(DateTime, Map<String, dynamic>) onTaskAdded, {
    String? currentTaskType,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return UltraResponsiveTaskDialog(
          selectedDay: selectedDay,
          onTaskAdded: onTaskAdded,
          currentTaskType: currentTaskType,
        );
      },
    );
  }

  @override
  State<UltraResponsiveTaskDialog> createState() => _UltraResponsiveTaskDialogState();
}

class _UltraResponsiveTaskDialogState extends State<UltraResponsiveTaskDialog> {
  final TextEditingController _taskController = TextEditingController();
  final PageController _pageController = PageController();
  
  // Core settings
  String _selectedVoiceCategory = 'male';
  String _selectedVoiceStyle = 'Default Male'; 
  String _selectedToneStyle = 'Balanced';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isAmberAlert = false;
  
  // Recurring settings
  bool _isRecurring = false;
  String _recurringType = 'daily'; // daily, weekly, monthly
  List<int> _selectedWeekdays = []; // For weekly recurring
  DateTime? _recurringEndDate;
  bool _neverEnds = true;
  
  // Advanced settings
  bool _enableVibration = true;
  String _notificationPriority = 'High';
  
  // UI state
  bool _isCreating = false;
  int _currentPage = 0;

  // Voice catalog from settings_screen.dart - BACKEND-CONNECTED VOICES ONLY
  // COMPLETE Voice catalog from settings_screen.dart - BACKEND-CONNECTED VOICES
  final Map<String, List<Map<String, dynamic>>> _voiceCatalog = {
    'male': [
      {'name': 'Default Male', 'description': 'Clear, professional male voice', 'icon': Icons.person},
      {'name': 'Energetic Male', 'description': 'High-energy, enthusiastic', 'icon': Icons.flash_on},
      {'name': 'Calm Male', 'description': 'Soothing, peaceful delivery', 'icon': Icons.spa},
      {'name': 'Professional Male', 'description': 'Business-ready, authoritative', 'icon': Icons.business},
      {'name': 'Wise Mentor', 'description': 'Experienced, thoughtful guide', 'icon': Icons.school},
      {'name': 'Sports Announcer', 'description': 'Dynamic, exciting commentary', 'icon': Icons.sports},
    ],
    'female': [
      {'name': 'Default Female', 'description': 'Clear, professional female voice', 'icon': Icons.person_outline},
      {'name': 'Energetic Female', 'description': 'High-energy, enthusiastic', 'icon': Icons.flash_on},
      {'name': 'Calm Female', 'description': 'Soothing, peaceful delivery', 'icon': Icons.spa},
      {'name': 'Professional Female', 'description': 'Business-ready, authoritative', 'icon': Icons.business},
      {'name': 'Wise Woman', 'description': 'Maternal, nurturing wisdom', 'icon': Icons.favorite},
      {'name': 'News Anchor', 'description': 'Clear, authoritative reporting', 'icon': Icons.mic},
    ],
    'characters': [
      // Standard Characters
      {'name': 'Robot Assistant', 'description': 'Futuristic AI companion', 'icon': Icons.smart_toy},
      {'name': 'Pirate Captain', 'description': 'Adventurous seafaring spirit', 'icon': Icons.sailing},
      {'name': 'Wizard Sage', 'description': 'Mystical, ancient wisdom', 'icon': Icons.auto_fix_high},
      {'name': 'Superhero', 'description': 'Heroic, inspiring strength', 'icon': Icons.shield},
      {'name': 'Surfer Dude', 'description': 'Laid-back, chill vibes', 'icon': Icons.surfing},
      {'name': 'Southern Belle', 'description': 'Charming, warm hospitality', 'icon': Icons.favorite_border},
      {'name': 'British Butler', 'description': 'Refined, proper etiquette', 'icon': Icons.wine_bar},
      {'name': 'Valley Girl', 'description': 'Bubbly, enthusiastic energy', 'icon': Icons.celebration},
      {'name': 'Game Show Host', 'description': 'Exciting, engaging presenter', 'icon': Icons.emoji_events},
      {'name': 'Meditation Guru', 'description': 'Peaceful, zen guidance', 'icon': Icons.self_improvement},
      {'name': 'Drill Instructor', 'description': 'Military, commanding presence', 'icon': Icons.military_tech},
      {'name': 'Cheerleader Coach', 'description': 'Peppy, encouraging spirit', 'icon': Icons.sports_gymnastics},
      
      // 🎭 YOUR CUSTOM ELEVENLABS VOICES
      {'name': 'Lana Croft', 'description': 'Fearless adventurer, tomb raider spirit', 'icon': Icons.explore},
      {'name': 'Baxter Jordan', 'description': 'Dark analyst, methodical precision', 'icon': Icons.psychology},
      {'name': 'Argent', 'description': 'Advanced AI assistant, JARVIS-like', 'icon': Icons.computer},
    ],
  };

  // Tone styles
  final List<Map<String, dynamic>> _toneStyles = [
    {
      'name': 'Balanced',
      'description': 'Even mix of support and challenge',
      'icon': Icons.balance,
      'color': Colors.blue,
    },
    {
      'name': 'Drill Sergeant',
      'description': 'Tough, no-nonsense motivation',
      'icon': Icons.military_tech,
      'color': Colors.red,
    },
    {
      'name': 'Cheerleader',
      'description': 'Enthusiastic and energetic support',
      'icon': Icons.celebration,
      'color': Colors.pink,
    },
    {
      'name': 'Wise Mentor',
      'description': 'Thoughtful guidance and wisdom',
      'icon': Icons.school,
      'color': Colors.purple,
    },
    {
      'name': 'Best Friend',
      'description': 'Casual, supportive, and understanding',
      'icon': Icons.favorite,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.selectedDay.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _taskController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // 🚨 NUCLEAR VERSION - ONLY ONE _createTask METHOD!
  Future<void> _createTask() async {
    final task = _taskController.text.trim();
    if (task.isEmpty || _isCreating) return;

    print('🚨 NUCLEAR: Starting task creation...');
    
    // 🚨 NUCLEAR OPTION: Show overlay IMMEDIATELY
    NuclearLoadingOverlay.show(context, isAmberAlert: _isAmberAlert);
    
    // Immediate haptic feedback
    HapticFeedback.heavyImpact();
    
    setState(() {
      _isCreating = true;
    });

    try {
      print('🚨 NUCLEAR: Building enhanced task...');
      
      final enhancedTask = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isCompleted': false,
        'completedAt': null,
        'isArchived': false,
        'archivedAt': null,
        'description': task,
        'dateTime': _selectedDateTime,
        'voiceCategory': _selectedVoiceCategory,
        'voiceStyle': _selectedVoiceStyle,
        'toneStyle': _selectedToneStyle,
        'backendVoiceStyle': '$_selectedVoiceCategory:$_selectedVoiceStyle',
        'backendToneStyle': _selectedToneStyle,
        'forceOverrideSilent': _isAmberAlert,
        'enableVibration': _enableVibration,
        'notificationPriority': _isAmberAlert ? 'Max' : _notificationPriority,
        'isAmberAlert': _isAmberAlert,
        'isRecurring': _isRecurring,
        'recurringType': _isRecurring ? _recurringType : null,
        'selectedWeekdays': _isRecurring && _recurringType == 'weekly' ? _selectedWeekdays : null,
        'recurringEndDate': _isRecurring && !_neverEnds ? _recurringEndDate : null,
        'neverEnds': _isRecurring ? _neverEnds : false,
      };

      print('🚨 NUCLEAR: Starting API work...');
      
      // Handle amber alert vs regular task
      if (_isAmberAlert) {
        await _createAmberAlertTask(enhancedTask, task);
      } else {
        await TaskScheduler().scheduleTask(enhancedTask);
      }

      print('🚨 NUCLEAR: API work completed!');

      // Add task and navigate
      widget.onTaskAdded(widget.selectedDay, enhancedTask);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        HapticFeedback.heavyImpact();
        
        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAmberAlert ? '🚨 Critical Alert Created!' : '✅ Reminder Scheduled!'),
            backgroundColor: _isAmberAlert ? Colors.green : const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

    } catch (e) {
      print('❌ NUCLEAR: Error occurred: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      print('🚨 NUCLEAR: Cleaning up...');
      
      // Hide the nuclear overlay
      NuclearLoadingOverlay.hide();
      
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  // Simplified amber alert creation
  Future<void> _createAmberAlertTask(Map<String, dynamic> taskData, String taskDescription) async {
    await TaskScheduler().scheduleTask(taskData);
  }

  // Navigation methods
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0a1428),
              const Color(0xFF16213e),
              const Color(0xFF000000),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isAmberAlert ? Colors.red : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header with progress indicator
            _buildHeader(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildBasicSettingsPage(),
                  _buildVoiceSettingsPage(),
                  _buildAdvancedSettingsPage(),
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isAmberAlert ? Icons.warning : Icons.add_task,
                color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isAmberAlert ? '🚨 Create Critical Alert' : 'Create Reminder',
                  style: TextStyle(
                    color: _isAmberAlert ? Colors.red : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress indicator
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _currentPage 
                          ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37))
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set up your task details',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Task input
            TextField(
              controller: _taskController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'What do you need motivation for?',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                  ),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 20),
            
            // Date/Time picker
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reminder Time',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} at ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Amber Alert Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isAmberAlert ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAmberAlert ? Colors.red : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: _isAmberAlert ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🚨 Emergency Alert Mode',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Bypasses silent mode with emergency-level priority',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAmberAlert,
                    onChanged: (value) {
                      setState(() {
                        _isAmberAlert = value;
                      });
                      HapticFeedback.selectionClick();
                    },
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recurring toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isRecurring ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isRecurring ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat,
                    color: _isRecurring ? const Color(0xFFD4AF37) : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recurring Reminder',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Repeat this reminder automatically',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                      });
                      HapticFeedback.selectionClick();
                    },
                    activeColor: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),
            
            // Recurring options
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              _buildRecurringOptions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat Every:',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Recurring type buttons
        Row(
          children: [
            for (final type in ['daily', 'weekly', 'monthly'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _recurringType = type;
                      });
                      HapticFeedback.selectionClick();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _recurringType == type 
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      type.capitalize(),
                      style: TextStyle(
                        color: _recurringType == type ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Weekly day selection
        if (_recurringType == 'weekly') ...[
          const SizedBox(height: 12),
          const Text(
            'Select Days:',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildWeekdaySelector(),
        ],
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWeekdaySelector() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      children: [
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedWeekdays.contains(i + 1)) {
                      _selectedWeekdays.remove(i + 1);
                    } else {
                      _selectedWeekdays.add(i + 1);
                    }
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedWeekdays.contains(i + 1)
                        ? const Color(0xFFD4AF37)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    weekdays[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedWeekdays.contains(i + 1) ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voice & Personality',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your motivational coach',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Voice category selection
                  const Text(
                    'Voice Category:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      for (final category in ['male', 'female', 'characters'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedVoiceCategory = category;
                                  // Set default voice for the category
                                  if (_voiceCatalog[category]!.isNotEmpty) {
                                    _selectedVoiceStyle = _voiceCatalog[category]!.first['name'];
                                  }
                                });
                                HapticFeedback.selectionClick();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedVoiceCategory == category 
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white.withOpacity(0.1),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                category == 'characters' ? 'Character' : category.capitalize(),
                                style: TextStyle(
                                  color: _selectedVoiceCategory == category ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Voice style selection
                  const Text(
                    'Voice Personality:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  ...(_voiceCatalog[_selectedVoiceCategory] ?? []).map((voice) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVoiceStyle = voice['name'];
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedVoiceStyle == voice['name'] 
                                ? const Color(0xFFD4AF37).withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedVoiceStyle == voice['name'] 
                                  ? const Color(0xFFD4AF37)
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                voice['icon'] as IconData,
                                color: _selectedVoiceStyle == voice['name'] 
                                    ? const Color(0xFFD4AF37)
                                    : Colors.grey[400],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voice['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      voice['description'],
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedVoiceStyle == voice['name'])
                                const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 20),
                  
                  // Tone style selection
                  const Text(
                    'Motivational Tone:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  ...(_toneStyles).map((tone) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedToneStyle = tone['name'];
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedToneStyle == tone['name'] 
                                ? (tone['color'] as Color).withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedToneStyle == tone['name'] 
                                  ? (tone['color'] as Color)
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                tone['icon'] as IconData,
                                color: tone['color'] as Color,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tone['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      tone['description'],
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedToneStyle == tone['name'])
                                Icon(Icons.check_circle, color: tone['color'] as Color),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fine-tune your experience',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Vibration toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.vibration,
                  color: _enableVibration ? const Color(0xFFD4AF37) : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enable Vibration',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Vibrate device when reminder triggers',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enableVibration,
                  onChanged: (value) {
                    setState(() {
                      _enableVibration = value;
                    });
                    HapticFeedback.selectionClick();
                  },
                  activeColor: const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Notification priority
          const Text(
            'Notification Priority:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              for (final priority in ['Low', 'Normal', 'High'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: _isAmberAlert ? null : () {
                        setState(() {
                          _notificationPriority = priority;
                        });
                        HapticFeedback.selectionClick();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _notificationPriority == priority 
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: _notificationPriority == priority ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          if (_isAmberAlert) ...[
            const SizedBox(height: 8),
            Text(
              '🚨 Amber alerts always use Maximum priority',
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const Spacer(),
          
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '📝 Task: ${_taskController.text.isEmpty ? "Not set" : _taskController.text}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                Text(
                  '🎭 Voice: $_selectedVoiceStyle',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                Text(
                  '🎯 Tone: $_selectedToneStyle',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                Text(
                  '⏰ Time: ${_selectedDateTime.day}/${_selectedDateTime.month} at ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                if (_isRecurring)
                  Text(
                    '🔁 Repeats: $_recurringType',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                if (_isAmberAlert)
                  const Text(
                    '🚨 Emergency Alert Mode: ON',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: TextButton(
                onPressed: _previousPage,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isCreating ? null : (_currentPage < 2 ? _nextPage : _createTask),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentPage < 2 
                          ? 'Next'
                          : (_isAmberAlert ? '🚨 Create Alert' : '✅ Create Reminder'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
              onPrimary: Colors.white,
              surface: const Color(0xFF1a1a2e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                onPrimary: Colors.white,
                surface: const Color(0xFF1a1a2e),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        HapticFeedback.selectionClick();
      }
    }
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}