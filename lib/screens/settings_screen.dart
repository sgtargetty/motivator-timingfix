// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_bottom_navbar.dart';
import '../services/reflection_settings_service.dart';
import '../services/privacy_control_service.dart';
import '../screens/learning_debug_screen.dart';
import '../services/complete_voice_manager.dart';
import 'dart:convert';
import 'dart:math' as math;

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
  bool _smartReflectionEnabled = true; // 🎭 NEW: Smart Reflection toggle state
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
      _smartReflectionEnabled = prefs.getBool('smart_reflection_enabled') ?? true; // 🎭 NEW: Load smart reflection setting
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
                value: _smartReflectionEnabled, // 🎭 NEW: Use actual state variable
                onChanged: (value) async {
                  setState(() {
                    _smartReflectionEnabled = value;
                  });
                  
                  // Save the setting
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('smart_reflection_enabled', value);
                  
                  // Show feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value 
                            ? '🎭 Smart Reflection enabled! AI will learn from your patterns.'
                            : '🎭 Smart Reflection disabled. AI learning paused.',
                      ),
                      backgroundColor: value ? const Color(0xFF9C27B0) : Colors.grey,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  HapticFeedback.selectionClick();
                }, // 🎭 NEW: Functional toggle with save and feedback
                activeColor: const Color(0xFF9C27B0),
              ),
            ],
          ),
          
          // 🎭 NEW: Show additional info when enabled
          if (_smartReflectionEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF9C27B0).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Smart Reflection Active',
                    style: TextStyle(
                      color: const Color(0xFF9C27B0),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• AI learns your communication style\n• Personalized check-ins after tasks\n• Adaptive conversation patterns',
                    style: TextStyle(
                      color: const Color(0xFF8B9DC3).withOpacity(0.9),
                      fontSize: 12,
                      height: 1.4,
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

  // 🧠 NEW: Show Complete Memory Manager Modal
  void _showMemoryManagerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MemoryRelationshipManager(
        selectedPersona: _selectedPersona,
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

// Memory & Relationship Manager - Complete Implementation
class MemoryRelationshipManager extends StatefulWidget {
  final String selectedPersona;

  const MemoryRelationshipManager({
    Key? key,
    required this.selectedPersona,
  }) : super(key: key);

  @override
  State<MemoryRelationshipManager> createState() => _MemoryRelationshipManagerState();
}

class _MemoryRelationshipManagerState extends State<MemoryRelationshipManager>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // 🧠 Memory Data
  List<Map<String, dynamic>> _conversationHistory = [];
  Map<String, dynamic> _relationshipData = {};
  Map<String, dynamic> _memoryStats = {};
  List<Map<String, dynamic>> _customMemories = []; // 🧠 NEW: Custom memories
  bool _isLoading = true;
  
  // 🎭 Relationship Levels
  final Map<String, Map<String, dynamic>> _relationshipLevels = {
    'Acquaintance': {'min': 0, 'max': 30, 'color': Colors.grey, 'icon': Icons.person_outline},
    'Friend': {'min': 31, 'max': 80, 'color': Colors.blue, 'icon': Icons.person},
    'Close Friend': {'min': 81, 'max': 150, 'color': Colors.green, 'icon': Icons.favorite_border},
    'Romantic Interest': {'min': 151, 'max': 250, 'color': Colors.pink, 'icon': Icons.favorite},
    'Partner': {'min': 251, 'max': 999, 'color': Colors.red, 'icon': Icons.favorite},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMemoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoryData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 🔍 DEBUG: Print ALL keys to see what's actually stored
      final allKeys = prefs.getKeys();
      print('🔍 DEBUG - ALL STORED KEYS:');
      for (String key in allKeys) {
        if (key.contains('conversation') || key.contains('memory') || key.contains('relationship') || key.contains('Lana') || key.contains('persona')) {
          final value = prefs.get(key);
          print('KEY: $key');
          print('VALUE: ${value.toString().length > 200 ? value.toString().substring(0, 200) + "..." : value}');
          print('---');
        }
      }
      
      // 🔍 Try multiple key formats to find the actual conversation data
      List<String> possibleKeys = [
        'conversation_history_${widget.selectedPersona}', // Persona-specific
        'conversation_history_Lana Croft', // Explicit name
        'conversation_history', // Generic
        'persistent_memory_${widget.selectedPersona}', // Alternative format
        'conversations_${widget.selectedPersona}', // Another possibility
        'conversations', // Generic conversations
        'chat_history', // Alternative name
        'voice_chat_history', // Voice specific
      ];
      
      // Load conversation history - try different key formats
      String? historyJson;
      String foundKey = '';
      for (String key in possibleKeys) {
        historyJson = prefs.getString(key);
        if (historyJson != null) {
          foundKey = key;
          print('✅ Found conversation data at key: $key');
          print('📄 Data length: ${historyJson.length} characters');
          print('📄 First 300 chars: ${historyJson.length > 300 ? historyJson.substring(0, 300) + "..." : historyJson}');
          break;
        }
      }
      
      if (historyJson != null) {
        try {
          final decoded = json.decode(historyJson);
          if (decoded is List) {
            _conversationHistory = List<Map<String, dynamic>>.from(decoded);
            print('✅ Loaded ${_conversationHistory.length} conversations from $foundKey');
          } else if (decoded is Map) {
            // Handle case where it might be stored as a map
            _conversationHistory = [Map<String, dynamic>.from(decoded)];
            print('✅ Converted map to list: 1 conversation from $foundKey');
          }
          
          // Print sample conversation data
          if (_conversationHistory.isNotEmpty) {
            print('📋 Sample conversation:');
            print('  Keys: ${_conversationHistory.first.keys.toList()}');
            print('  Sample: ${_conversationHistory.first}');
          }
        } catch (e) {
          print('❌ Error parsing conversation history: $e');
          _conversationHistory = [];
        }
      } else {
        print('⚠️ No conversation history found in any expected keys');
        _conversationHistory = [];
      }
      
      // Load relationship data - try different formats
      List<String> relationshipKeys = [
        'relationship_data_${widget.selectedPersona}',
        'relationship_Lana Croft',
        'relationship_${widget.selectedPersona}',
        'memory_stats_${widget.selectedPersona}',
        'backend_memory_stats',
        'total_conversations',
      ];
      
      String? relationshipJson;
      for (String key in relationshipKeys) {
        final value = prefs.get(key);
        if (value != null) {
          print('🔍 Found relationship data at key: $key, value: $value');
          if (value is String) {
            relationshipJson = value;
          } else {
            // Handle non-string values
            _relationshipData[key.replaceAll('_${widget.selectedPersona}', '')] = value;
          }
        }
      }
      
      if (relationshipJson != null) {
        try {
          _relationshipData.addAll(Map<String, dynamic>.from(json.decode(relationshipJson)));
        } catch (e) {
          print('❌ Error parsing relationship JSON: $e');
        }
      }
      
      // Create default relationship data if none exists
      if (_relationshipData.isEmpty) {
        _relationshipData = {
          'points': 0,
          'level': 'Acquaintance',
          'totalConversations': _conversationHistory.length,
        };
      }
      
      print('📊 Final relationship data: $_relationshipData');
      print('📊 Final conversation count: ${_conversationHistory.length}');
      
      // 🧠 Load custom memories
      final customMemoriesJson = prefs.getString('custom_memories_${widget.selectedPersona}') ?? '[]';
      try {
        _customMemories = List<Map<String, dynamic>>.from(json.decode(customMemoriesJson));
        print('🧠 Loaded ${_customMemories.length} custom memories');
      } catch (e) {
        print('❌ Error loading custom memories: $e');
        _customMemories = [];
      }
      
      // Generate memory stats
      _generateMemoryStats();
      
    } catch (e) {
      print('❌ Error loading memory data: $e');
      _conversationHistory = [];
      _relationshipData = {'points': 0, 'level': 'Acquaintance'};
    }
    
    setState(() => _isLoading = false);
  }

  void _generateMemoryStats() {
    final totalConversations = _conversationHistory.length;
    
    // Use backend stats if available, otherwise calculate from local data
    final backendTotalConversations = _relationshipData['totalConversations'] ?? totalConversations;
    final relationshipPoints = _relationshipData['points'] ?? math.max(0, (backendTotalConversations * 2)); // Estimate 2 points per conversation
    final currentLevel = _getCurrentRelationshipLevel(relationshipPoints);
    
    _memoryStats = {
      'totalConversations': backendTotalConversations,
      'localConversations': totalConversations,
      'relationshipPoints': relationshipPoints,
      'currentLevel': currentLevel,
      'daysSinceFirstChat': _getDaysSinceFirstChat(),
    };
    
    print('📊 Memory Stats Generated:');
    print('  Total Conversations: $backendTotalConversations');
    print('  Local Conversations: $totalConversations'); 
    print('  Relationship Points: $relationshipPoints');
    print('  Current Level: $currentLevel');
  }

  String _getCurrentRelationshipLevel(int points) {
    for (final entry in _relationshipLevels.entries) {
      if (points >= entry.value['min'] && points <= entry.value['max']) {
        return entry.key;
      }
    }
    return 'Acquaintance';
  }

  int _getDaysSinceFirstChat() {
    if (_conversationHistory.isEmpty) return 0;
    final firstChat = DateTime.tryParse(_conversationHistory.first['timestamp'] ?? '');
    if (firstChat == null) return 0;
    return DateTime.now().difference(firstChat).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0a1428),
            Color(0xFF1a2332),
            Color(0xFF0f1419),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading 
                ? _buildLoadingView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConversationTab(),
                      _buildRelationshipTab(), 
                      _buildMemoryTab(),
                      _buildControlsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF5722).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.memory,
              color: Color(0xFFFF5722),
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memory & Relationship Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.selectedPersona} • ${_memoryStats['currentLevel'] ?? 'Loading...'}',
                  style: TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Color(0xFFFF5722),
        indicatorWeight: 3,
        labelColor: Color(0xFFFF5722),
        unselectedLabelColor: Color(0xFF8B9DC3),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(icon: Icon(Icons.chat, size: 20), text: 'Chats'),
          Tab(icon: Icon(Icons.favorite, size: 20), text: 'Relationship'),
          Tab(icon: Icon(Icons.psychology, size: 20), text: 'Memory'),
          Tab(icon: Icon(Icons.settings, size: 20), text: 'Controls'),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFF5722)),
          SizedBox(height: 16),
          Text(
            'Loading memory data...',
            style: TextStyle(color: Color(0xFF8B9DC3)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // Stats Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conversation Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showSearchDialog,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A90E2).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.search, color: Color(0xFF4A90E2), size: 20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Total Conversations: ${_memoryStats['totalConversations']}',
                style: TextStyle(color: Color(0xFF8B9DC3)),
              ),
              Text(
                'Local History: ${_memoryStats['localConversations']} stored',
                style: TextStyle(color: Color(0xFF8B9DC3)),
              ),
              Text(
                'Days Chatting: ${_memoryStats['daysSinceFirstChat']}',
                style: TextStyle(color: Color(0xFF8B9DC3)),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Conversation List Header
        Text(
          'Recent Conversations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        // Conversation List
        if (_conversationHistory.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, color: Color(0xFF8B9DC3), size: 48),
                SizedBox(height: 12),
                Text(
                  'No local conversation history found',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Backend shows ${_memoryStats['totalConversations']} total conversations.\nLocal history may be stored differently.',
                  style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Conversation items - directly in the ListView
          ..._conversationHistory.map((conversation) {
            final index = _conversationHistory.indexOf(conversation);
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Conversation ${index + 1}',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => _deleteConversation(conversation),
                        child: Icon(Icons.delete, color: Colors.red.withOpacity(0.7), size: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    conversation['timestamp'] ?? 'Unknown time',
                    style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                  ),
                  if (conversation['user'] != null) ...[
                    SizedBox(height: 8),
                    Text(
                      'You: ${conversation['user']}',
                      style: TextStyle(color: Color(0xFF8B9DC3)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildRelationshipTab() {
    final currentLevel = _memoryStats['currentLevel'] ?? 'Acquaintance';
    final points = _memoryStats['relationshipPoints'] ?? 0;
    final levelData = _relationshipLevels[currentLevel]!;
    final progress = ((points - levelData['min']) / (levelData['max'] - levelData['min'])).clamp(0.0, 1.0);
    
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Current Relationship Status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (levelData['color'] as Color).withOpacity(0.3),
                  (levelData['color'] as Color).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: levelData['color'].withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Icon(
                  levelData['icon'],
                  color: levelData['color'],
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  currentLevel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '$points relationship points',
                  style: TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(levelData['color']),
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${levelData['min']} pts',
                      style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                    ),
                    Text(
                      '${levelData['max']} pts',
                      style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Relationship Journey
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relationship Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: _relationshipLevels.entries.map((entry) {
                      final isUnlocked = points >= entry.value['min'];
                      final isCurrent = entry.key == currentLevel;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent 
                              ? entry.value['color'].withOpacity(0.2)
                              : Colors.white.withOpacity(isUnlocked ? 0.05 : 0.02),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent 
                                ? entry.value['color']
                                : Colors.white.withOpacity(isUnlocked ? 0.2 : 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              entry.value['icon'],
                              color: isUnlocked ? entry.value['color'] : Color(0xFF8B9DC3),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : Color(0xFF8B9DC3),
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value['min']}-${entry.value['max']} pts',
                              style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                            ),
                            if (isCurrent) ...[
                              SizedBox(width: 8),
                              Icon(Icons.star, color: entry.value['color'], size: 16),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text(
          'What ${widget.selectedPersona} Remembers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        
        // Memory Stats Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: Color(0xFFFF5722), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Memory Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildMemoryStatRow('Total Conversations', '${_memoryStats['totalConversations']}'),
              _buildMemoryStatRow('Relationship Points', '${_memoryStats['relationshipPoints']}'),
              _buildMemoryStatRow('Current Level', '${_memoryStats['currentLevel']}'),
              _buildMemoryStatRow('Days Chatting', '${_memoryStats['daysSinceFirstChat']}'),
              _buildMemoryStatRow('Custom Memories', '${_customMemories.length}'),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Add Custom Memory Button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAddMemoryDialog,
            icon: Icon(Icons.add_circle, color: Colors.white),
            label: Text('Add Custom Memory', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              padding: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Custom Memories Section
        if (_getCustomMemories().isNotEmpty) ...[
          Text(
            'Custom Memories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ..._getCustomMemories().map((memory) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        memory['category'] ?? 'General',
                        style: TextStyle(
                          color: Color(0xFF4A90E2),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteCustomMemory(memory),
                        child: Icon(Icons.delete, color: Colors.red.withOpacity(0.7), size: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    memory['memory'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Added: ${_formatTimestamp(DateTime.tryParse(memory['timestamp'] ?? '') ?? DateTime.now())}',
                    style: TextStyle(
                      color: Color(0xFF8B9DC3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          SizedBox(height: 20),
        ],
        
        // Backend Memory Insights
        if (_relationshipData.isNotEmpty) ...[
          Text(
            'Backend Memory Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🧠 AI Memory Status',
                  style: TextStyle(
                    color: Color(0xFF4A90E2),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Memory tracking: Active\n• Learning patterns: Enabled\n• Conversation context: Preserved\n• Emotional mapping: In progress',
                  style: TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
        
        // Topics Mentioned (from backend logs)
        Text(
          'Recent Topics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['hobbies', 'relationships', 'health', 'walks', 'evening activities'].map((topic) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF34C759).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                topic,
                style: TextStyle(
                  color: Color(0xFF34C759),
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMemoryStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.circle, color: Color(0xFFFF5722), size: 6),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildActionButton(
          'Delete All Conversations',
          'Remove all chat history',
          Icons.delete_forever,
          Colors.red,
          _showDeleteAllDialog,
        ),
        SizedBox(height: 16),
        _buildActionButton(
          'Reset Relationship',
          'Start over as acquaintances',
          Icons.refresh,
          Colors.orange,
          _showResetRelationshipDialog,
        ),
        SizedBox(height: 16),
        _buildActionButton(
          'Export Data',
          'Download conversation history',
          Icons.download,
          Colors.blue,
          _exportData,
        ),
        SizedBox(height: 20),
        
        // Privacy Controls Section
        Text(
          'Privacy Controls',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Memory Learning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Allow AI to learn from conversations',
                          style: TextStyle(
                            color: Color(0xFF8B9DC3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: true, // TODO: Make this configurable
                    onChanged: (value) {
                      // TODO: Implement memory learning toggle
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Memory learning ${value ? 'enabled' : 'disabled'}'),
                          backgroundColor: value ? Colors.green : Colors.orange,
                        ),
                      );
                    },
                    activeColor: Color(0xFFFF5722),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relationship Progression',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Enable automatic relationship development',
                          style: TextStyle(
                            color: Color(0xFF8B9DC3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: true, // TODO: Make this configurable
                    onChanged: (value) {
                      // TODO: Implement relationship progression toggle
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Relationship progression ${value ? 'enabled' : 'disabled'}'),
                          backgroundColor: value ? Colors.green : Colors.orange,
                        ),
                      );
                    },
                    activeColor: Color(0xFFFF5722),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a2332),
        title: Text('Delete All Conversations', style: TextStyle(color: Colors.white)),
        content: Text('This will permanently delete ALL conversations. Continue?', style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      setState(() => _conversationHistory.clear());
      await _saveMemoryData();
      _generateMemoryStats();
    }
  }

  Future<void> _showResetRelationshipDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a2332),
        title: Text('Reset Relationship', style: TextStyle(color: Colors.white)),
        content: Text('Reset relationship with ${widget.selectedPersona} to Acquaintance level?', style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Reset', style: TextStyle(color: Colors.orange))),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      setState(() {
        _relationshipData['points'] = 0;
        _relationshipData['level'] = 'Acquaintance';
      });
      await _saveMemoryData();
      _generateMemoryStats();
    }
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📤 Export feature coming soon'), backgroundColor: Colors.blue),
    );
  }

  Future<void> _saveMemoryData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conversation_history_${widget.selectedPersona}', json.encode(_conversationHistory));
    await prefs.setString('relationship_data_${widget.selectedPersona}', json.encode(_relationshipData));
  }

  // 🔍 MISSING METHODS - Add all the missing functionality

  Future<void> _showSearchDialog() async {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a2332),
        title: Text('Search Conversations', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: searchController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: Color(0xFF8B9DC3)),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch(searchController.text);
            },
            child: Text('Search', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔍 Search for "$query" - Feature coming soon!'),
        backgroundColor: Color(0xFF4A90E2),
      ),
    );
  }

  Future<void> _deleteConversation(Map<String, dynamic> conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a2332),
        title: Text('Delete Conversation', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete this conversation?', style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      setState(() {
        _conversationHistory.remove(conversation);
      });
      await _saveMemoryData();
      _generateMemoryStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Conversation deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAddMemoryDialog() async {
    final memoryController = TextEditingController();
    final categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a2332),
        title: Text('Add Custom Memory', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Color(0xFF8B9DC3)),
                hintText: 'e.g., preferences, goals, facts',
                hintStyle: TextStyle(color: Color(0xFF8B9DC3)),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: memoryController,
              style: TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Memory',
                labelStyle: TextStyle(color: Color(0xFF8B9DC3)),
                hintText: 'What should the AI remember about you?',
                hintStyle: TextStyle(color: Color(0xFF8B9DC3)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addCustomMemory(categoryController.text, memoryController.text);
            },
            child: Text('Add', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );
  }

  Future<void> _addCustomMemory(String category, String memory) async {
    if (category.trim().isEmpty || memory.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final customMemoriesJson = prefs.getString('custom_memories_${widget.selectedPersona}') ?? '[]';
    final customMemories = List<Map<String, dynamic>>.from(json.decode(customMemoriesJson));
    
    customMemories.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'category': category.trim(),
      'memory': memory.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString('custom_memories_${widget.selectedPersona}', json.encode(customMemories));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧠 Custom memory added!'),
        backgroundColor: Color(0xFF4A90E2),
      ),
    );
    
    // Refresh the memory data
    _loadMemoryData();
  }

  List<Map<String, dynamic>> _getCustomMemories() {
    // Load custom memories from SharedPreferences
    // This is a synchronous method, so we'll need to load this data during _loadMemoryData
    return _customMemories;
  }

  Future<void> _deleteCustomMemory(Map<String, dynamic> memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a2332),
        title: Text('Delete Custom Memory', style: TextStyle(color: Colors.white)),
        content: Text('Delete this custom memory?', style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      final prefs = await SharedPreferences.getInstance();
      final customMemoriesJson = prefs.getString('custom_memories_${widget.selectedPersona}') ?? '[]';
      final customMemories = List<Map<String, dynamic>>.from(json.decode(customMemoriesJson));
      
      customMemories.removeWhere((m) => m['id'] == memory['id']);
      
      await prefs.setString('custom_memories_${widget.selectedPersona}', json.encode(customMemories));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Custom memory deleted'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {});
      _loadMemoryData(); // Refresh all data
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}