import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'motivator_home.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _geometryController;
  late AnimationController _particleController;
  late AnimationController _carouselController;
  
  // Animations
  late Animation<double> _heroOpacity;
  late Animation<double> _heroScale;
  late Animation<Offset> _heroSlide;
  late Animation<double> _nameCardOpacity;
  late Animation<double> _nameCardSlide;
  late Animation<double> _carouselOpacity;
  late Animation<double> _carouselSlide;
  late Animation<double> _buttonOpacity;
  late Animation<double> _skipOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _geometryRotation;
  late Animation<double> _glowOpacity;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final PageController _pageController = PageController();
  
  // State
  bool _isNameValid = false;
  int _currentFeaturePage = 0;

  // Modern Color Palette
  static const Color primaryBackground = Color(0xFF0F1419);
  static const Color cardBackground = Color(0xFF1A1F2E);
  static const Color accentTeal = Color(0xFF00D4AA);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C8);
  static const Color glassOverlay = Color(0x1AFFFFFF);

  // Enhanced Feature Data
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'AI Voice Characters',
      'subtitle': 'Choose from diverse personalities',
      'description': 'From professional coaches to quirky characters like Pirate Captain, Wizard Sage, or Superhero - find the voice that motivates you best.',
      'icon': Icons.record_voice_over_rounded,
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
      'examples': ['🤖 Robot Assistant', '🏴‍☠️ Pirate Captain', '🧙‍♂️ Wizard Sage', '🦸‍♀️ Superhero'],
    },
    {
      'title': 'Motivation Styles',
      'subtitle': 'Personalized encouragement',
      'description': 'Choose how you want to be motivated - from gentle encouragement to drill sergeant intensity.',
      'icon': Icons.psychology_rounded,
      'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
      'examples': ['💪 Drill Sergeant', '📣 Cheerleader', '🧠 Sage', '⚽ Coach'],
    },
    {
      'title': 'Smart Task Focus',
      'subtitle': 'Context-aware reminders',
      'description': 'Set your primary focus area and get tailored motivational messages for Study, Exercise, Work, and more.',
      'icon': Icons.flag_rounded,
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      'examples': ['📚 Study', '💪 Exercise', '💼 Work', '😴 Sleep'],
    },
    {
      'title': 'Critical Alerts',
      'subtitle': 'Cut through the noise',
      'description': 'Voice reminders that bypass silent mode and notification settings - because some motivation can\'t wait.',
      'icon': Icons.notifications_active_rounded,
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
      'examples': ['🚨 Emergency Mode', '📱 Screen Takeover', '🔊 Sound Override', '⚡ Instant Alert'],
    },
    {
      'title': 'Adaptive Intelligence',
      'subtitle': 'Learns and evolves with you',
      'description': 'AI that understands your patterns, preferences, and optimal motivation timing for maximum effectiveness.',
      'icon': Icons.auto_awesome_rounded,
      'gradient': [Color(0xFF8360c3), Color(0xFF2ebf91)],
      'examples': ['🧠 Learns You', '📈 Adapts Style', '🎯 Perfect Timing', '✨ AI Magic'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    _setupAnimations();
    _setupTextFieldListener();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _pageController.dispose();
    _mainController.dispose();
    _pulseController.dispose();
    _geometryController.dispose();
    _particleController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    
    if (hasSeenOnboarding && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  void _setupTextFieldListener() {
    _nameController.addListener(() {
      final newIsValid = _nameController.text.trim().length >= 2;
      if (newIsValid != _isNameValid) {
        setState(() {
          _isNameValid = newIsValid;
        });
      }
    });
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _geometryController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _carouselController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Hero Animations
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _heroScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.fastLinearToSlowEaseIn),
      ),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    // Name Card Animations
    _nameCardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _nameCardSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Carousel Animations
    _carouselOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeInOut),
      ),
    );

    _carouselSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Button Animations
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _skipOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Additional Animations
    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _geometryRotation = Tween<double>(begin: 0.0, end: 1.0).animate(_geometryController);
    _glowOpacity = Tween<double>(begin: 0.3, end: 0.8).animate(_pulseController);
  }

  void _startAnimationSequence() {
    _mainController.forward();
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    
    final userName = _nameController.text.trim();
    if (userName.isNotEmpty) {
      await prefs.setString('user_name', userName);
    }
  }

  void _navigateToApp() async {
    if (!_isNameValid) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter at least 2 characters for your name'),
          backgroundColor: Colors.orange.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _nameFocusNode.requestFocus();
      return;
    }

    HapticFeedback.heavyImpact();
    await _markOnboardingComplete();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MotivatorHome(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  void _skipOnboarding() async {
    HapticFeedback.lightImpact();
    await _markOnboardingComplete();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MotivatorHome(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
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
              Color(0xFF0a1428), // Deep navy
              Color(0xFF1a2332), // Navy blue
              Color(0xFF0f1419), // Dark slate
              Color(0xFF000000), // Black
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Enhanced Geometric Background
            AnimatedBuilder(
              animation: _geometryController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ModernGeometricPainter(_geometryRotation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Enhanced Particle System
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PremiumParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;
                  
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 48 : 24,
                      vertical: 24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hero Section
                          _PremiumHeroSection(
                            heroOpacity: _heroOpacity,
                            heroScale: _heroScale,
                            heroSlide: _heroSlide,
                            pulseScale: _pulseScale,
                            glowOpacity: _glowOpacity,
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 60 : 48),
                          
                          // Name Input Section
                          _GlassmorphicNameCard(
                            nameCardOpacity: _nameCardOpacity,
                            nameCardSlide: _nameCardSlide,
                            nameController: _nameController,
                            nameFocusNode: _nameFocusNode,
                            isNameValid: _isNameValid,
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 48 : 40),
                          
                          // Feature Carousel
                          _SleekFeatureCarousel(
                            carouselOpacity: _carouselOpacity,
                            carouselSlide: _carouselSlide,
                            features: _features,
                            pageController: _pageController,
                            currentFeaturePage: _currentFeaturePage,
                            onPageChanged: (index) {
                              setState(() {
                                _currentFeaturePage = index;
                              });
                            },
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 48 : 40),
                          
                          // Action Button
                          _PremiumActionButton(
                            buttonOpacity: _buttonOpacity,
                            isNameValid: _isNameValid,
                            onPressed: _navigateToApp,
                            isTablet: isTablet,
                          ),
                          
                          SizedBox(height: isTablet ? 32 : 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Skip Button
            _SleekSkipButton(
              skipOpacity: _skipOpacity,
              onPressed: _skipOnboarding,
            ),
          ],
        ),
      ),
    );
  }
}

// 🌟 Premium Hero Section Component
class _PremiumHeroSection extends StatelessWidget {
  final Animation<double> heroOpacity;
  final Animation<double> heroScale;
  final Animation<Offset> heroSlide;
  final Animation<double> pulseScale;
  final Animation<double> glowOpacity;
  final bool isTablet;

  const _PremiumHeroSection({
    required this.heroOpacity,
    required this.heroScale,
    required this.heroSlide,
    required this.pulseScale,
    required this.glowOpacity,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: heroOpacity,
      builder: (context, child) {
        return SlideTransition(
          position: heroSlide,
          child: Transform.scale(
            scale: heroScale.value,
            child: Opacity(
              opacity: heroOpacity.value,
              child: Column(
                children: [
                  // Glowing Logo Container
                  AnimatedBuilder(
                    animation: glowOpacity,
                    builder: (context, child) {
                      return Container(
                        width: isTablet ? 120 : 100,
                        height: isTablet ? 120 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _OnboardingScreenState.accentTeal.withOpacity(glowOpacity.value),
                              _OnboardingScreenState.accentTeal.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _OnboardingScreenState.accentTeal.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: pulseScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: pulseScale.value,
                              child: Icon(
                                Icons.psychology_rounded,
                                size: isTablet ? 60 : 50,
                                color: _OnboardingScreenState.accentTeal,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  // App Title
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF00D4AA),
                                Color(0xFF64FFDA),
                                Color(0xFFD4AF37),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Motivator.AI',
                              style: TextStyle(
                                fontSize: isTablet ? 48 : 40,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 3.0,
                                height: 1.1,
                                fontFeatures: const [FontFeature.proportionalFigures()],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: isTablet ? 12 : 8),
                  
                  // Subtitle
                  Text(
                    'Advanced AI-Powered Motivation Platform',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: _OnboardingScreenState.textSecondary.withOpacity(0.8),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🪟 Glassmorphic Name Card Component
class _GlassmorphicNameCard extends StatelessWidget {
  final Animation<double> nameCardOpacity;
  final Animation<double> nameCardSlide;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final bool isNameValid;
  final bool isTablet;

  const _GlassmorphicNameCard({
    required this.nameCardOpacity,
    required this.nameCardSlide,
    required this.nameController,
    required this.nameFocusNode,
    required this.isNameValid,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: nameCardOpacity,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, nameCardSlide.value),
          child: Opacity(
            opacity: nameCardOpacity.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 32 : 24),
                  decoration: BoxDecoration(
                    color: _OnboardingScreenState.glassOverlay,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // More sophisticated header
                      Column(
                        children: [
                          Text(
                            'Personal Setup',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w500,
                              color: _OnboardingScreenState.accentTeal.withOpacity(0.8),
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(
                            'How would you like to be addressed?',
                            style: TextStyle(
                              fontSize: isTablet ? 24 : 22,
                              fontWeight: FontWeight.w400,
                              color: _OnboardingScreenState.textPrimary,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isTablet ? 24 : 20),
                      
                      // Enhanced Text Field
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: nameController,
                            focusNode: nameFocusNode,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: _OnboardingScreenState.textPrimary,
                              letterSpacing: 0.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Your preferred name',
                              hintStyle: TextStyle(
                                color: _OnboardingScreenState.textSecondary.withOpacity(0.6),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: _OnboardingScreenState.accentTeal,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
                            ),
                            textCapitalization: TextCapitalization.words,
                            maxLength: 20,
                            buildCounter: (context, {required int currentLength, required int? maxLength, required bool isFocused}) => null,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: isTablet ? 16 : 12),
                      
                      // Validation Indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isNameValid 
                              ? _OnboardingScreenState.accentTeal.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isNameValid 
                                ? _OnboardingScreenState.accentTeal.withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNameValid ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: isNameValid 
                                  ? _OnboardingScreenState.accentTeal
                                  : _OnboardingScreenState.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isNameValid ? 'Perfect!' : 'Minimum 2 characters required',
                              style: TextStyle(
                                color: isNameValid 
                                    ? _OnboardingScreenState.accentTeal
                                    : _OnboardingScreenState.textSecondary.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🎠 Sleek Feature Carousel Component
class _SleekFeatureCarousel extends StatelessWidget {
  final Animation<double> carouselOpacity;
  final Animation<double> carouselSlide;
  final List<Map<String, dynamic>> features;
  final PageController pageController;
  final int currentFeaturePage;
  final Function(int) onPageChanged;
  final bool isTablet;

  const _SleekFeatureCarousel({
    required this.carouselOpacity,
    required this.carouselSlide,
    required this.features,
    required this.pageController,
    required this.currentFeaturePage,
    required this.onPageChanged,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: carouselOpacity,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, carouselSlide.value),
          child: Opacity(
            opacity: carouselOpacity.value,
            child: Column(
              children: [
                // Section Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _OnboardingScreenState.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: _OnboardingScreenState.accentGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'What to Expect',
                      style: TextStyle(
                        color: _OnboardingScreenState.accentGold,
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isTablet ? 24 : 20),
                
                // Feature Cards Carousel
                SizedBox(
                  height: isTablet ? 420 : 380,
                  child: PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: _PremiumFeatureCard(
                          feature: feature,
                          isTablet: isTablet,
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: isTablet ? 24 : 20),
                
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(features.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentFeaturePage == index ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentFeaturePage == index
                            ? _OnboardingScreenState.accentGold
                            : _OnboardingScreenState.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🎯 Premium Feature Card Component
class _PremiumFeatureCard extends StatelessWidget {
  final Map<String, dynamic> feature;
  final bool isTablet;

  const _PremiumFeatureCard({
    required this.feature,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 28 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (feature['gradient'][0] as Color).withOpacity(0.1),
                (feature['gradient'][1] as Color).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (feature['gradient'][0] as Color).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: feature['gradient'].cast<Color>(),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (feature['gradient'][0] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      feature['icon'],
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'],
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: _OnboardingScreenState.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['subtitle'],
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            color: _OnboardingScreenState.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isTablet ? 20 : 16),
              
              // Description
              Text(
                feature['description'],
                style: TextStyle(
                  fontSize: isTablet ? 16 : 15,
                  color: _OnboardingScreenState.textSecondary,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
              
              SizedBox(height: isTablet ? 24 : 20),
              
              // Examples Grid
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: feature['examples'].length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          feature['examples'][index],
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 11,
                            color: _OnboardingScreenState.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}

// 🚀 Premium Action Button Component
class _PremiumActionButton extends StatelessWidget {
  final Animation<double> buttonOpacity;
  final bool isNameValid;
  final VoidCallback onPressed;
  final bool isTablet;

  const _PremiumActionButton({
    required this.buttonOpacity,
    required this.isNameValid,
    required this.onPressed,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: buttonOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: buttonOpacity.value,
          child: Material(
            elevation: isNameValid ? 12 : 4,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: isTablet ? 64 : 56,
                decoration: BoxDecoration(
                  gradient: isNameValid ? LinearGradient(
                    colors: [
                      _OnboardingScreenState.accentGold,
                      _OnboardingScreenState.accentGold.withOpacity(0.8),
                    ],
                  ) : null,
                  color: isNameValid ? null : _OnboardingScreenState.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: isNameValid ? Colors.black : _OnboardingScreenState.textSecondary,
                        size: isTablet ? 24 : 20,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Launch Experience',
                        style: TextStyle(
                          color: isNameValid ? Colors.black : _OnboardingScreenState.textSecondary,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ⏭️ Sleek Skip Button Component
class _SleekSkipButton extends StatelessWidget {
  final Animation<double> skipOpacity;
  final VoidCallback onPressed;

  const _SleekSkipButton({
    required this.skipOpacity,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      right: 24,
      child: AnimatedBuilder(
        animation: skipOpacity,
        builder: (context, child) {
          return Opacity(
            opacity: skipOpacity.value,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: _OnboardingScreenState.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _OnboardingScreenState.textSecondary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 🎨 Modern Geometric Painter
class _ModernGeometricPainter extends CustomPainter {
  final double rotation;

  _ModernGeometricPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.05);

    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (rotation * 2 * math.pi);
      final radius = size.width * 0.3 + (math.sin(rotation * 2 * math.pi) * 20);
      
      final start = center;
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      canvas.drawLine(start, end, paint);
    }
    
    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      final circleRadius = (size.width * 0.1 * i) + (math.sin(rotation * 2 * math.pi) * 10);
      canvas.drawCircle(center, circleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ✨ Premium Particle Painter
class _PremiumParticlePainter extends CustomPainter {
  final double animationValue;

  _PremiumParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final phase = (animationValue + (i * 0.1)) % 1.0;
      final opacity = (math.sin(phase * math.pi) * 0.4).clamp(0.0, 1.0);
      final radius = 1 + (math.sin(phase * math.pi) * 2);
      
      paint.color = Color.lerp(
        _OnboardingScreenState.accentTeal,
        _OnboardingScreenState.accentGold,
        random.nextDouble(),
      )!.withOpacity(opacity);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}