import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _geometryController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _glowOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _progressOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _geometryRotation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500), // Back to original duration
    );

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Geometry animation controller
    _geometryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Logo animations - more refined, less bouncy
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart),
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
    ));

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    // Text animations - simple fade-in approach
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
    ));

    _subtitleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 0.9, curve: Curves.easeInOut), // Start after main text
    ));

    // Refined glow effect
    _glowOpacity = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Progress animations
    _progressOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.75, 0.85, curve: Curves.easeInOut), // After subtitle
    ));

    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeInOut), // Fills to end
    ));

    // Geometry rotation
    _geometryRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_geometryController);

    // Start the animation
    _startAnimation();
  }

  void _startAnimation() async {
    await _mainController.forward();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
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

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sophisticated logo with geometric elements
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _logoScale,
                      _logoOpacity,
                      _logoSlide,
                      _glowOpacity,
                      _geometryRotation,
                    ]),
                    builder: (context, child) {
                      return SlideTransition(
                        position: _logoSlide,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer geometric ring
                                Transform.rotate(
                                  angle: _geometryRotation.value * 2 * math.pi,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFD4AF37).withOpacity(_glowOpacity.value * 0.3), // Gold
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
                                  width: 100,
                                  height: 100,
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
                                // Main icon - brain with geometric style
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFD4AF37).withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome, // More sophisticated than psychology
                                    size: 50,
                                    color: Color(0xFFD4AF37), // Gold
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Sophisticated title with sequential letter animation
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          // Simplified title with fade-in only (no complex letter animations)
                          AnimatedBuilder(
                            animation: _textOpacity,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textOpacity.value,
                                child: Column(
                                  children: [
                                    ShaderMask(
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
                                      child: const Text(
                                        'MOTIVATOR',
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w200,
                                          color: Colors.white,
                                          letterSpacing: 4,
                                          height: 1.0,
                                          shadows: [
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
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Academic-style separator line
                                    Container(
                                      width: 120,
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
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Refined AI badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFD4AF37).withOpacity(0.05),
                                            Colors.transparent,
                                            const Color(0xFFD4AF37).withOpacity(0.05),
                                          ],
                                        ),
                                      ),
                                      child: const Text(
                                        'A.I',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFFD4AF37),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 25),

                  // Elegant subtitle
                  AnimatedBuilder(
                    animation: _subtitleOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _subtitleOpacity.value,
                        child: const Text(
                          'I N T E L L I G E N T   M O T I V A T I O N   S Y S T E M',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8B9DC3), // Soft blue-gray
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 90),

                  // Elegant progress indicator
                  AnimatedBuilder(
                    animation: Listenable.merge([_progressOpacity, _progressValue]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _progressOpacity.value,
                        child: Column(
                          children: [
                            Container(
                              width: 240,
                              height: 1,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B9DC3).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(0.5),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 240 * _progressValue.value,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFD4AF37),
                                          Color(0xFFFFD700),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'INITIALIZING SYSTEM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF8B9DC3).withOpacity(0.7),
                                letterSpacing: 2,
                              ),
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
}

// Sophisticated geometric pattern painter
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

// Geometric ring painter for the logo
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
    final radius = 50.0;

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

// Refined particle painter
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