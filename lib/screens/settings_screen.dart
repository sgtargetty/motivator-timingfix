import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _userName = 'Champion'; // Will be loaded from SharedPreferences
  String? _selectedTaskType;

  // Controllers for the name input
  late TextEditingController _nameController;

  // Enhanced voice settings
  String _selectedVoiceCategory = 'male';
  String _selectedVoiceStyle = 'Default Male';
  String _selectedToneStyle = 'Balanced';

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
      'description': 'Positive and enthusiastic',
      'icon': Icons.celebration,
      'color': Colors.pink,
      'example': '"You\'re amazing! Go team YOU! 🎉"',
    },
    {
      'name': 'Sage',
      'description': 'Wise and philosophical',
      'icon': Icons.psychology,
      'color': Colors.purple,
      'example': '"Every journey begins with a single step."',
    },
    {
      'name': 'Coach',
      'description': 'Supportive and goal-focused',
      'icon': Icons.sports,
      'color': Colors.green,
      'example': '"Let\'s break this down and tackle it!"',
    },
    {
      'name': 'Friend',
      'description': 'Casual and encouraging',
      'icon': Icons.people,
      'color': Colors.orange,
      'example': '"Hey, I believe in you! You\'ve got this!"',
    },
  ];

  // Voice categories and their available styles
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
      // 🎭 CUSTOM ELEVENLABS VOICES - Your creations!
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
    _loadUserPreferences(); // ✅ Load saved user name
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

  // ✅ Load user preferences from SharedPreferences
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Champion';
    });
    
    // Initialize the text controller with the loaded name
    _nameController = TextEditingController(text: _userName);
    
    // Listen for changes to the name field
    _nameController.addListener(() {
      setState(() {
        _userName = _nameController.text;
      });
    });
  }

  void _loadCurrentSettings() {
    _selectedTaskType = widget.currentTaskType;
    
    // Parse the combined voice setting (if it exists)
    if (widget.currentVoice != null) {
      _parseVoiceSetting(widget.currentVoice!);
    }
    
    _selectedToneStyle = widget.currentToneStyle ?? 'Balanced';
  }

  void _parseVoiceSetting(String voiceSetting) {
    // Parse format like "male:Default Male" or just "Default Male"
    if (voiceSetting.contains(':')) {
      final parts = voiceSetting.split(':');
      _selectedVoiceCategory = parts[0];
      _selectedVoiceStyle = parts[1];
    } else {
      // Legacy format - try to determine category from style name
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
      // Set default voice for the category
      if (_voiceCatalog[category]!.isNotEmpty) {
        _selectedVoiceStyle = _voiceCatalog[category]!.first['name'];
      }
    });
    HapticFeedback.selectionClick();
  }

  // ✅ Updated _saveSettings method to save user name to SharedPreferences
  Future<void> _saveSettings() async {
    HapticFeedback.heavyImpact();
    
    // Get SharedPreferences to save user name
    final prefs = await SharedPreferences.getInstance();
    
    // Save the user name
    if (_userName.trim().isNotEmpty) {
      await prefs.setString('user_name', _userName.trim());
      print('💾 Saved user name: ${_userName.trim()}');
    }
    
    // Create updated config
    final updatedConfig = _selectedTaskType != null 
        ? _taskTypeOptions[_selectedTaskType!]
        : null;
    
    // Combine voice category and style for backend
    final combinedVoiceSetting = '$_selectedVoiceCategory:$_selectedVoiceStyle';
    
    // Call the callback to update main app
    widget.onSettingsChanged(_selectedTaskType, updatedConfig, combinedVoiceSetting, _selectedToneStyle);
    
    // Show success feedback
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
    _nameController.dispose(); // ✅ Dispose the controller
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // 🎨 SOPHISTICATED NAVY/GOLD GRADIENT - matching other screens
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
              _buildSophisticatedHeader(),
              Expanded(
                child: AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: _buildSettingsContent(),
                      ),
                    );
                  },
                ),
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
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.2), // 🎨 GOLD accent border
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8B9DC3)), // 🎨 Muted blue-gray
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.3), // 🎨 GOLD gradient
                        const Color(0xFFFFD700).withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.3), // 🎨 GOLD glow
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFFD4AF37), // 🎨 GOLD icon
                    size: 20,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD700), // 🎨 GOLD gradient text shader
                  Color(0xFFD4AF37),
                  Color(0xFFB8860B),
                ],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w200, // 🎨 Ultra-light academic font
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37), // 🎨 GOLD button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
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
          _buildProfileSection(),
          const SizedBox(height: 30),
          _buildTaskTypeSection(),
          const SizedBox(height: 30),
          _buildEnhancedVoiceSection(),
          const SizedBox(height: 30),
          _buildToneStyleSection(),
          const SizedBox(height: 30),
          _buildNotificationSection(),
          const SizedBox(height: 30),
          _buildAppPreferencesSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSettingsCard(
      title: 'Profile',
      icon: Icons.person,
      color: const Color(0xFFD4AF37), // 🎨 GOLD
      child: Column(
        children: [
          TextField(
            controller: _nameController, // ✅ Use the controller
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300, // 🎨 Light academic font
            ),
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: const TextStyle(
                color: Color(0xFFD4AF37), // 🎨 GOLD
                fontWeight: FontWeight.w300,
              ),
              hintText: 'How should we address you?',
              hintStyle: TextStyle(
                color: const Color(0xFF8B9DC3).withOpacity(0.5), // 🎨 Muted blue-gray
                fontWeight: FontWeight.w300,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFFD4AF37).withOpacity(0.3), // 🎨 GOLD border
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFD4AF37), // 🎨 GOLD focused border
                ),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFD4AF37), size: 16), // 🎨 GOLD
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This name will appear in your personalized motivations',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.8), // 🎨 Muted blue-gray
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeSection() {
    return _buildSettingsCard(
      title: 'Primary Focus',
      icon: Icons.flag,
      color: const Color(0xFFD4AF37), // 🎨 GOLD
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your main goal area?',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9), // 🎨 Muted blue-gray
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _taskTypeOptions.keys.map((taskType) {
              final config = _taskTypeOptions[taskType]!;
              final isSelected = _selectedTaskType == taskType;
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTaskType = taskType);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFD700)]) // 🎨 GOLD gradient when selected
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFF8B9DC3).withOpacity(0.2), // 🎨 Muted blue-gray border
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
                          color: isSelected ? Colors.black : const Color(0xFF8B9DC3), // 🎨 Black when selected, muted blue-gray when not
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
      color: const Color(0xFFD4AF37), // 🎨 GOLD
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice Category Selection
          Text(
            'Voice Category',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9), // 🎨 Muted blue-gray
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
          
          // Voice Style Selection
          Text(
            'Voice Style',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9), // 🎨 Muted blue-gray
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          
          // Voice options for selected category
          ...(_voiceCatalog[_selectedVoiceCategory] ?? []).map((voice) {
            final isSelected = _selectedVoiceStyle == voice['name'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFD4AF37).withOpacity(0.1) // 🎨 GOLD background when selected
                    : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFD4AF37) // 🎨 GOLD border when selected
                      : const Color(0xFF8B9DC3).withOpacity(0.1), // 🎨 Muted blue-gray border
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1), // 🎨 GOLD background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    voice['icon'],
                    color: const Color(0xFFD4AF37), // 🎨 GOLD icon
                    size: 20,
                  ),
                ),
                title: Text(
                  voice['name'],
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white, // 🎨 GOLD when selected
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                  ),
                ),
                subtitle: Text(
                  voice['description'],
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.7), // 🎨 Muted blue-gray
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37)) // 🎨 GOLD check
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedVoiceStyle = voice['name']);
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
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFD700)]) // 🎨 GOLD gradient when selected
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF8B9DC3).withOpacity(0.2), // 🎨 Muted blue-gray border
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : const Color(0xFF8B9DC3), // 🎨 Black when selected, muted blue-gray when not
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF8B9DC3), // 🎨 Black when selected, muted blue-gray when not
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneStyleSection() {
    return _buildSettingsCard(
      title: 'Motivation Style',
      icon: Icons.psychology,
      color: const Color(0xFFD4AF37), // 🎨 GOLD
      child: Column(
        children: _toneStyles.map((tone) {
          final isSelected = _selectedToneStyle == tone['name'];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD4AF37).withOpacity(0.1) // 🎨 GOLD background when selected
                  : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD4AF37) // 🎨 GOLD border when selected
                    : const Color(0xFF8B9DC3).withOpacity(0.1), // 🎨 Muted blue-gray border
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFD4AF37).withOpacity(0.2) // 🎨 GOLD background when selected
                              : tone['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          tone['icon'],
                          color: isSelected ? const Color(0xFFD4AF37) : tone['color'], // 🎨 GOLD when selected
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tone['name'],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFD4AF37) : Colors.white, // 🎨 GOLD when selected
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              tone['description'],
                              style: TextStyle(
                                color: const Color(0xFF8B9DC3).withOpacity(0.7), // 🎨 Muted blue-gray
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: tone['name'],
                        groupValue: _selectedToneStyle,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedToneStyle = value!);
                        },
                        activeColor: const Color(0xFFD4AF37), // 🎨 GOLD radio button
                      ),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1), // 🎨 GOLD background
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Example:',
                            style: TextStyle(
                              color: const Color(0xFFD4AF37), // 🎨 GOLD
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tone['example'],
                            style: TextStyle(
                              color: const Color(0xFF8B9DC3).withOpacity(0.9), // 🎨 Muted blue-gray
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications,
      color: const Color(0xFFD4AF37), // 🎨 GOLD
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Enable Notifications',
            subtitle: 'Receive motivational reminders',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            color: const Color(0xFFD4AF37), // 🎨 GOLD
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Bypass Silent Mode',
            subtitle: 'Play audio even when phone is silent',
            value: _bypassSilentMode,
            onChanged: (value) => setState(() => _bypassSilentMode = value),
            color: Colors.red,
            icon: Icons.volume_up,
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            title: 'Daily Reminders',
            subtitle: 'Get reminded to stay motivated',
            value: _dailyReminders,
            onChanged: (value) => setState(() => _dailyReminders = value),
            color: const Color(0xFFD4AF37), // 🎨 GOLD
            icon: Icons.schedule,
          ),
          if (_dailyReminders) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1), // 🎨 GOLD background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3), // 🎨 GOLD border
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFFD4AF37), size: 16), // 🎨 GOLD
                  const SizedBox(width: 8),
                  const Text(
                    'Reminder Time:',
                    style: TextStyle(
                      color: Color(0xFFD4AF37), // 🎨 GOLD
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      // Show time picker
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2), // 🎨 GOLD background
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _reminderTime,
                        style: const TextStyle(
                          color: Color(0xFFD4AF37), // 🎨 GOLD
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return _buildSettingsCard(
      title: 'App Preferences',
      icon: Icons.tune,
      color: const Color(0xFFD4AF37), // 🎨 GOLD
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Haptic Feedback',
            subtitle: 'Feel vibrations for interactions',
            value: _hapticFeedback,
            onChanged: (value) => setState(() => _hapticFeedback = value),
            color: const Color(0xFFD4AF37), // 🎨 GOLD
            icon: Icons.vibration,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFD4AF37), size: 16), // 🎨 GOLD
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'More settings coming soon: Dark mode, export data, backup & sync',
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.7), // 🎨 Muted blue-gray
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ],
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
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2), // 🎨 GOLD border
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                  fontWeight: FontWeight.w400, // 🎨 Academic light font weight
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value
            ? color.withOpacity(0.1)
            : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? color.withOpacity(0.3)
              : const Color(0xFF8B9DC3).withOpacity(0.1), // 🎨 Muted blue-gray border
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: value ? color : const Color(0xFF8B9DC3), size: 16), // 🎨 Muted blue-gray when off
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: value ? color : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF8B9DC3).withOpacity(0.7), // 🎨 Muted blue-gray
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}