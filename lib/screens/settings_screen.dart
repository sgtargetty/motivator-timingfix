import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_bottom_navbar.dart';
import '../services/reflection_settings_service.dart';

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
      {'name': 'Superhero', 'description': 'Noble, inspiring hero', 'icon': Icons.shield},
      {'name': 'British Butler', 'description': 'Refined, proper service', 'icon': Icons.restaurant_menu},
      {'name': 'Drill Instructor', 'description': 'Military precision, commanding', 'icon': Icons.fitness_center},
      {'name': 'Lana Croft', 'description': 'Adventure hero, tomb raider spirit', 'icon': Icons.explore},
      {'name': 'Baxter Jordan', 'description': 'Dark analyst, methodical precision', 'icon': Icons.psychology_alt},
      {'name': 'Argent', 'description': 'Advanced AI assistant, JARVIS-like', 'icon': Icons.android},
    ],
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCurrentSettings();
    _loadUserPreferences();
    _checkReflectionOnboarding(); // 🎭 NEW: Check reflection onboarding
    _slideController.forward();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  // 🎭 NEW: Check reflection onboarding
  Future<void> _checkReflectionOnboarding() async {
    final hasShown = await _reflectionSettings.hasShownOnboarding();
    setState(() {
      _hasShownReflectionOnboarding = hasShown;
    });
  }

  // 🎭 NEW: Show reflection onboarding dialog
  void _showReflectionOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReflectionOnboardingDialog(
        onAccept: () async {
          await _reflectionSettings.setOnboardingShown();
          await _reflectionSettings.setReflectionEnabled(true);
          Navigator.pop(context);
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎭 Smart reflections enabled! Customize below.'),
              backgroundColor: Color(0xFFD4AF37),
            ),
          );
        },
        onDecline: () async {
          await _reflectionSettings.setOnboardingShown();
          Navigator.pop(context);
        },
        onLater: () {
          Navigator.pop(context);
        },
      ),
    );
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
      if (voiceSetting.contains('Female') || voiceSetting.contains('Woman') || voiceSetting.contains('Belle') || voiceSetting.contains('Girl')) {
        _selectedVoiceCategory = 'female';
      } else if (voiceSetting.contains('Robot') || voiceSetting.contains('Pirate') || voiceSetting.contains('Wizard') || voiceSetting.contains('Superhero') || voiceSetting.contains('Lana') || voiceSetting.contains('Baxter') || voiceSetting.contains('Argent')) {
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

  Future<void> _saveSettings() async {
    HapticFeedback.heavyImpact();
    
    final prefs = await SharedPreferences.getInstance();
    
    if (_userName.trim().isNotEmpty) {
      await prefs.setString('user_name', _userName.trim());
      print('💾 Saved user name: ${_userName.trim()}');
    }
    
    final updatedConfig = _selectedTaskType != null 
        ? _taskTypeOptions[_selectedTaskType!]
        : null;
    
    final combinedVoiceSetting = '$_selectedVoiceCategory:$_selectedVoiceStyle';
    
    widget.onSettingsChanged(_selectedTaskType, updatedConfig, combinedVoiceSetting, _selectedToneStyle);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Settings saved successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _buildSophisticatedHeader(),
              Expanded(
                child: AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: _buildSettingsContent(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              AppBottomNavBar(
                currentScreen: AppScreen.settings,
                onScreenChanged: (screen) => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSophisticatedHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF8B9DC3).withOpacity(0.1),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Customize your AI experience',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      children: [
        _buildPersonalizationSection(),
        const SizedBox(height: 20),
        _buildTaskTypeSection(),
        const SizedBox(height: 20),
        _buildEnhancedVoiceSection(),
        const SizedBox(height: 20),
        _buildToneStyleSection(),
        const SizedBox(height: 20),
        
        // 🎭 NEW: Smart Reflections Section
        _buildSectionHeader('Smart Reflections'),
        ReflectionSettingsSection(),
        const SizedBox(height: 20),
        
        _buildNotificationSection(),
        const SizedBox(height: 20),
        _buildAdvancedSection(),
        const SizedBox(height: 30),
        _buildSaveButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  // 🎭 NEW: Section header helper
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection() {
    return _buildSettingsCard(
      title: 'Personalization',
      icon: Icons.person,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Name',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: const Color(0xFF8B9DC3).withOpacity(0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _userName = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeSection() {
    return _buildSettingsCard(
      title: 'Focus Mode',
      icon: Icons.psychology,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Focus',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedTaskType = null;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _selectedTaskType == null
                    ? const Color(0xFFD4AF37).withOpacity(0.1)
                    : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedTaskType == null
                      ? const Color(0xFFD4AF37).withOpacity(0.5)
                      : const Color(0xFF8B9DC3).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.all_inclusive,
                    color: _selectedTaskType == null ? const Color(0xFFD4AF37) : const Color(0xFF8B9DC3),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'All Activities (Balanced)',
                    style: TextStyle(
                      color: _selectedTaskType == null ? const Color(0xFFD4AF37) : const Color(0xFF8B9DC3),
                      fontWeight: _selectedTaskType == null ? FontWeight.w600 : FontWeight.w300,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
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
                    _selectedTaskType = taskType;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? config['color']
                        : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? config['color']
                          : const Color(0xFF8B9DC3).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config['icon'],
                        color: isSelected ? Colors.black : config['color'],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        taskType,
                        style: TextStyle(
                          color: isSelected ? Colors.black : const Color(0xFF8B9DC3),
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

  Widget _buildEnhancedVoiceSection() {
    return _buildSettingsCard(
      title: 'Voice & Character',
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
                      ? const Color(0xFFD4AF37).withOpacity(0.5)
                      : const Color(0xFF8B9DC3).withOpacity(0.1),
                  width: 1,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : const Color(0xFF8B9DC3).withOpacity(0.1),
            width: 1,
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
      title: 'Motivational Tone',
      icon: Icons.psychology,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Coaching Style',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._toneStyles.map((tone) {
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
                      ? tone['color'].withOpacity(0.5)
                      : const Color(0xFF8B9DC3).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  tone['icon'],
                  color: isSelected ? tone['color'] : const Color(0xFF8B9DC3),
                  size: 20,
                ),
                title: Text(
                  tone['name'],
                  style: TextStyle(
                    color: isSelected ? tone['color'] : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tone['description'],
                      style: TextStyle(
                        color: const Color(0xFF8B9DC3).withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tone['example'],
                      style: TextStyle(
                        color: const Color(0xFF8B9DC3).withOpacity(0.8),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedToneStyle = tone['name'];
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

  Widget _buildNotificationSection() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications,
      color: const Color(0xFFD4AF37),
      child: Column(
        children: [
          _buildToggleOption(
            'Push Notifications',
            'Receive task reminders and motivational alerts',
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

  Widget _buildAdvancedSection() {
    return _buildSettingsCard(
      title: 'Advanced',
      icon: Icons.settings,
      color: const Color(0xFFD4AF37),
      child: Column(
        children: [
          _buildActionButton(
            'Reset All Settings',
            'Restore default configuration',
            Icons.refresh,
            Colors.orange,
            () => _showResetDialog(),
          ),
          const SizedBox(height: 12),
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
          if (!_hasShownReflectionOnboarding) ...[
            const SizedBox(height: 12),
            _buildActionButton(
              'Smart Reflections Tour',
              'Learn about AI check-ins and reflections',
              Icons.psychology,
              Color(0xFFD4AF37),
              () => _showReflectionOnboarding(),
            ),
          ],
        ],
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _saveSettings,
                child: const Center(
                  child: Text(
                    'Save Settings',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B9DC3).withOpacity(0.1),
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
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
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
    String description,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: value ? const Color(0xFFD4AF37) : const Color(0xFF8B9DC3),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: value ? const Color(0xFFD4AF37) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: const Color(0xFF8B9DC3).withOpacity(0.7),
                  fontSize: 12,
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
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B9DC3).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: const Color(0xFF8B9DC3).withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: const Color(0xFF8B9DC3),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // Helper methods
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3E),
        title: const Text(
          'Reset Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF8B9DC3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B9DC3)),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Reset reflection settings
              await _reflectionSettings.resetToDefaults();
              
              // Reset other settings
              setState(() {
                _selectedTaskType = null;
                _selectedVoiceCategory = 'male';
                _selectedVoiceStyle = 'Default Male';
                _selectedToneStyle = 'Balanced';
                _userName = 'Champion';
                _nameController.text = 'Champion';
                _notificationsEnabled = true;
                _bypassSilentMode = false;
                _hapticFeedback = true;
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Settings reset to defaults'),
                  backgroundColor: Color(0xFFD4AF37),
                ),
              );
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

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Data export feature coming soon!'),
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
}

// 🎭 NEW: Reflection Settings Section Widget
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
            size: 24,
          ),
        ),
        title: Text(
          'Smart Reflections',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'AI automatically checks in after your tasks',
          style: TextStyle(
            color: Color(0xFF8B9DC3),
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
      margin: EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF8B9DC3).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.tune,
          color: Color(0xFFD4AF37),
        ),
        title: Text(
          'Reflection Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Customize your check-in experience',
          style: TextStyle(
            color: Color(0xFF8B9DC3),
            fontSize: 14,
          ),
        ),
        children: [
          _buildQuickSettings(),
        ],
      ),
    );
  }

  Widget _buildQuickSettings() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Settings',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'For detailed customization, use the main settings above.',
            style: TextStyle(
              color: Color(0xFF8B9DC3),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          
          // Fixed layout with proper constraints
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule, color: Color(0xFF8B9DC3), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Default: 2 hours after tasks',
                      style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.category, color: Color(0xFF8B9DC3), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enabled: Medical appointments, Important meetings',
                      style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.volume_up, color: Color(0xFF8B9DC3), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Style: Audio check-in (recommended)',
                      style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 🎭 NEW: Reflection Onboarding Dialog
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
      backgroundColor: Color(0xFF2A2D3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.psychology, color: Color(0xFFD4AF37), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Smart Reflections',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Would you like your AI companion to check in with you after important appointments and tasks?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFFD4AF37).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benefits:',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                _buildBenefit('✅ Build positive completion habits'),
                _buildBenefit('🎯 Emotional support when you need it'),
                _buildBenefit('📈 Track your progress and patterns'),
                _buildBenefit('🎭 Personalized, caring conversations'),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'You can always customize or disable this in settings.',
            style: TextStyle(
              color: Color(0xFF8B9DC3),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onLater,
          child: Text(
            'Ask me later',
            style: TextStyle(color: Color(0xFF8B9DC3)),
          ),
        ),
        TextButton(
          onPressed: onDecline,
          child: Text(
            'No thanks',
            style: TextStyle(color: Color(0xFF8B9DC3)),
          ),
        ),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'Yes, enable!',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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