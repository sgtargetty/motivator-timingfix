import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/task_scheduler.dart';
import '../../services/amber_alert_service.dart';
import '../amber_alert_screen.dart';

class TaskDialog extends StatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime, Map<String, dynamic>) onTaskAdded;
  final String? currentTaskType;

  const TaskDialog({
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
        return TaskDialog(
          selectedDay: selectedDay,
          onTaskAdded: onTaskAdded,
          currentTaskType: currentTaskType,
        );
      },
    );
  }

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final TextEditingController _taskController = TextEditingController();

  String _selectedVoiceCategory = 'male';
  String _selectedVoiceStyle = 'Default Male'; 
  String _selectedToneStyle = 'Cheerleader';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _forceOverrideSilent = false;
  bool _enableVibration = true;
  String _notificationPriority = 'High';

  bool _isAmberAlert = false;
  bool _isCreatingTask = false;
  bool _isRecurring = false;
  String _recurringFrequency = 'Weekly';
  Set<int> _selectedDays = <int>{DateTime.now().weekday};
  DateTime? _recurringEndDate;
  bool _neverEnds = true;

  // EXACT SAME VOICE CATALOG AS SETTINGS SCREEN
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
      // CUSTOM ELEVENLABS VOICES
      {'name': 'Lana Croft', 'description': 'Adventure hero, tomb raider spirit', 'icon': Icons.explore},
      {'name': 'Baxter Jordan', 'description': 'Dark analyst, methodical precision', 'icon': Icons.psychology_alt},
      {'name': 'Argent', 'description': 'Advanced AI assistant, JARVIS-like', 'icon': Icons.android},
    ],
  };

  final List<Map<String, dynamic>> _toneStyles = [
    {'name': 'Balanced', 'description': 'Even mix of support and challenge', 'color': Colors.blue, 'icon': Icons.balance},
    {'name': 'Drill Sergeant', 'description': 'Tough & commanding', 'color': Colors.red, 'icon': Icons.military_tech},
    {'name': 'Cheerleader', 'description': 'Positive & enthusiastic', 'color': Colors.pink, 'icon': Icons.celebration},
    {'name': 'Sage', 'description': 'Wise & philosophical', 'color': Colors.purple, 'icon': Icons.psychology},
    {'name': 'Coach', 'description': 'Goal-focused support', 'color': Colors.green, 'icon': Icons.sports},
    {'name': 'Friend', 'description': 'Casual & encouraging', 'color': Colors.orange, 'icon': Icons.people},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.selectedDay.add(const Duration(hours: 1));
    _selectedDays = <int>{DateTime.now().weekday};
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _createTask() async {
    final task = _taskController.text.trim();
    if (task.isNotEmpty && !_isCreatingTask) {
      setState(() {
        _isCreatingTask = true;
      });
      
      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAmberAlert ? '🚨 Creating Critical Alert...' : '⏱️ Creating Reminder...'),
          backgroundColor: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
          duration: const Duration(seconds: 1),
        ),
      );

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
        
        // Backend compatible format
        'backendVoiceStyle': '$_selectedVoiceCategory:$_selectedVoiceStyle',
        'backendToneStyle': _selectedToneStyle,
        'forceOverrideSilent': _forceOverrideSilent,
        'enableVibration': _enableVibration,
        'notificationPriority': _notificationPriority,
        'isAmberAlert': _isAmberAlert,
        
        'isRecurring': _isRecurring,
        'recurringFrequency': _isRecurring ? _recurringFrequency : null,
        'selectedDays': _isRecurring ? _selectedDays.toList() : null,
        'recurringEndDate': _isRecurring && !_neverEnds ? _recurringEndDate : null,
        'neverEnds': _isRecurring ? _neverEnds : false,
      };
      
      try {
        // Handle amber alert tasks differently
        if (_isAmberAlert) {
          await _createAmberAlertTask(enhancedTask, task);
        } else {
          // Regular task scheduling
          await TaskScheduler.instance.scheduleNotification(
            enhancedTask, 
            context,
            currentTaskType: widget.currentTaskType,
          );
        }
        
        // ✅ Only add task and navigate if everything succeeded
        widget.onTaskAdded(widget.selectedDay, enhancedTask);
        
        Navigator.of(context).pop();
        HapticFeedback.heavyImpact();
        
        final alertType = _isAmberAlert ? ' (🚨 AMBER ALERT)' : '';
        final recurringText = _isRecurring 
            ? ' (${_recurringFrequency.toLowerCase()}${_recurringFrequency == 'Weekly' ? ' on ${_selectedDays.map(_getDayName).join(', ')}' : ''})'
            : '';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $_selectedVoiceStyle reminder scheduled$alertType$recurringText'),
            backgroundColor: _isAmberAlert ? Colors.green : const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
      } catch (e) {
        print('❌ Error in _createTask: $e');
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to create task: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Don't navigate or add task on error
        
      } finally {
        // ✅ ALWAYS reset loading state, even on errors
        if (mounted) {
          setState(() {
            _isCreatingTask = false;
          });
        }
      }
    }
  }

// Handle amber alert task creation with proper emergency system integration
Future<void> _createAmberAlertTask(Map<String, dynamic> taskData, String taskDescription) async {
  print('🚨 Starting _createAmberAlertTask...');
  
  try {
    // 1. Show immediate progress - AI content generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Step 1/3: Generating motivational content...'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Small delay to show the progress message
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 2. Show audio generation progress
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Step 2/3: Creating emergency audio...'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    
    print('🚨 Creating AMBER ALERT task with emergency system integration');
    
    // 3. Create the scheduled notification (this is the slow part)
    print('🔄 About to call TaskScheduler.scheduleNotification...');
    await TaskScheduler.instance.scheduleNotification(
      taskData, 
      context,
      currentTaskType: widget.currentTaskType,
    );
    print('✅ TaskScheduler.scheduleNotification completed');
    
    print('🚨 Amber alert scheduled for: $_selectedDateTime');
    
    // 4. Show final success message
    print('🔄 About to show success snackbar...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Step 3/3: Critical Alert Created Successfully!'),
        backgroundColor: Colors.green,  // Green for final success
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
    print('✅ Success snackbar shown');
    
  } catch (e, stackTrace) {
    print('❌ Exception in _createAmberAlertTask: $e');
    print('📍 Stack trace: $stackTrace');
    
    // Show error message
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create critical alert: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e2) {
      print('❌ Even the error snackbar failed: $e2');
    }
    
    // 🚨 CRITICAL FIX: Rethrow the exception so _createTask knows it failed
    rethrow;
  }
  
  print('✅ _createAmberAlertTask method completed');
}
  
  print('✅ _createAmberAlertTask method completed');
}

  // Show amber alert screen directly (for testing or immediate alerts)
  void _showAmberAlertScreen({String? taskDescription}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AmberAlertScreen(
          title: '🚨 CRITICAL TASK ALERT 🚨',
          message: 'You have created an emergency-priority motivational task that requires immediate attention!',
          taskDescription: taskDescription ?? _taskController.text.trim(),
          payload: {
            'alertType': 'task_creation',
            'priority': 'emergency',
            'source': 'task_dialog',
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // Show preview of amber alert without full emergency mode
  void _showAmberAlertPreview(String taskDescription) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              '🚨 AMBER ALERT PREVIEW',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your amber alert has been scheduled and will appear as:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMERGENCY TASK:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    taskDescription,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scheduled: ${_formatDateAmerican(_selectedDateTime)} at ${_formatTimeAmerican(_selectedDateTime)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ This will create a full-screen emergency alert with vibration and override silent mode.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAmberAlertScreen(taskDescription: taskDescription);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('Preview Full Alert', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Handle both 1-7 (Mon-Sun) and 7,1-6 (Sun,Mon-Sat) formats
    if (weekday == 7) return 'Sun';
    return days[weekday - 1];
  }

  void _selectVoiceCategory(String category) {
    setState(() {
      _selectedVoiceCategory = category;
      // Set default voice for the category
      if (_voiceCatalog[category]!.isNotEmpty) {
        _selectedVoiceStyle = _voiceCatalog[category]!.first['name'];
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a1428), // Navy
              Color(0xFF16213e),
              Color(0xFF000000), // Black
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isAmberAlert 
                ? Colors.red.withOpacity(0.5)
                : const Color(0xFFD4AF37).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildAmberAlertToggle(),
              const SizedBox(height: 20),
              _buildTaskDescriptionSection(),
              const SizedBox(height: 20),
              _buildDateTimeSection(),
              const SizedBox(height: 20),
              _buildRecurringSection(),
              const SizedBox(height: 20),
              _buildVoiceSection(),
              const SizedBox(height: 20),
              _buildToneStyleSection(),
              const SizedBox(height: 20),
              _buildNotificationSettingsSection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper functions for American date/time formatting
  String _formatDateAmerican(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month/$day/$year';
  }

  String _formatTimeAmerican(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isAmberAlert 
                  ? [Colors.red, Colors.orange]
                  : [const Color(0xFFD4AF37), const Color(0xFFFFD700)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _isAmberAlert ? Icons.warning : Icons.notification_add,
            color: _isAmberAlert ? Colors.white : Colors.black,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAmberAlert 
                    ? '🚨 Create Critical Alert'
                    : 'Create Motivational Reminder',
                style: TextStyle(
                  color: _isAmberAlert ? Colors.red : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                'For ${_formatDateAmerican(widget.selectedDay)}',
                style: const TextStyle(
                  color: Color(0xFF8B9DC3),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmberAlertToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAmberAlert 
            ? Colors.red.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAmberAlert 
              ? Colors.red
              : Colors.white.withOpacity(0.2),
          width: 1,
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
                  '🚨 Amber Alert Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Emergency-level alert that bypasses all settings',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAmberAlert,
            onChanged: (value) {
              setState(() {
                _isAmberAlert = value;
                if (value) {
                  _forceOverrideSilent = true;
                  _enableVibration = true;
                  _notificationPriority = 'Max';
                }
              });
            },
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDescriptionSection() {
    return _buildDialogSection(
      'What do you need motivation for?',
      Icons.psychology,
      _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
      TextField(
        controller: _taskController,
        style: const TextStyle(color: Colors.white),
        maxLines: 2,
        decoration: InputDecoration(
          hintText: _isAmberAlert 
              ? 'e.g., CRITICAL: Must finish project by deadline!'
              : 'e.g., Go for a morning run, Study for exam...',
          hintStyle: const TextStyle(color: Color(0xFF8B9DC3)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
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
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return _buildDialogSection(
      'When should we remind you?',
      Icons.schedule,
      _isAmberAlert ? Colors.red : Colors.blue,
      GestureDetector(
        onTap: () async {
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
                    surface: const Color(0xFF0a1428),
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
                      surface: const Color(0xFF0a1428),
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
            }
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_isAmberAlert ? Colors.red : Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_isAmberAlert ? Colors.red : Colors.blue).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: _isAmberAlert ? Colors.red : Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDateAmerican(_selectedDateTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      _formatTimeAmerican(_selectedDateTime),
                      style: const TextStyle(
                        color: Color(0xFF8B9DC3),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit, color: _isAmberAlert ? Colors.red : Colors.blue, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringSection() {
    return _buildDialogSection(
      'Recurring reminder',
      Icons.repeat,
      _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
      Column(
        children: [
          // Recurring toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isRecurring 
                  ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isRecurring 
                    ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37))
                    : Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: _isRecurring ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)) : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Repeat this reminder',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Set up recurring motivational reminders',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
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
                  },
                  activeColor: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
          
          // Recurring options (show when enabled)
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            
            // Frequency selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequency',
                    style: TextStyle(
                      color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Daily', 'Weekly', 'Monthly'].map((freq) {
                      final isSelected = _recurringFrequency == freq;
                      final color = _isAmberAlert ? Colors.red : const Color(0xFFD4AF37);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _recurringFrequency = freq;
                              // Reset selected days when changing frequency
                              if (freq == 'Daily') {
                                _selectedDays = {1, 2, 3, 4, 5, 6, 7}; // All days
                              } else if (freq == 'Weekly') {
                                _selectedDays = {DateTime.now().weekday}; // Current day
                              } else {
                                _selectedDays = {DateTime.now().day}; // Current day of month
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? color.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected 
                                    ? color
                                    : Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              freq,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? color : Colors.grey,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Day selection (for Weekly)
            if (_recurringFrequency == 'Weekly') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Days',
                      style: TextStyle(
                        color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Days of week
                        {'day': 'S', 'value': 7}, // Sunday
                        {'day': 'M', 'value': 1}, // Monday
                        {'day': 'T', 'value': 2}, // Tuesday
                        {'day': 'W', 'value': 3}, // Wednesday
                        {'day': 'T', 'value': 4}, // Thursday
                        {'day': 'F', 'value': 5}, // Friday
                        {'day': 'S', 'value': 6}, // Saturday
                      ].map((dayData) {
                        final dayNum = dayData['value'] as int;
                        final dayLetter = dayData['day'] as String;
                        final isSelected = _selectedDays.contains(dayNum);
                        final color = _isAmberAlert ? Colors.red : const Color(0xFFD4AF37);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedDays.remove(dayNum);
                              } else {
                                _selectedDays.add(dayNum);
                              }
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? color 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? color 
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                dayLetter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            
            // End date options
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End Date',
                    style: TextStyle(
                      color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.all_inclusive,
                        color: _neverEnds ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)) : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Never ends',
                          style: TextStyle(
                            color: _neverEnds ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)) : Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Switch(
                        value: _neverEnds,
                        onChanged: (value) {
                          setState(() {
                            _neverEnds = value;
                            if (!value && _recurringEndDate == null) {
                              _recurringEndDate = DateTime.now().add(const Duration(days: 30));
                            }
                          });
                        },
                        activeColor: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                      ),
                    ],
                  ),
                  if (!_neverEnds) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _recurringEndDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                                  onPrimary: Colors.white,
                                  surface: const Color(0xFF0a1428),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            _recurringEndDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ends on: ${_recurringEndDate != null ? _formatDateAmerican(_recurringEndDate!) : 'Select date'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit,
                              color: Color(0xFF8B9DC3),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceSection() {
    return _buildDialogSection(
      'Voice & Character',
      Icons.record_voice_over,
      _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice Category Selection
          Row(
            children: [
              Expanded(
                child: _buildCategoryChip('male', 'Male', Icons.man, const Color(0xFFD4AF37)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryChip('female', 'Female', Icons.woman, const Color(0xFFD4AF37)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryChip('characters', 'Characters', Icons.theater_comedy, const Color(0xFFD4AF37)),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Voice Style Selection
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: (_voiceCatalog[_selectedVoiceCategory] ?? []).map((voice) {
                  final isSelected = _selectedVoiceStyle == voice['name'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD4AF37).withOpacity(0.1)
                          : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF8B9DC3).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          voice['icon'],
                          color: const Color(0xFFD4AF37),
                          size: 16,
                        ),
                      ),
                      title: Text(
                        voice['name'],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        voice['description'],
                        style: TextStyle(
                          color: const Color(0xFF8B9DC3).withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 16)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedVoiceStyle = voice['name']);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon, Color color) {
    final isSelected = _selectedVoiceCategory == category;
    
    return GestureDetector(
      onTap: () => _selectVoiceCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFD700)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF8B9DC3).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : const Color(0xFF8B9DC3),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF8B9DC3),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneStyleSection() {
    return _buildDialogSection(
      'Pick your motivation intensity',
      Icons.psychology,
      _isAmberAlert ? Colors.red : Colors.purple,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _toneStyles.map((tone) {
          final isSelected = _selectedToneStyle == tone['name'];
          final toneColor = _isAmberAlert ? Colors.red : tone['color'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedToneStyle = tone['name'];
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? toneColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? toneColor
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tone['icon'],
                    color: isSelected ? toneColor : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tone['name'],
                    style: TextStyle(
                      color: isSelected ? toneColor : Colors.grey,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationSettingsSection() {
    return _buildDialogSection(
      'Alert settings',
      Icons.notifications_active,
      _isAmberAlert ? Colors.red : Colors.red,
      Column(
        children: [
          // Force through silent toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _forceOverrideSilent 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _forceOverrideSilent 
                    ? Colors.red
                    : Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.volume_up,
                  color: _forceOverrideSilent ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Override Silent Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Play motivation even when phone is silent',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _forceOverrideSilent,
                  onChanged: _isAmberAlert ? null : (value) {
                    setState(() {
                      _forceOverrideSilent = value;
                    });
                  },
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Vibration toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _enableVibration 
                  ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _enableVibration 
                    ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37))
                    : Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.vibration,
                  color: _enableVibration ? (_isAmberAlert ? Colors.red : const Color(0xFFD4AF37)) : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vibration Alert',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Vibrate phone when reminder triggers',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enableVibration,
                  onChanged: _isAmberAlert ? null : (value) {
                    setState(() {
                      _enableVibration = value;
                    });
                  },
                  activeColor: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Priority selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_isAmberAlert ? Colors.red : Colors.yellow).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_isAmberAlert ? Colors.red : Colors.yellow).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.priority_high, color: _isAmberAlert ? Colors.red : Colors.yellow),
                    const SizedBox(width: 12),
                    const Text(
                      'Notification Priority',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Low', 'Normal', 'High', 'Max'].map((priority) {
                    final isSelected = _notificationPriority == priority;
                    final colors = {
                      'Low': Colors.grey,
                      'Normal': Colors.blue,
                      'High': Colors.orange,
                      'Max': Colors.red,
                    };
                    final priorityColor = _isAmberAlert ? Colors.red : colors[priority]!;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: _isAmberAlert ? null : () {
                          setState(() {
                            _notificationPriority = priority;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: (_isAmberAlert && priority == 'Max') || isSelected 
                                ? priorityColor.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (_isAmberAlert && priority == 'Max') || isSelected 
                                  ? priorityColor
                                  : Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            priority,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: (_isAmberAlert && priority == 'Max') || isSelected 
                                  ? priorityColor
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: (_isAmberAlert && priority == 'Max') || isSelected 
                                  ? FontWeight.w500 
                                  : FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isCreatingTask ? null : _createTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isCreatingTask 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _isAmberAlert ? Icons.warning : Icons.add_task, 
                      color: _isAmberAlert ? Colors.white : Colors.black,
                    ),
                const SizedBox(width: 8),
                Text(
                  _isCreatingTask 
                    ? 'Creating...'
                    : (_isAmberAlert ? 'Create Critical Alert' : 'Create Reminder'),
                  style: TextStyle(
                    color: _isAmberAlert ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogSection(String title, IconData icon, Color color, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}