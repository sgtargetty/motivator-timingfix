// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_bottom_navbar.dart';
import '../services/reflection_settings_service.dart';
import '../services/privacy_control_service.dart';
import '../screens/learning_debug_screen.dart';
import '../services/complete_voice_manager.dart';

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

  // 🎭 NEW: Simplified AI Persona System (CLEANED UP!)
  String _selectedPersona = 'Lana Croft'; // Default persona
  
  // 🎤 Voice preview manager (keep existing functionality)
  final CompleteVoiceManager _voiceManager = CompleteVoiceManager();
  String? _currentlyPlayingVoice;

  // 🎭 Reflection settings (keep existing)
  final ReflectionSettingsService _reflectionSettings = ReflectionSettingsService();
  bool _hasShownReflectionOnboarding = false;

  // 🎭 AI Persona Catalog - Clean & Simple (REPLACES old voice catalog)
  final Map<String, Map<String, dynamic>> _aiPersonas = {
    'Lana Croft': {
      'name': 'Lana Croft',
      'gender': 'Female',
      'accent': 'British',
      'personality': 'Adventurous & Flirty',
      'description': 'Ready for an adventure? Let\'s explore together!',
      'icon': Icons.explore,
      'color': Color(0xFFD4AF37), // Gold
      'voiceId': 'cgSgspJ2msm6clMCkdW9', // ElevenLabs voice ID
      'defaultRelationshipTrack': 'romantic',
    },
    'Baxter Jordan': {
      'name': 'Baxter Jordan',
      'gender': 'Male', 
      'accent': 'American',
      'personality': 'Analytical & Wise',
      'description': 'Let\'s analyze this situation and find the best path forward.',
      'icon': Icons.psychology,
      'color': Color(0xFF4A90E2), // Blue
      'voiceId': 'pNInz6obpgDQGcFmaJgB', // ElevenLabs voice ID
      'defaultRelationshipTrack': 'mentor',
    },
    'Sophie Chen': {
      'name': 'Sophie Chen',
      'gender': 'Female',
      'accent': 'Asian-American', 
      'personality': 'Bubbly & Sisterly',
      'description': 'OMG, this is going to be so much fun! Tell me everything!',
      'icon': Icons.favorite,
      'color': Color(0xFFFF6B9D), // Pink
      'voiceId': 'TBD', // TODO: Get ElevenLabs voice ID
      'defaultRelationshipTrack': 'platonic',
    },
    'Marcus Thompson': {
      'name': 'Marcus Thompson',
      'gender': 'Male',
      'accent': 'Black American',
      'personality': 'Chill & Loyal', 
      'description': 'Yo, I got your back. Let\'s figure this out together, bro.',
      'icon': Icons.support,
      'color': Color(0xFF34C759), // Green
      'voiceId': 'TBD', // TODO: Get ElevenLabs voice ID  
      'defaultRelationshipTrack': 'platonic',
    },
  };

  // Task type options (keep existing)
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

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCurrentSettings();
    _loadPersonaSettings(); // 🎭 NEW: Load persona instead of complex voice settings
    _loadUserSettings();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _pulseController.repeat(reverse: true);

    setState(() {
      _selectedTaskType = widget.currentTaskType ?? 'Study';
      _userName = 'Champion';
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
  }

  // 🎭 NEW: Simplified persona loading (replaces complex voice parsing)
  Future<void> _loadPersonaSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try to load saved persona
    final savedPersona = prefs.getString('selected_persona');
    final savedVoice = prefs.getString('selected_voice'); // Legacy fallback
    
    print('🎭 Loading persona settings...');
    print('🎯 Saved Persona: $savedPersona');
    print('🔄 Legacy Voice: $savedVoice');
    
    if (savedPersona != null && _aiPersonas.containsKey(savedPersona)) {
      setState(() {
        _selectedPersona = savedPersona;
      });
      print('✅ Persona loaded: $_selectedPersona');
    } else if (savedVoice != null) {
      // 🔄 Legacy migration: convert old voice settings to persona
      final migratedPersona = _migrateOldVoiceToPersona(savedVoice);
      setState(() {
        _selectedPersona = migratedPersona;
      });
      // Save the migrated persona
      await _savePersonaSelection();
      print('🔄 Migrated legacy voice to persona: $_selectedPersona');
    } else {
      // Default to Lana Croft
      setState(() {
        _selectedPersona = 'Lana Croft';
      });
      await _savePersonaSelection();
      print('✅ Defaulted to persona: $_selectedPersona');
    }
  }

  // 🔄 Helper: Migrate old voice settings to new persona system
  String _migrateOldVoiceToPersona(String oldVoice) {
    final lowerVoice = oldVoice.toLowerCase();
    
    if (lowerVoice.contains('lana') || lowerVoice.contains('british') || lowerVoice.contains('female')) {
      return 'Lana Croft';
    } else if (lowerVoice.contains('baxter') || lowerVoice.contains('american') || lowerVoice.contains('male')) {
      return 'Baxter Jordan';
    } else if (lowerVoice.contains('sophie') || lowerVoice.contains('asian')) {
      return 'Sophie Chen';
    } else if (lowerVoice.contains('marcus') || lowerVoice.contains('black')) {
      return 'Marcus Thompson';
    }
    
    // Default fallback
    return 'Lana Croft';
  }

  // 🎭 NEW: Simple persona selection (replaces complex voice selection)
  void _selectPersona(String persona) async {
    if (!_aiPersonas.containsKey(persona)) return;
    
    setState(() {
      _selectedPersona = persona;
    });
    
    await _savePersonaSelection();
    HapticFeedback.selectionClick();
    
    print('🎭 Persona selected: $persona');
  }

  // 🎭 NEW: Save persona selection
  Future<void> _savePersonaSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_persona', _selectedPersona);
    
    // Also save in legacy format for compatibility
    final personaData = _aiPersonas[_selectedPersona]!;
    final legacyVoice = '${personaData['gender']}:${personaData['name']}';
    await prefs.setString('selected_voice', legacyVoice);
    
    print('💾 Persona saved: $_selectedPersona');
    print('🔄 Legacy compatibility: $legacyVoice');
  }

  // 🎤 Voice preview functionality (updated for persona system)
  Future<void> _previewPersonaVoice(String persona) async {
    if (!_aiPersonas.containsKey(persona)) return;
    
    final personaData = _aiPersonas[persona]!;
    final voiceId = personaData['voiceId'];
    
    if (voiceId == 'TBD') {
      _showVoiceComingSoonSnackBar(persona);
      return;
    }
    
    setState(() {
      _currentlyPlayingVoice = persona;
    });
    
    try {
      // Use the correct method signature from CompleteVoiceManager
      final success = await _voiceManager.playVoicePreview(
        voiceStyle: 'characters:$persona',  // Format it correctly
        toneStyle: 'Balanced',             // Default tone
        userName: _userName,               // Use current user name
      );
      
      if (success) {
        print('✅ Voice preview started for $persona');
      } else {
        print('❌ Voice preview failed for $persona');
        _showVoiceComingSoonSnackBar(persona);
      }
      
      // Reset playing state after preview
      if (mounted) {
        setState(() {
          _currentlyPlayingVoice = null;
        });
      }
    } catch (e) {
      print('❌ Voice preview error: $e');
      if (mounted) {
        setState(() {
          _currentlyPlayingVoice = null;
        });
      }
      _showVoiceComingSoonSnackBar(persona);
    }
  }

  void _showVoiceComingSoonSnackBar(String persona) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎤 $persona\'s voice is coming soon!'),
        backgroundColor: _aiPersonas[persona]!['color'],
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _bypassSilentMode = prefs.getBool('bypass_silent_mode') ?? false;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _dailyReminders = prefs.getBool('daily_reminders') ?? true;
      _reminderTime = prefs.getString('reminder_time') ?? '9:00 AM';
      _userName = prefs.getString('user_name') ?? 'Champion';
    });
    
    _nameController.text = _userName;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _voiceManager.dispose();
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFFD4AF37),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildUserIdentitySection(),
          const SizedBox(height: 20),
          _buildTaskFocusSection(),
          const SizedBox(height: 20),
          _buildAICompanionSection(), // 🎭 NEW: Replaces complex voice section
          const SizedBox(height: 20),
          _buildSmartReflectionSection(),
          const SizedBox(height: 20),
          _buildPrivacyAndAIControlSection(),
          const SizedBox(height: 20),
          _buildNotificationSection(),
          const SizedBox(height: 20),
          _buildAdvancedSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // 🎭 NEW: Beautiful AI Companion Section (replaces complex voice selection)
  Widget _buildAICompanionSection() {
    return _buildSettingsCard(
      title: 'AI Companion',
      icon: Icons.smart_toy,
      color: const Color(0xFFD4AF37),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your AI companion personality. Your relationship will develop naturally through conversation.',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          
          // 🎭 Persona Cards Grid
          ..._aiPersonas.entries.map((entry) {
            final persona = entry.key;
            final data = entry.value;
            final isSelected = _selectedPersona == persona;
            final isPlaying = _currentlyPlayingVoice == persona;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectPersona(persona),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (data['color'] as Color).withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? (data['color'] as Color)
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: (data['color'] as Color).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ] : null,
                    ),
                    child: Row(
                      children: [
                        // Persona Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (data['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            data['icon'] as IconData,
                            color: data['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Persona Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              Text(
                                data['name'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF8B9DC3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Demographics
                              Text(
                                '${data['accent']} • ${data['gender']} • ${data['personality']}',
                                style: TextStyle(
                                  color: isSelected 
                                      ? (data['color'] as Color) 
                                      : const Color(0xFF8B9DC3).withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Description Quote
                              Text(
                                '"${data['description']}"',
                                style: TextStyle(
                                  color: const Color(0xFF8B9DC3).withOpacity(0.9),
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Preview Button
                        GestureDetector(
                          onTap: () => _previewPersonaVoice(persona),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isPlaying 
                                  ? (data['color'] as Color)
                                  : (data['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPlaying ? Icons.stop : Icons.play_arrow,
                              color: isPlaying ? Colors.white : (data['color'] as Color),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUserIdentitySection() {
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
          TextField(
            controller: _nameController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(
                color: const Color(0xFF8B9DC3).withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFocusSection() {
    return _buildSettingsCard(
      title: 'Task Focus',
      icon: Icons.gps_fixed,
      color: const Color(0xFF4A90E2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of tasks do you want to focus on?',
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
            children: _taskTypeOptions.keys.map((taskType) {
              final config = _taskTypeOptions[taskType]!;
              final isSelected = _selectedTaskType == taskType;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTaskType = taskType;
                  });
                  widget.onSettingsChanged(_selectedTaskType, config, null, null);
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
                          : Colors.white.withOpacity(0.2),
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

  Widget _buildSmartReflectionSection() {
    return _buildSettingsCard(
      title: 'Smart Reflection',
      icon: Icons.psychology,
      color: const Color(0xFF9C27B0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI learns from your patterns and provides personalized insights.',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enable Smart Reflection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: true, // Always enabled for now
                onChanged: null, // Disabled for now
                activeColor: const Color(0xFF9C27B0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyAndAIControlSection() {
    return _buildSettingsCard(
      title: 'Privacy and AI Control',
      icon: Icons.security,
      color: const Color(0xFFFF5722),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage your data and AI behavior settings.',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          
          // 🧠 NEW: Human in the Loop Control - Memory & Relationship Manager
          GestureDetector(
            onTap: () {
              _showMemoryManagerModal();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF5722).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.memory,
                    color: const Color(0xFFFF5722),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Memory & Relationship Manager',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View conversation history, manage AI memories, reset relationship',
                          style: TextStyle(
                            color: const Color(0xFF8B9DC3).withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFFFF5722),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LearningDebugScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    color: const Color(0xFF8B9DC3),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Learning Debug Console',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFF8B9DC3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSettingsCard(
      title: 'Notification Options',
      icon: Icons.notifications,
      color: const Color(0xFF4CAF50),
      child: Column(
        children: [
          _buildNotificationToggle(
            'Enable Notifications',
            'Receive AI motivation and reminders',
            _notificationsEnabled,
            (value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', value);
            },
          ),
          const SizedBox(height: 16),
          _buildNotificationToggle(
            'Bypass Silent Mode',
            'Play sounds even when phone is on silent',
            _bypassSilentMode,
            (value) async {
              setState(() {
                _bypassSilentMode = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('bypass_silent_mode', value);
            },
          ),
          const SizedBox(height: 16),
          _buildNotificationToggle(
            'Haptic Feedback',
            'Feel vibrations with interactions',
            _hapticFeedback,
            (value) async {
              setState(() {
                _hapticFeedback = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('haptic_feedback', value);
            },
          ),
          const SizedBox(height: 20),
          
          // Daily AI Companion Reminders
          Text(
            'Daily AI Companion Reminders',
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          _buildNotificationToggle(
            'Daily Reminders',
            'Get daily check-ins from your AI companion',
            _dailyReminders,
            (value) async {
              setState(() {
                _dailyReminders = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('daily_reminders', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return _buildSettingsCard(
      title: 'Advanced Settings',
      icon: Icons.settings,
      color: const Color(0xFF607D8B),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.refresh, color: Color(0xFF8B9DC3)),
            title: const Text(
              'Reset All Settings',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            subtitle: Text(
              'Return to default configuration',
              style: TextStyle(
                color: const Color(0xFF8B9DC3).withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            onTap: _showResetConfirmation,
          ),
        ],
      ),
    );
  }

  // 🧠 NEW: Show Memory Manager Modal (placeholder for now)
  void _showMemoryManagerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF1a2332),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memory & Relationship Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Placeholder content
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      color: const Color(0xFFD4AF37),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Coming Soon!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Human in the Loop memory management will be available in the next update. You\'ll be able to:\n\n• View conversation history\n• Delete specific memories\n• Reset relationship progression\n• Export conversation data',
                      style: TextStyle(
                        color: const Color(0xFF8B9DC3),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
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
          activeColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, animChild) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
      },
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a2332),
          title: const Text(
            'Reset All Settings',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will reset all settings to their default values. This action cannot be undone.',
            style: TextStyle(color: Color(0xFF8B9DC3)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF8B9DC3)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}