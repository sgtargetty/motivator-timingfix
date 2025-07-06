// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_bottom_navbar.dart';
import '../services/reflection_settings_service.dart';
import '../services/privacy_control_service.dart';
import '../screens/learning_debug_screen.dart';


class SettingsScreen extends StatefulWidget {
  final String? currentTaskType;
  final Map<String, dynamic>? currentTaskConfig;
  final String? currentVoice;
  final String? currentToneStyle;
  final Function(String?, Map<String, dynamic>?, String?, String?) onSettingsChanged;

  const SettingsScreen({
    Key? key,
    required this.currentTaskType,
    required this.currentTaskConfig,
    this.currentVoice,
    this.currentToneStyle,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Settings state
  bool _notificationsEnabled = true;
  bool _bypassSilentMode = false;
  bool _hapticFeedback = true;
  bool _dailyReminders = true;
  String _reminderTime = '9:00 AM';
  String _userName = 'Champion';
  String? _selectedTaskType;

  // Controllers for the name input
  late TextEditingController _nameController;

  // Enhanced voice settings
  String _selectedVoiceCategory = 'male';
  String _selectedVoiceStyle = 'Default Male';
  String _selectedToneStyle = 'Balanced';

  // 🎭 NEW: Reflection settings
  final ReflectionSettingsService _reflectionSettings = ReflectionSettingsService();
  bool _hasShownReflectionOnboarding = false;

  // Task type options
  final Map<String, Map<String, dynamic>> _taskTypeOptions = {
    'Study': {
      'icon': Icons.school,
      'color': Colors.blue,
      'gradient': <Color>[Colors.blue, Colors.indigo],
    },
    'Exercise': {
      'icon': Icons.fitness_center,
      'color': Colors.red,
      'gradient': <Color>[Colors.red, Colors.deepOrange],
    },
    'Work': {
      'icon': Icons.work,
      'color': Colors.green,
      'gradient': <Color>[Colors.green, Colors.teal],
    },
    'Eat': {
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'gradient': <Color>[Colors.orange, Colors.amber],
    },
    'Sleep': {
      'icon': Icons.bedtime,
      'color': Colors.purple,
      'gradient': <Color>[Colors.purple, Colors.deepPurple],
    },
  };

  // Tone style options
  final List<Map<String, dynamic>> _toneStyles = [
    {
      'name': 'Balanced',
      'description': 'Even mix of support and challenge',
      'icon': Icons.balance,
      'color': Colors.blue,
      'example': '"You\'ve got this! Take it step by step."',
    },
    {
      'name': 'Drill Sergeant',
      'description': 'Tough, no-nonsense motivation',
      'icon': Icons.military_tech,
      'color': Colors.red,
      'example': '"Drop and give me 20! No excuses!"',
    },
    {
      'name': 'Cheerleader',
      'description': 'Enthusiastic and bubbly',
      'icon': Icons.celebration,
      'color': Colors.pink,
      'example': '"You\'re amazing! Go team YOU! 🎉"',
    },
    {
      'name': 'Sage',
      'description': 'Wise and philosophical',
      'icon': Icons.psychology,
      'color': Colors.purple,
      'example': '"Like water flowing over stone, persistence shapes success."',
    },
    {
      'name': 'Coach',
      'description': 'Strategic and goal-focused',
      'icon': Icons.sports,
      'color': Colors.green,
      'example': '"Let\'s break this down into manageable steps."',
    },
    {
      'name': 'Friend',
      'description': 'Casual and encouraging',
      'icon': Icons.person,
      'color': Colors.orange,
      'example': '"Hey, you\'ve totally got this! I believe in you."',
    },
  ];

  // Voice catalog
  final Map<String, List<Map<String, dynamic>>> _voiceCatalog = {
    'male': [
      {'name': 'Default Male', 'description': 'Classic, reliable voice', 'icon': Icons.man},
      {'name': 'Energetic Male', 'description': 'High-energy, dynamic', 'icon': Icons.bolt},
      {'name': 'Calm Male', 'description': 'Peaceful, soothing', 'icon': Icons.spa},
      {'name': 'Professional Male', 'description': 'Authoritative, clear', 'icon': Icons.business},
    ],
    'female': [
      {'name': 'Default Female', 'description': 'Warm, encouraging voice', 'icon': Icons.woman},
      {'name': 'Energetic Female', 'description': 'Vibrant, enthusiastic', 'icon': Icons.star},
      {'name': 'Calm Female', 'description': 'Gentle, reassuring', 'icon': Icons.favorite},
      {'name': 'Professional Female', 'description': 'Confident, polished', 'icon': Icons.work_outline},
    ],
    'characters': [
      {'name': 'Pirate Captain', 'description': 'Adventurous seafaring spirit', 'icon': Icons.sailing},
      {'name': 'Robot Assistant', 'description': 'Logical, efficient helper', 'icon': Icons.smart_toy},
      {'name': 'Wizard Sage', 'description': 'Mystical, ancient wisdom', 'icon': Icons.auto_fix_high},
      {'name': 'Drill Instructor', 'description': 'Military precision motivation', 'icon': Icons.military_tech},
      {'name': 'Life Coach', 'description': 'Professional development focus', 'icon': Icons.psychology_alt},
      {'name': 'Superhero', 'description': 'Heroic inspiration and power', 'icon': Icons.flash_on},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    _loadUserPreferences();
    _loadCurrentSettings();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _bypassSilentMode = prefs.getBool('bypass_silent_mode') ?? false;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _dailyReminders = prefs.getBool('daily_reminders') ?? true;
      _reminderTime = prefs.getString('reminder_time') ?? '9:00 AM';
      _hasShownReflectionOnboarding = prefs.getBool('reflection_onboarding_shown') ?? false;
    });
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Champion';
    });
    
    _nameController = TextEditingController(text: _userName);
    _nameController.addListener(() {
      setState(() {
        _userName = _nameController.text;
      });
    });
  }

  void _loadCurrentSettings() {
    _selectedTaskType = widget.currentTaskType;
    
    if (widget.currentVoice != null) {
      _parseVoiceSetting(widget.currentVoice!);
    }
    
    _selectedToneStyle = widget.currentToneStyle ?? 'Balanced';
  }

  void _parseVoiceSetting(String voiceSetting) {
    if (voiceSetting.contains(':')) {
      final parts = voiceSetting.split(':');
      _selectedVoiceCategory = parts[0];
      _selectedVoiceStyle = parts[1];
    } else {
      if (voiceSetting.contains('Female') || voiceSetting.contains('Woman')) {
        _selectedVoiceCategory = 'female';
      } else if (voiceSetting.contains('Robot') || voiceSetting.contains('Pirate')) {
        _selectedVoiceCategory = 'characters';
      } else {
        _selectedVoiceCategory = 'male';
      }
      _selectedVoiceStyle = voiceSetting;
    }
  }

  void _selectVoiceCategory(String category) {
    setState(() {
      _selectedVoiceCategory = category;
      if (_voiceCatalog[category]!.isNotEmpty) {
        _selectedVoiceStyle = _voiceCatalog[category]!.first['name'];
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
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
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildSettingsContent(),
                      ),
                    );
                  },
                ),
              ),
              AppBottomNavBar(currentScreen: AppScreen.settings),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings,
              color: Color(0xFFD4AF37),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 Personalization section
          _buildSectionHeader('Personalization'),
          _buildPersonalizationSection(),
          const SizedBox(height: 20),

          // 📋 Task Type section
          _buildSectionHeader('Default Task Focus'),
          _buildTaskTypeSection(),
          const SizedBox(height: 20),

          // 🎤 Voice section
          _buildSectionHeader('Voice & Character'),
          _buildVoiceSection(),
          const SizedBox(height: 20),

          // 🎭 Tone section
          _buildSectionHeader('Motivational Tone'),
          _buildToneStyleSection(),
          const SizedBox(height: 20),
          
          // 🎭 NEW: Smart Reflections section  
          _buildSectionHeader('Smart Reflections'),
          ReflectionSettingsSection(),
          const SizedBox(height: 20),
          
          // 🛡️ NEW: Privacy & AI Controls Section
          _buildSectionHeader('Privacy & AI Controls'),
          PrivacyControlsSection(),
          const SizedBox(height: 20),
          
          // 📱 Notification section
          _buildSectionHeader('Notifications'),
          _buildNotificationSection(),
          const SizedBox(height: 20),

          // ⏰ Daily Reminders section
          _buildSectionHeader('Daily Reminders'),
          _buildDailyRemindersSection(),
          const SizedBox(height: 20),
          
          // ⚙️ Advanced section
          _buildSectionHeader('Advanced'),
          _buildAdvancedSection(),
          const SizedBox(height: 30),
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection() {
    return _buildSettingsCard(
      title: 'Your Identity',
      icon: Icons.person,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should I call you?',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B9DC3).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter your name...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.badge,
                  color: const Color(0xFFD4AF37).withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeSection() {
    return _buildSettingsCard(
      title: 'Task Focus',
      icon: Icons.track_changes,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your primary focus area:',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _taskTypeOptions.entries.map((entry) {
              final taskType = entry.key;
              final config = entry.value;
              final isSelected = _selectedTaskType == taskType;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTaskType = isSelected ? null : taskType;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? config['color'].withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? config['color']
                          : const Color(0xFF8B9DC3).withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config['icon'],
                        color: isSelected ? config['color'] : const Color(0xFF8B9DC3),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        taskType,
                        style: TextStyle(
                          color: isSelected ? config['color'] : const Color(0xFF8B9DC3),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w300,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSection() {
    return _buildSettingsCard(
      title: 'Voice Settings',
      icon: Icons.record_voice_over,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice Category',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
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
          
          const SizedBox(height: 20),
          
          Text(
            'Voice Style',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          
          ...(_voiceCatalog[_selectedVoiceCategory] ?? []).map((voice) {
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
                      : const Color(0xFF8B9DC3).withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  voice['icon'],
                  color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8B9DC3),
                  size: 20,
                ),
                title: Text(
                  voice['name'],
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  voice['description'],
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedVoiceStyle = voice['name'];
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon, Color color) {
    final isSelected = _selectedVoiceCategory == category;
    
    return GestureDetector(
      onTap: () => _selectVoiceCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF8B9DC3).withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : const Color(0xFF8B9DC3),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : const Color(0xFF8B9DC3),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneStyleSection() {
    return _buildSettingsCard(
      title: 'Motivational Style',
      icon: Icons.psychology,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How should I motivate you?',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          
          ...(_toneStyles.map((tone) {
            final isSelected = _selectedToneStyle == tone['name'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? tone['color'].withOpacity(0.1)
                    : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? tone['color']
                      : const Color(0xFF8B9DC3).withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  tone['icon'],
                  color: isSelected ? tone['color'] : const Color(0xFF8B9DC3),
                  size: 24,
                ),
                title: Text(
                  tone['name'],
                  style: TextStyle(
                    color: isSelected ? tone['color'] : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      tone['description'],
                      style: TextStyle(
                        color: const Color(0xFF8B9DC3).withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tone['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tone['example'],
                        style: TextStyle(
                          color: tone['color'],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: tone['color'], size: 24)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedToneStyle = tone['name'];
                  });
                  HapticFeedback.selectionClick();
                },
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications,
      color: const Color(0xFFD4AF37),
      child: Column(
        children: [
          _buildToggleOption(
            'Enable Notifications',
            'Receive motivational reminders',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
            Icons.notifications_active,
          ),
          const SizedBox(height: 16),
          _buildToggleOption(
            'Override Silent Mode',
            'Play audio even when phone is on silent',
            _bypassSilentMode,
            (value) => setState(() => _bypassSilentMode = value),
            Icons.volume_up,
          ),
          const SizedBox(height: 16),
          _buildToggleOption(
            'Haptic Feedback',
            'Feel vibrations for interactions',
            _hapticFeedback,
            (value) => setState(() => _hapticFeedback = value),
            Icons.vibration,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRemindersSection() {
    return _buildSettingsCard(
      title: 'Daily Reminders',
      icon: Icons.schedule,
      color: const Color(0xFFD4AF37),
      child: Column(
        children: [
          _buildToggleOption(
            'Daily Motivation',
            'Get a daily dose of motivation',
            _dailyReminders,
            (value) => setState(() => _dailyReminders = value),
            Icons.wb_sunny,
          ),
          if (_dailyReminders) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, color: const Color(0xFF8B9DC3), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reminder Time',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _reminderTime,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showTimePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
  return _buildSettingsCard(
    title: 'Advanced',
    icon: Icons.settings,
    color: Colors.grey,
    child: Column(
      children: [
        _buildActionButton(
          'Export Data',
          'Download your settings and data',
          Icons.download,
          Colors.blue,
          () => _exportData(),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Privacy Policy',
          'View our privacy and data policies',
          Icons.privacy_tip,
          Colors.green,
          () => _openPrivacyPolicy(),
        ),
        const SizedBox(height: 12),
        // 🧠 NEW: Add debug screen access
        _buildActionButton(
          'AI Learning Debug',
          'View learning patterns and test responses',
          Icons.psychology,
          const Color(0xFFD4AF37),
          () => _openLearningDebug(),
        ),
        if (!_hasShownReflectionOnboarding) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            'Smart Reflections Tour',
            'Learn about AI check-ins',
            Icons.tour,
            Color(0xFFD4AF37),
            () => _showReflectionOnboarding(),
          ),
        ],
      ],
    ),
  );
}

// Add this new method to handle debug screen navigation:
void _openLearningDebug() {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const LearningDebugScreen(),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: Container(
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
            child: child,
          ),
        );
      },
    ),
  );
}

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B9DC3), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFD4AF37),
          activeTrackColor: const Color(0xFFD4AF37).withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saveSettings,
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Text(
                    'Save Settings',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(_reminderTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1F2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _reminderTime = _formatTime(picked);
      });
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    if (parts[1] == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts[1] == 'AM' && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    
    return '$displayHour:$minute $period';
  }

  Future<void> _saveSettings() async {
    HapticFeedback.heavyImpact();
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save all settings
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('bypass_silent_mode', _bypassSilentMode);
    await prefs.setBool('haptic_feedback', _hapticFeedback);
    await prefs.setBool('daily_reminders', _dailyReminders);
    await prefs.setString('reminder_time', _reminderTime);
    
    if (_userName.trim().isNotEmpty) {
      await prefs.setString('user_name', _userName.trim());
    }
    
    final updatedConfig = _selectedTaskType != null 
        ? _taskTypeOptions[_selectedTaskType!]
        : null;
    
    final combinedVoiceSetting = '$_selectedVoiceCategory:$_selectedVoiceStyle';
    
    widget.onSettingsChanged(_selectedTaskType, updatedConfig, combinedVoiceSetting, _selectedToneStyle);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Settings saved successfully!'),
        backgroundColor: Color(0xFFD4AF37),
      ),
    );
  }

  Future<void> _showResetDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text(
          'Reset Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will restore all settings to their default values. This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    setState(() {
      _notificationsEnabled = true;
      _bypassSilentMode = false;
      _hapticFeedback = true;
      _dailyReminders = true;
      _reminderTime = '9:00 AM';
      _userName = 'Champion';
      _selectedTaskType = null;
      _selectedVoiceCategory = 'male';
      _selectedVoiceStyle = 'Default Male';
      _selectedToneStyle = 'Balanced';
      _nameController.text = _userName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Settings reset to defaults'),
        backgroundColor: Color(0xFFD4AF37),
      ),
    );
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Data export feature coming soon'),
        backgroundColor: Color(0xFFD4AF37),
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔒 Privacy policy will open in browser'),
        backgroundColor: Color(0xFFD4AF37),
      ),
    );
  }

  Future<void> _showReflectionOnboarding() async {
    showDialog(
      context: context,
      builder: (context) => ReflectionOnboardingDialog(
        onAccept: () async {
          await _reflectionSettings.setReflectionEnabled(true);
          await _reflectionSettings.markOnboardingShown();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎭 Smart Reflections enabled!'),
              backgroundColor: Color(0xFFD4AF37),
            ),
          );
        },
        onDecline: () async {
          await _reflectionSettings.markOnboardingShown();
          Navigator.pop(context);
        },
        onLater: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}

// 🎭 Reflection Settings Section Widget
class ReflectionSettingsSection extends StatefulWidget {
  const ReflectionSettingsSection({Key? key}) : super(key: key);

  @override
  _ReflectionSettingsSectionState createState() => _ReflectionSettingsSectionState();
}

class _ReflectionSettingsSectionState extends State<ReflectionSettingsSection> {
  final ReflectionSettingsService _settingsService = ReflectionSettingsService();
  
  bool _reflectionEnabled = false;
  ReflectionStyle _notificationStyle = ReflectionStyle.audio;
  Map<String, dynamic> _settings = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    
    try {
      final settings = await _settingsService.getAllSettings();
      setState(() {
        _settings = settings;
        _reflectionEnabled = settings['enabled'] as bool;
        _notificationStyle = settings['style'] as ReflectionStyle;
        _loading = false;
      });
    } catch (e) {
      print('Error loading reflection settings: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _updateReflectionEnabled(bool enabled) async {
    await _settingsService.setReflectionEnabled(enabled);
    setState(() => _reflectionEnabled = enabled);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled 
          ? '✅ Smart reflections enabled'
          : '❌ Smart reflections disabled'
        ),
        backgroundColor: enabled ? Color(0xFFD4AF37) : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    return Column(
      children: [
        _buildMainToggle(),
        if (_reflectionEnabled) ...[
          SizedBox(height: 16),
          _buildAdvancedSettings(),
        ],
      ],
    );
  }

  Widget _buildMainToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF8B9DC3).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFD4AF37).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.psychology,
            color: Color(0xFFD4AF37),
            size: 20,
          ),
        ),
        title: Text(
          'Smart AI Reflections',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'AI checks in after important tasks',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: _reflectionEnabled,
          onChanged: _updateReflectionEnabled,
          activeColor: Color(0xFFD4AF37),
          activeTrackColor: Color(0xFFD4AF37).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎭 Reflection Benefits:',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          _buildBenefit('• AI learns your communication style'),
          _buildBenefit('• Caring check-ins after medical appointments'),
          _buildBenefit('• Celebration after achievements'),
          _buildBenefit('• Voice-first conversations'),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
      ),
    );
  }
}

// 🛡️ Privacy Controls Section Widget
class PrivacyControlsSection extends StatefulWidget {
  const PrivacyControlsSection({Key? key}) : super(key: key);

  @override
  _PrivacyControlsSectionState createState() => _PrivacyControlsSectionState();
}

class _PrivacyControlsSectionState extends State<PrivacyControlsSection> {
  late PrivacyControlService _privacyService;
  
  bool _dataCollectionConsent = false;
  bool _aiLearningEnabled = false;
  bool _debuggingConsent = false;
  bool _humanInLoopEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _privacyService = PrivacyControlService();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _loading = true);
    
    try {
      final dataConsent = await _privacyService.hasDataCollectionConsent();
      final aiLearning = await _privacyService.isAILearningEnabled();
      final debugging = await _privacyService.hasDebuggingConsent();
      final humanInLoop = await _privacyService.isHumanInLoopEnabled();
      
      setState(() {
        _dataCollectionConsent = dataConsent;
        _aiLearningEnabled = aiLearning;
        _debuggingConsent = debugging;
        _humanInLoopEnabled = humanInLoop;
        _loading = false;
      });
    } catch (e) {
      print('Error loading privacy settings: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF8B9DC3).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.security,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy & AI Controls',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '✅ All data stays on YOUR device only',
                        style: TextStyle(
                          color: Colors.green.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Privacy toggles
            _buildPrivacyToggle(
              'AI Learning & Personalization',
              'Allow AI to learn your communication style',
              _aiLearningEnabled,
              (value) async {
                await _privacyService.setAILearningEnabled(value);
                setState(() => _aiLearningEnabled = value);
              },
              Icons.psychology,
              Colors.purple,
            ),
            
            SizedBox(height: 12),
            
            _buildPrivacyToggle(
              'Human-in-the-Loop Controls',
              'Require human approval for AI decisions',
              _humanInLoopEnabled,
              (value) async {
                await _privacyService.setHumanInLoopEnabled(value);
                setState(() => _humanInLoopEnabled = value);
              },
              Icons.person_pin,
              Colors.blue,
            ),
            
            SizedBox(height: 16),
            
            // Emergency controls
            Row(
              children: [
                Expanded(
                  child: _buildEmergencyButton(
                    'View Data Report',
                    Icons.visibility,
                    Colors.blue,
                    _showTransparencyReport,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildEmergencyButton(
                    'Kill Switch',
                    Icons.delete_forever,
                    Colors.red,
                    _showKillSwitchDialog,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
          activeTrackColor: color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTransparencyReport() async {
    final report = await _privacyService.getTransparencyReport();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F2E),
        title: Text(
          '🔍 Privacy Report',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportItem('AI Learning', _aiLearningEnabled ? '✅ On' : '❌ Off'),
            _buildReportItem('Human Controls', _humanInLoopEnabled ? '✅ On' : '❌ Off'),
            _buildReportItem('Data Keys', '${report['storedDataKeys']} items'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white)),
          Text(value, style: TextStyle(color: Color(0xFFD4AF37))),
        ],
      ),
    );
  }

  Future<void> _showKillSwitchDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F2E),
        title: Text(
          '🚨 Kill Switch',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'This will delete ALL data and reset settings.\n\nThis cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _privacyService.activateKillSwitch();
              Navigator.pop(context);
              _loadPrivacySettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚨 All data cleared'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('ACTIVATE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// 🎭 Reflection Onboarding Dialog
class ReflectionOnboardingDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onLater;

  const ReflectionOnboardingDialog({
    Key? key,
    required this.onAccept,
    required this.onDecline,
    required this.onLater,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1A1F2E),
      title: Text(
        '🎭 Smart AI Reflections',
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        'Let your AI companion check in after important tasks!\n\n'
        '• Medical appointments\n'
        '• Work meetings\n'
        '• Personal achievements\n\n'
        'All conversations stay on your device.',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: onDecline,
          child: Text('No Thanks'),
        ),
        TextButton(
          onPressed: onLater,
          child: Text('Later'),
        ),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD4AF37),
            foregroundColor: Colors.black,
          ),
          child: Text('Enable'),
        ),
      ],
    );
  }
}