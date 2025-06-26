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
  
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _geometryController;
  late AnimationController _particleController;
  
  late Animation<double> _heroOpacity;
  late Animation<double> _heroScale;
  late Animation<double> _nameCardOpacity;
  late Animation<double> _nameCardSlide;
  late Animation<double> _carouselOpacity;
  late Animation<double> _carouselSlide;
  late Animation<double> _buttonOpacity;
  late Animation<double> _skipOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _geometryRotation;
  late Animation<double> _glowOpacity;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final PageController _pageController = PageController();
  
  bool _isNameValid = false;
  int _currentFeaturePage = 0;

  // Feature showcase data
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'AI Voice Characters',
      'subtitle': 'Choose from diverse personalities',
      'description': 'From professional coaches to quirky characters like Pirate Captain, Wizard Sage, or Superhero - find the voice that motivates you best.',
      'icon': Icons.record_voice_over,
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      'examples': ['🤖 Robot Assistant', '🏴‍☠️ Pirate Captain', '🧙‍♂️ Wizard Sage', '🦸‍♀️ Superhero'],
    },
    {
      'title': 'Motivation Styles',
      'subtitle': 'Personalized encouragement',
      'description': 'Choose how you want to be motivated - from gentle encouragement to drill sergeant intensity.',
      'icon': Icons.psychology,
      'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
      'examples': ['💪 Drill Sergeant', '📣 Cheerleader', '🧠 Sage', '⚽ Coach'],
    },
    {
      'title': 'Smart Task Focus',
      'subtitle': 'Context-aware reminders',
      'description': 'Set your primary focus area and get tailored motivational messages for Study, Exercise, Work, and more.',
      'icon': Icons.flag,
      'gradient': [Color(0xFF11998e), Color(0xFF38ef7d)],
      'examples': ['📚 Study', '💪 Exercise', '💼 Work', '😴 Sleep'],
    },
    {
      'title': 'Critical Alerts',
      'subtitle': 'Cut through the noise',
      'description': 'Voice reminders that bypass silent mode and notification settings - because some motivation can\'t wait.',
      'icon': Icons.volume_up,
      'gradient': [Color(0xFFee0979), Color(0xFFff6a00)],
      'examples': ['🔊 Bypass Silent', '📢 Amber Alerts', '⏰ Never Miss', '🎯 Critical Focus'],
    },
    {
      'title': 'AI Personalization',
      'subtitle': 'Gets smarter with time',
      'description': 'Your AI coach learns your patterns, preferences, and what works best to keep you motivated and on track.',
      'icon': Icons.auto_awesome,
      'gradient': [Color(0xFFf093fb), Color(0xFFf5576c)],
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

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    
    if (hasSeenOnboarding) {
      // Skip to dashboard if already seen onboarding
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
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

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    
    // Save user name if provided
    final userName = _nameController.text.trim();
    if (userName.isNotEmpty) {
      await prefs.setString('user_name', userName);
    }
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 4000),
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

    // Hero animation
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _heroScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // Name card animations
    _nameCardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
      ),
    );

    _nameCardSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Carousel animations
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

    // Button animations
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Skip link animation
    _skipOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
      ),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
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

  void _startAnimationSequence() {
    _mainController.forward();
  }

  void _navigateToApp() async {
    final userName = _nameController.text.trim();
    
    if (userName.length < 2) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please tell us what to call you 😊'),
          backgroundColor: const Color(0xFFD4AF37),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _nameFocusNode.requestFocus();
      return;
    }

    HapticFeedback.heavyImpact();
    
    // Mark onboarding as complete
    await _markOnboardingComplete();
    
    // Navigate to home screen directly
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
    
    // Mark onboarding as complete
    await _markOnboardingComplete();
    
    // Navigate to home screen directly
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
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _pageController.dispose();
    _mainController.dispose();
    _pulseController.dispose();
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
            // Sophisticated geometric background
            AnimatedBuilder(
              animation: _geometryController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GeometricPatternPainter(_geometryRotation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Refined particles background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RefinedParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;
                  
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 48 : 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: Column(
                        children: [
                          // Hero Logo Section
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _heroOpacity,
                              _heroScale,
                              _pulseController,
                              _geometryController,
                            ]),
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _heroScale.value * _pulseScale.value,
                                child: Opacity(
                                  opacity: _heroOpacity.value,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      
                                      // Logo with geometric ring
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outer geometric ring
                                          Transform.rotate(
                                            angle: _geometryRotation.value * 2 * math.pi,
                                            child: Container(
                                              width: isTablet ? 120 : 100,
                                              height: isTablet ? 120 : 100,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(0xFFD4AF37).withOpacity(_glowOpacity.value * 0.3),
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
                                            width: isTablet ? 90 : 80,
                                            height: isTablet ? 90 : 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFD4AF37).withOpacity(_glowOpacity.value * 0.3),
                                                  blurRadius: 30,
                                                  spreadRadius: 5,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Main icon
                                          Container(
                                            padding: EdgeInsets.all(isTablet ? 20 : 16),
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
                                              Icons.auto_awesome,
                                              size: isTablet ? 45 : 40,
                                              color: const Color(0xFFD4AF37),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: isTablet ? 32 : 24),
                                      
                                      // App title
                                      ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFFFD700),
                                            Color(0xFFD4AF37),
                                            Color(0xFFB8860B),
                                          ],
                                          stops: [0.0, 0.5, 1.0],
                                        ).createShader(bounds),
                                        child: Text(
                                          'Motivator.AI',
                                          style: TextStyle(
                                            fontSize: isTablet ? 36 : 32,
                                            fontWeight: FontWeight.w200,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                            height: 1.0,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0xFFD4AF37),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                              Shadow(
                                                color: Colors.black45,
                                                blurRadius: 4,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      
                                      SizedBox(height: isTablet ? 12 : 8),
                                      
                                      // Separator line
                                      Container(
                                        width: isTablet ? 120 : 100,
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFFD4AF37),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      SizedBox(height: isTablet ? 16 : 12),
                                      
                                      Text(
                                        'Voice-powered reminders that cut through the noise.',
                                        style: TextStyle(
                                          color: const Color(0xFF8B9DC3).withOpacity(0.9),
                                          fontSize: isTablet ? 18 : 16,
                                          height: 1.4,
                                          fontWeight: FontWeight.w300,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 40 : 32),

                          // Name input section
                          AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _nameCardSlide.value),
                                child: Opacity(
                                  opacity: _nameCardOpacity.value,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(isTablet ? 28 : 24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _nameFocusNode.hasFocus 
                                            ? const Color(0xFFD4AF37).withOpacity(0.5)
                                            : const Color(0xFFD4AF37).withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD4AF37).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                                color: Color(0xFFD4AF37),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'What should I call you?',
                                              style: TextStyle(
                                                color: const Color(0xFFD4AF37),
                                                fontSize: isTablet ? 18 : 16,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isTablet ? 20 : 16),
                                        
                                        Text(
                                          'Your AI coach will use this name to create personalized motivational messages just for you.',
                                          style: TextStyle(
                                            color: const Color(0xFF8B9DC3).withOpacity(0.8),
                                            fontSize: isTablet ? 16 : 14,
                                            height: 1.4,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        SizedBox(height: isTablet ? 20 : 16),
                                        
                                        // Name input field
                                        TextField(
                                          controller: _nameController,
                                          focusNode: _nameFocusNode,
                                          textCapitalization: TextCapitalization.words,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isTablet ? 20 : 18,
                                            fontWeight: FontWeight.w300,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your preferred name',
                                            hintStyle: TextStyle(
                                              color: const Color(0xFF8B9DC3).withOpacity(0.5),
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.w300,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.05),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFD4AF37),
                                                width: 1,
                                              ),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: isTablet ? 20 : 16,
                                            ),
                                            suffixIcon: _isNameValid 
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Color(0xFFD4AF37),
                                                  )
                                                : null,
                                          ),
                                          onSubmitted: (_) => _navigateToApp(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 40 : 32),

                          // Feature carousel section
                          AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _carouselSlide.value),
                                child: Opacity(
                                  opacity: _carouselOpacity.value,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD4AF37).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.auto_awesome,
                                                color: Color(0xFFD4AF37),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'What to Expect',
                                              style: TextStyle(
                                                color: const Color(0xFFD4AF37),
                                                fontSize: isTablet ? 18 : 16,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      SizedBox(height: isTablet ? 20 : 16),
                                      
                                      // Horizontal carousel
                                      SizedBox(
                                        height: isTablet ? 380 : 350, // Increased height to prevent overflow
                                        child: PageView.builder(
                                          controller: _pageController,
                                          onPageChanged: (index) {
                                            setState(() {
                                              _currentFeaturePage = index;
                                            });
                                          },
                                          itemCount: _features.length,
                                          itemBuilder: (context, index) {
                                            final feature = _features[index];
                                            return Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 8),
                                              child: _buildFeatureCard(feature, isTablet),
                                            );
                                          },
                                        ),
                                      ),
                                      
                                      SizedBox(height: isTablet ? 20 : 16),
                                      
                                      // Page indicators
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(_features.length, (index) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            width: _currentFeaturePage == index ? 24 : 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _currentFeaturePage == index
                                                  ? const Color(0xFFD4AF37)
                                                  : const Color(0xFF8B9DC3).withOpacity(0.3),
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
                          ),

                          SizedBox(height: isTablet ? 40 : 32),

                          // Get Started button
                          AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _buttonOpacity.value,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: isTablet ? 64 : 56,
                                  child: ElevatedButton(
                                    onPressed: _navigateToApp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isNameValid
                                          ? const Color(0xFFD4AF37)
                                          : const Color(0xFF8B9DC3).withOpacity(0.3),
                                      foregroundColor: _isNameValid
                                          ? Colors.black
                                          : const Color(0xFF8B9DC3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                                      ),
                                      elevation: _isNameValid ? 12 : 0,
                                      shadowColor: _isNameValid 
                                          ? const Color(0xFFD4AF37).withOpacity(0.4)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rocket_launch_rounded,
                                          color: _isNameValid
                                              ? Colors.black
                                              : const Color(0xFF8B9DC3),
                                          size: isTablet ? 28 : 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Begin My Journey',
                                          style: TextStyle(
                                            color: _isNameValid
                                                ? Colors.black
                                                : const Color(0xFF8B9DC3),
                                            fontSize: isTablet ? 20 : 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 32 : 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Skip link - bottom right
            Positioned(
              bottom: 32,
              right: 24,
              child: AnimatedBuilder(
                animation: _skipOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _skipOpacity.value,
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B9DC3).withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip',
                            style: TextStyle(
                              color: const Color(0xFF8B9DC3).withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF8B9DC3).withOpacity(0.8),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20), // Reduced padding slightly
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature icon with gradient
          Container(
            width: isTablet ? 54 : 46, // Slightly smaller icon
            height: isTablet ? 54 : 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: feature['gradient']),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: feature['gradient'][0].withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              feature['icon'],
              color: Colors.white,
              size: isTablet ? 26 : 22, // Slightly smaller icon
            ),
          ),
          
          SizedBox(height: isTablet ? 16 : 14), // Reduced spacing
          
          // Feature title
          Text(
            feature['title'],
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18, // Slightly smaller title
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          
          SizedBox(height: isTablet ? 6 : 4), // Reduced spacing
          
          // Feature subtitle
          Text(
            feature['subtitle'],
            style: TextStyle(
              color: const Color(0xFFD4AF37),
              fontSize: isTablet ? 14 : 13, // Slightly smaller subtitle
              fontWeight: FontWeight.w400,
            ),
          ),
          
          SizedBox(height: isTablet ? 12 : 10), // Reduced spacing
          
          // Feature description
          Text(
            feature['description'],
            style: TextStyle(
              color: const Color(0xFF8B9DC3).withOpacity(0.9),
              fontSize: isTablet ? 14 : 13, // Slightly smaller description
              height: 1.3, // Tighter line height
              fontWeight: FontWeight.w300,
            ),
            maxLines: 3, // Limit description to 3 lines
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: isTablet ? 16 : 12), // Reduced spacing
          
          // Feature examples - make more compact
          Expanded( // Use Expanded to take remaining space
            child: SingleChildScrollView( // Allow scrolling if needed
              child: Wrap(
                spacing: 6, // Reduced spacing
                runSpacing: 4, // Reduced spacing
                children: (feature['examples'] as List<String>).take(4).map((example) { // Limit to 4 examples
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Smaller padding
                    decoration: BoxDecoration(
                      color: feature['gradient'][0].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: feature['gradient'][0].withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        color: feature['gradient'][0],
                        fontSize: isTablet ? 12 : 11, // Smaller example text
                        fontWeight: FontWeight.w500,
                      ),
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
}

// Same painters as splash screen for visual consistency
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
    final radius = 40.0;

    // Draw rotating geometric points
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + (animationValue * 2 * math.pi);
      final x = centerX + math.cos(angle) * radius;
      final y = centerY + math.sin(angle) * radius;

      canvas.drawCircle(
        Offset(x, y),
        2,
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