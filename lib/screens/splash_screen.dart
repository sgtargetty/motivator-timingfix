import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'onboarding_screen.dart';

// 🎨 MINIMAL DESIGN TOKEN SYSTEM
class AppDesignTokens {
  // ===== PRIMARY BRAND COLORS =====
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color backgroundDark = Color(0xFF0a1428);
  static const Color backgroundNavy = Color(0xFF1a2332);
  static const Color backgroundSlate = Color(0xFF0f1419);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textTertiary = Color(0xFF8B9DC3);
  
  // ===== SPACING SYSTEM =====
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXXL = 48.0;
  
  // ===== ANIMATION TIMINGS =====
  static const Duration animationXSlow = Duration(milliseconds: 1200);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _geometryController;
  
  // Letter animations for "Motivatr"
  late List<Animation<Offset>> _motivatrLetterSlides;
  late List<Animation<double>> _motivatrLetterOpacities;
  late List<Animation<Offset>> _motivatrLetterExits;
  late List<Animation<double>> _motivatrLetterExitOpacities;
  
  // Animations for "&"
  late Animation<Offset> _ampersandSlide;  
  late Animation<double> _ampersandOpacity;
  late Animation<Offset> _ampersandExit;  
  late Animation<double> _ampersandExitOpacity;
  
  // Letter animations for "Co."
  late List<Animation<Offset>> _coLetterSlides;
  late List<Animation<double>> _coLetterOpacities;
  late List<Animation<Offset>> _coLetterExits;
  late List<Animation<double>> _coLetterExitOpacities;
  
  late Animation<double> _progressOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _statusOpacity;
  late Animation<double> _geometryRotation;

  final String motivatrText = "Motivatr";
  final String coText = "Co.";

  @override
  void initState() {
    super.initState();

    // Main animation controller - SIMPLE TIMING
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500), // Back to reasonable duration
    );

    // Background controllers
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _geometryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    // Initialize letter animations
    _initializeLetterAnimations();

    // Progress and status animations - AFTER app name is complete
    _progressOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 0.75, curve: Curves.easeInOut), // AFTER all letters
    ));

    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 0.9, curve: Curves.easeOutCubic), // Fill over time
    ));

    _statusOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.72, 0.77, curve: Curves.easeInOut), // With progress
    ));

    _geometryRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_geometryController);

    // Start the animation
    _startAnimation();
  }

  void _initializeLetterAnimations() {
    // Initialize lists
    _motivatrLetterSlides = [];
    _motivatrLetterOpacities = [];
    _motivatrLetterExits = [];
    _motivatrLetterExitOpacities = [];
    _coLetterSlides = [];
    _coLetterOpacities = [];
    _coLetterExits = [];
    _coLetterExitOpacities = [];

    // Create FLY-IN animations for each letter in "Motivatr" (8 letters) - FROM RIGHT
    for (int i = 0; i < motivatrText.length; i++) {
      final startTime = 0.0 + (i * 0.05); // Start immediately, clear stagger
      final endTime = startTime + 0.2; // Clear entrance duration

      // FLY-IN from RIGHT
      _motivatrLetterSlides.add(
        Tween<Offset>(
          begin: const Offset(2.0, 0), // Fly in from RIGHT
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.easeOutCubic),
        )),
      );

      _motivatrLetterOpacities.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.easeInOut),
        )),
      );

      // Remove exit animations for now - keep it simple
      _motivatrLetterExits.add(
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero, // No exit movement
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.95, 1.0, curve: Curves.easeInCubic),
        )),
      );

      _motivatrLetterExitOpacities.add(
        Tween<double>(
          begin: 1.0,
          end: 1.0, // Stay visible
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.95, 1.0, curve: Curves.easeInOut),
        )),
      );
    }

    // Animation for "&" (comes after "Motivatr") - FLY-IN from RIGHT
    _ampersandSlide = Tween<Offset>(
      begin: const Offset(2.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeOutCubic), // Clear timing after letters
    ));

    _ampersandOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
    ));

    // "&" - Remove exit animation for now
    _ampersandExit = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero, // No exit
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.95, 1.0, curve: Curves.easeInCubic),
    ));

    _ampersandExitOpacity = Tween<double>(
      begin: 1.0,
      end: 1.0, // Stay visible
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.95, 1.0, curve: Curves.easeInOut),
    ));

    // Create animations for each letter in "Co." (3 characters) - FLY-IN from RIGHT
    for (int i = 0; i < coText.length; i++) {
      final startTime = 0.45 + (i * 0.05); // Start with "&", clear stagger
      final endTime = startTime + 0.2; // Clear entrance

      // FLY-IN from RIGHT
      _coLetterSlides.add(
        Tween<Offset>(
          begin: const Offset(2.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.easeOutCubic),
        )),
      );

      _coLetterOpacities.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: Interval(startTime, endTime, curve: Curves.easeInOut),
        )),
      );

      // Remove exit animations for now - keep it simple
      _coLetterExits.add(
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero, // No exit
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.95, 1.0, curve: Curves.easeInCubic),
        )),
      );

      _coLetterExitOpacities.add(
        Tween<double>(
          begin: 1.0,
          end: 1.0, // Stay visible
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.95, 1.0, curve: Curves.easeInOut),
        )),
      );
    }
  }

  void _startAnimation() async {
    // Add haptic feedback for premium feel
    HapticFeedback.lightImpact();
    
    // Start animation and wait for completion
    await _mainController.forward();
    
    // Extra wait as requested (1 second)
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      // Final haptic before transition
      HapticFeedback.mediumImpact();
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: AppDesignTokens.animationXSlow,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _geometryController.dispose();
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
              AppDesignTokens.backgroundDark,
              AppDesignTokens.backgroundNavy,
              AppDesignTokens.backgroundSlate,
              AppDesignTokens.backgroundBlack,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle geometric background
            AnimatedBuilder(
              animation: _geometryController,
              builder: (context, child) {
                return CustomPaint(
                  painter: MinimalGeometricPainter(_geometryRotation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Minimal particles background
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: MinimalParticlePainter(_particleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Main content - MINIMALIST
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // STACKED BRAND NAME with letter fly-in animation
                  Column(
                    children: [
                      // "Motivatr" with letter-by-letter animation
                      _buildAnimatedWord(
                        motivatrText,
                        _motivatrLetterSlides,
                        _motivatrLetterOpacities,
                        _motivatrLetterExits,
                        _motivatrLetterExitOpacities,
                        fontSize: 48, // BIGGER
                      ),
                      
                      SizedBox(height: AppDesignTokens.spacingS),
                      
                      // "&" with animation - SIMPLIFIED
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _ampersandSlide, 
                          _ampersandOpacity,
                          // Remove exit animations for now
                        ]),
                        builder: (context, child) {
                          return Transform.translate(
                            offset: _ampersandSlide.value,
                            child: Opacity(
                              opacity: _ampersandOpacity.value,
                              child: ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFD4AF37),
                                    Color(0xFFB8860B),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  '&',
                                  style: TextStyle(
                                    fontSize: 32, // BIGGER
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                    fontFamily: 'serif',
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: AppDesignTokens.spacingS),
                      
                      // "Co." with letter-by-letter animation
                      _buildAnimatedWord(
                        coText,
                        _coLetterSlides,
                        _coLetterOpacities,
                        _coLetterExits,
                        _coLetterExitOpacities,
                        fontSize: 40, // BIGGER
                      ),
                    ],
                  ),

                  SizedBox(height: AppDesignTokens.spacingXXL * 2),

                  // Minimal progress indicator
                  AnimatedBuilder(
                    animation: Listenable.merge([_progressOpacity, _progressValue]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _progressOpacity.value,
                        child: Column(
                          children: [
                            Container(
                              width: 200,
                              height: 1,
                              decoration: BoxDecoration(
                                color: AppDesignTokens.textTertiary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(0.5),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 200 * _progressValue.value,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppDesignTokens.primaryGold,
                                          Color(0xFFFFD700),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppDesignTokens.primaryGold.withOpacity(0.4),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: AppDesignTokens.spacingL),
                            
                            // Status text
                            AnimatedBuilder(
                              animation: _statusOpacity,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _statusOpacity.value,
                                  child: Text(
                                    'INITIALIZING AI COMPANIONS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                      color: AppDesignTokens.textTertiary.withOpacity(0.8),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWord(
    String word,
    List<Animation<Offset>> letterSlides,
    List<Animation<double>> letterOpacities,
    List<Animation<Offset>> letterExits,
    List<Animation<double>> letterExitOpacities,
    {required double fontSize}
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(word.length, (index) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            letterSlides[index], 
            letterOpacities[index],
            // Remove exit animations from merge for now
          ]),
          builder: (context, child) {
            return Transform.translate(
              // Just use entry slide for now
              offset: letterSlides[index].value,
              child: Opacity(
                // Just use entry opacity for now  
                opacity: letterOpacities[index].value,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFD700), // Bright gold top
                      Color(0xFFD4AF37), // Rich gold middle
                      Color(0xFFB8860B), // Deep gold bottom
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    word[index],
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: 2,
                      fontFamily: 'serif',
                      height: 1.0,
                      shadows: const [
                        Shadow(
                          color: AppDesignTokens.primaryGold,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Minimal geometric pattern painter
class MinimalGeometricPainter extends CustomPainter {
  final double animationValue;

  MinimalGeometricPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppDesignTokens.primaryGold.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Minimal geometric lines
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + (animationValue * math.pi / 6);
      final startX = centerX + math.cos(angle) * 150;
      final startY = centerY + math.sin(angle) * 150;
      final endX = centerX + math.cos(angle) * 220;
      final endY = centerY + math.sin(angle) * 220;

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

// Minimal particle painter
class MinimalParticlePainter extends CustomPainter {
  final double animationValue;
  final List<MinimalParticle> particles = [];

  MinimalParticlePainter(this.animationValue) {
    // Fewer, more subtle particles
    for (int i = 0; i < 15; i++) {
      particles.add(MinimalParticle());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = (particle.x * size.width) % size.width;
      final y = (particle.y * size.height + 
                 animationValue * particle.speed * size.height) % size.height;
      
      final opacity = (math.sin(animationValue * math.pi + particle.phase) + 1) / 2;
      paint.color = AppDesignTokens.primaryGold.withOpacity(opacity * 0.1);
      
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

class MinimalParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  MinimalParticle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 1.0 + 0.5,
        speed = math.Random().nextDouble() * 0.2 + 0.03,
        phase = math.Random().nextDouble() * 2 * math.pi;
}