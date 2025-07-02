import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../services/amber_alert_service.dart';
import '../amber_alert_screen.dart';

class MotivatorDashboard extends StatefulWidget {
  // State passed from parent
  final String userName;
  final int motivationStreak;
  final int totalMotivations;
  final List<String> recentMotivations;
  final List<String> quickActions;
  final String dailyQuote;
  final String generatedLine;
  final bool loading;
  final String? currentTaskType;
  final Map<String, dynamic>? currentTaskConfig;
  
  // Controllers and animations from parent
  final TextEditingController controller;
  final Animation<double> motivationScale;
  final Animation<double> streakBounce;
  final AnimationController streakController;
  
  // Callback functions
  final VoidCallback onGenerateMotivation;
  final Function(String) onSelectQuickAction;
  final Function(String) onGenerateMotivationForTask;
  
  const MotivatorDashboard({
    Key? key,
    required this.userName,
    required this.motivationStreak,
    required this.totalMotivations,
    required this.recentMotivations,
    required this.quickActions,
    required this.dailyQuote,
    required this.generatedLine,
    required this.loading,
    this.currentTaskType,
    this.currentTaskConfig,
    required this.controller,
    required this.motivationScale,
    required this.streakBounce,
    required this.streakController,
    required this.onGenerateMotivation,
    required this.onSelectQuickAction,
    required this.onGenerateMotivationForTask,
  }) : super(key: key);

  @override
  State<MotivatorDashboard> createState() => _MotivatorDashboardState();
}

class _MotivatorDashboardState extends State<MotivatorDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Modern color palette
  static const Color primaryBackground = Color(0xFF0F1419);
  static const Color cardBackground = Color(0xFF1A1F2E);
  static const Color accentTeal = Color(0xFF00D4AA);
  static const Color accentOrange = Color(0xFFFF6B47);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C8);
  static const Color glassOverlay = Color(0x1AFFFFFF);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SleekWelcomeHeader(userName: widget.userName),
              const SizedBox(height: 24),
              // 🔥 STREAK CARD - Debug to make sure it shows
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF4500),
                      Color(0xFFFF6B35),
                      Color(0xFFFF8E53),
                      Color(0xFFFFD700),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🔥 ${widget.motivationStreak} 🔥',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'DAY STREAK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "🔥 DON'T BREAK THE CHAIN! 🔥",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _GlassmorphicWeeklyStats(totalMotivations: widget.totalMotivations),
              const SizedBox(height: 24),
              _BlurredDailyQuote(quote: widget.dailyQuote),
              const SizedBox(height: 24),
              _PremiumMotivationCard(
                context: context,
                controller: widget.controller,
                currentTaskType: widget.currentTaskType,
                currentTaskConfig: widget.currentTaskConfig,
                loading: widget.loading,
                onGenerateMotivation: widget.onGenerateMotivation,
                generatedLine: widget.generatedLine,
                motivationScale: widget.motivationScale,
              ),
              const SizedBox(height: 28),
              _SmoothQuickActions(
                quickActions: widget.quickActions,
                currentTaskType: widget.currentTaskType,
                currentTaskConfig: widget.currentTaskConfig,
                onSelectQuickAction: widget.onSelectQuickAction,
              ),
              const SizedBox(height: 28),
              _ElectrifyingRecentMotivations(
                recentMotivations: widget.recentMotivations,
                currentTaskConfig: widget.currentTaskConfig,
                onGenerateMotivationForTask: widget.onGenerateMotivationForTask,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 Modern Welcome Header Component
class _SleekWelcomeHeader extends StatelessWidget {
  final String userName;
  
  const _SleekWelcomeHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          Text(
            'Hello, ',
            style: TextStyle(
              color: _MotivatorDashboardState.textSecondary,
              fontSize: 22,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            '$userName!',
            style: TextStyle(
              color: _MotivatorDashboardState.accentTeal,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const Text(
                  '👋',
                  style: TextStyle(fontSize: 22),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 🔥 Ultra-Modern Streak Card
class _ModernStreakCard extends StatelessWidget {
  final int motivationStreak;
  final AnimationController streakController;
  final Animation<double> streakBounce;

  const _ModernStreakCard({
    required this.motivationStreak,
    required this.streakController,
    required this.streakBounce,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: streakController,
      builder: (context, child) {
        return Transform.scale(
          scale: streakBounce.value,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B47),
                  Color(0xFFFF8E53),
                  Color(0xFFFFB347),
                  Color(0xFFFFD700),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _MotivatorDashboardState.accentOrange.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Glowing particles effect
                      ...List.generate(6, (index) {
                        return Positioned(
                          top: 20 + (index * 25.0),
                          right: 20 + (index * 15.0),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 800 + (index * 200)),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: (0.3 + (value * 0.4)) * 
                                    (0.5 + 0.5 * (index % 2)),
                                child: Container(
                                  width: 4 + (index * 2),
                                  height: 4 + (index * 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      // Main content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                const SizedBox(width: 16),
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: motivationStreak),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Text(
                                      '$value',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 64,
                                        fontWeight: FontWeight.w900,
                                        height: 0.9,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(2, 2),
                                            blurRadius: 6,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'DAY STREAK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                "🔥 DON'T BREAK THE CHAIN! 🔥",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
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

// 📊 Glassmorphic Weekly Stats
class _GlassmorphicWeeklyStats extends StatelessWidget {
  final int totalMotivations;

  const _GlassmorphicWeeklyStats({required this.totalMotivations});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _MotivatorDashboardState.glassOverlay,
                _MotivatorDashboardState.cardBackground.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _MotivatorDashboardState.accentTeal.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: _MotivatorDashboardState.accentTeal,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: totalMotivations),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          '$value',
                          style: TextStyle(
                            color: _MotivatorDashboardState.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                    Text(
                      'This Week',
                      style: TextStyle(
                        color: _MotivatorDashboardState.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Keep it up! 📈',
                style: TextStyle(
                  color: _MotivatorDashboardState.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 💭 Blurred Daily Quote Card
class _BlurredDailyQuote extends StatelessWidget {
  final String quote;

  const _BlurredDailyQuote({required this.quote});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _MotivatorDashboardState.cardBackground.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: Colors.purpleAccent.withOpacity(0.8),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Daily Inspiration',
                    style: TextStyle(
                      color: _MotivatorDashboardState.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                quote,
                style: TextStyle(
                  color: _MotivatorDashboardState.textSecondary,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🚀 Premium Motivation Card
class _PremiumMotivationCard extends StatelessWidget {
  final BuildContext context;
  final TextEditingController controller;
  final String? currentTaskType;
  final Map<String, dynamic>? currentTaskConfig;
  final bool loading;
  final VoidCallback onGenerateMotivation;
  final String generatedLine;
  final Animation<double> motivationScale;

  const _PremiumMotivationCard({
    required this.context,
    required this.controller,
    this.currentTaskType,
    this.currentTaskConfig,
    required this.loading,
    required this.onGenerateMotivation,
    required this.generatedLine,
    required this.motivationScale,
  });

  String _getHintForTaskType() {
    switch (currentTaskType) {
      case 'Study':
        return 'Review chapter 5, practice math problems...';
      case 'Exercise':
        return 'Complete 30-min cardio, lift weights...';
      case 'Work':
        return 'Finish project proposal, prepare presentation...';
      case 'Eat':
        return 'Prep healthy lunch, drink more water...';
      case 'Sleep':
        return 'Get to bed by 10pm, wind down routine...';
      default:
        return 'Finish my presentation, workout, call mom...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: currentTaskConfig != null
                  ? (currentTaskConfig!['gradient'] as List<Color>)
                      .map<Color>((color) => color.withOpacity(0.15))
                      .toList()
                  : [
                      _MotivatorDashboardState.accentTeal.withOpacity(0.15),
                      _MotivatorDashboardState.accentTeal.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (currentTaskConfig?['color'] ?? 
                     _MotivatorDashboardState.accentTeal).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    currentTaskConfig?['icon'] ?? Icons.psychology_rounded,
                    color: currentTaskConfig?['color'] ?? 
                           _MotivatorDashboardState.accentTeal,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      currentTaskType != null 
                          ? 'What ${currentTaskType?.toLowerCase()} goal needs your energy?'
                          : 'What needs your energy today?',
                      style: TextStyle(
                        color: _MotivatorDashboardState.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Enhanced TextField
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextField(
                    controller: controller,
                    style: TextStyle(
                      color: _MotivatorDashboardState.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: currentTaskType != null
                          ? 'e.g., ${_getHintForTaskType()}'
                          : 'e.g., Finish my presentation, workout, call mom...',
                      hintStyle: TextStyle(
                        color: _MotivatorDashboardState.textSecondary,
                        fontSize: 15,
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
                          color: currentTaskConfig?['color'] ?? 
                                 _MotivatorDashboardState.accentTeal,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Enhanced Generate Button
              AnimatedBuilder(
                animation: motivationScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: motivationScale.value,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: loading ? null : onGenerateMotivation,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: loading ? null : LinearGradient(
                              colors: [
                                currentTaskConfig?['color'] ?? 
                                _MotivatorDashboardState.accentTeal,
                                (currentTaskConfig?['color'] ?? 
                                _MotivatorDashboardState.accentTeal)
                                .withOpacity(0.8),
                              ],
                            ),
                            color: loading ? Colors.grey[600] : null,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: loading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'Summoning Motivation...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.rocket_launch_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Get Motivated! 🚀',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
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
              ),
              
              // Debug buttons (maintaining your existing functionality)
              const SizedBox(height: 16),
              _buildDebugButtons(context),
              
              // Generated line display
              if (generatedLine.isNotEmpty)
                AnimatedBuilder(
                  animation: motivationScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: motivationScale.value,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.only(top: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: currentTaskConfig != null 
                                ? (currentTaskConfig!['gradient'] as List<Color>)
                                : [
                                    _MotivatorDashboardState.accentTeal,
                                    _MotivatorDashboardState.accentTeal.withOpacity(0.8),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (currentTaskConfig?['color'] ?? 
                                     _MotivatorDashboardState.accentTeal)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          '"$generatedLine"',
                          style: const TextStyle(
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugButtons(BuildContext context) {
    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _DebugButton(
                label: '🧪 Basic',
                color: Colors.blue,
                onPressed: () => AmberAlertService.testNotificationWithoutPayload(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '🧪 Enhanced',
                color: Colors.green,
                onPressed: () => AmberAlertService.testNotificationWithSimplePayload(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '🧪 Full',
                color: Colors.orange,
                onPressed: () => AmberAlertService.testNotificationWithJsonPayload(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '🚨 AUTO',
                color: Colors.red,
                onPressed: () => AmberAlertService.testAmberAlertNotification(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Additional rows (maintaining your existing debug functionality)
        Row(
          children: [
            Expanded(
              child: _DebugButton(
                label: '🚨 NOW',
                color: Colors.red.shade800,
                onPressed: () => AmberAlertService.testImmediateAutoHijackAlert(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '⚠️ Native',
                color: Colors.red.shade700,
                onPressed: () => AmberAlertService.testNativeAlarmAlert(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '🔴 Continuous',
                color: Colors.red.shade900,
                onPressed: () => AmberAlertService.testContinuousAlarm(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '📋 Check',
                color: Colors.purple,
                onPressed: () => AmberAlertService.checkScheduledNotifications(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DebugButton(
                label: '🔐 Perms',
                color: Colors.indigo,
                onPressed: () => AmberAlertService.checkAllPermissions(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '🔋 Battery',
                color: Colors.teal,
                onPressed: () => AmberAlertService.checkBatteryOptimization(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '⚙️ Settings',
                color: Colors.grey,
                onPressed: () => AmberAlertService.openDeviceSettings(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DebugButton(
                label: '🚨 ULTIMATE',
                color: Colors.red.shade800,
                onPressed: () => AmberAlertService.testTrueFullScreenAmberAlert(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '🔴 ALL',
                color: Colors.red.shade900,
                onPressed: () => AmberAlertService.testAllAmberStrategies(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DebugButton(
                label: '🎭 DEMO',
                color: Colors.purple.shade700,
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => 
                          const AmberAlertScreen(
                        title: '🚨 TEST EMERGENCY ALERT 🚨',
                        message: 'This is a test of the full-screen amber alert takeover!',
                        taskDescription: 'Test your motivation system',
                      ),
                      opaque: false,
                      fullscreenDialog: true,
                      transitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                              CurvedAnimation(parent: animation, curve: Curves.easeOut),
                            ),
                            child: child,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 🎯 Smooth Quick Actions Grid
class _SmoothQuickActions extends StatelessWidget {
  final List<String> quickActions;
  final String? currentTaskType;
  final Map<String, dynamic>? currentTaskConfig;
  final Function(String) onSelectQuickAction;

  const _SmoothQuickActions({
    required this.quickActions,
    this.currentTaskType,
    this.currentTaskConfig,
    required this.onSelectQuickAction,
  });

  IconData _getIconForAction(String action) {
    final iconMap = {
      "Focus Session": Icons.psychology_rounded,
      "Reading Time": Icons.menu_book_rounded,
      "Note Review": Icons.note_alt_rounded,
      "Quiz Prep": Icons.quiz_rounded,
      "Research Deep Dive": Icons.search_rounded,
      "Memory Practice": Icons.memory_rounded,
      "Pre-Workout": Icons.play_arrow_rounded,
      "Cardio Boost": Icons.favorite_rounded,
      "Strength Push": Icons.fitness_center_rounded,
      "Cool Down": Icons.self_improvement_rounded,
      "Yoga Flow": Icons.spa_rounded,
      "Recovery": Icons.hotel_rounded,
      "Project Focus": Icons.work_rounded,
      "Meeting Prep": Icons.groups_rounded,
      "Email Clear": Icons.email_rounded,
      "Creative Think": Icons.lightbulb_rounded,
      "Problem Solve": Icons.extension_rounded,
      "Team Sync": Icons.people_rounded,
      "Meal Prep": Icons.restaurant_rounded,
      "Healthy Choice": Icons.eco_rounded,
      "Portion Control": Icons.straighten_rounded,
      "Mindful Eating": Icons.self_improvement_rounded,
      "Hydration": Icons.local_drink_rounded,
      "Nutrition Plan": Icons.assignment_rounded,
      "Wind Down": Icons.bedtime_rounded,
      "Relaxation": Icons.spa_rounded,
      "Sleep Prep": Icons.night_shelter_rounded,
      "Dream Well": Icons.cloud_rounded,
      "Recovery Rest": Icons.hotel_rounded,
      "Morning Rise": Icons.wb_sunny_rounded,
      "Morning Motivation": Icons.wb_sunny_rounded,
      "Workout Boost": Icons.fitness_center_rounded,
      "Work Focus": Icons.work_rounded,
      "Evening Reflection": Icons.nightlight_rounded,
      "Study Session": Icons.school_rounded,
      "Creative Flow": Icons.palette_rounded,
    };
    
    return iconMap[action] ?? Icons.star_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentTaskType != null 
              ? '⚡ Quick ${currentTaskType} Actions'
              : '⚡ Quick Motivation',
          style: TextStyle(
            color: _MotivatorDashboardState.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              final colors = currentTaskConfig?['gradient'] ?? [
                Colors.primaries[index % Colors.primaries.length],
                Colors.primaries[index % Colors.primaries.length].withOpacity(0.7),
              ];
              
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 160,
                      margin: EdgeInsets.only(
                        right: 16,
                        left: index == 0 ? 0 : 0,
                      ),
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onSelectQuickAction(action);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colors.cast<Color>(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getIconForAction(action),
                                  color: Colors.white,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  action,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
            },
          ),
        ),
      ],
    );
  }
}

// ⚡ Electrifying Recent Motivations
class _ElectrifyingRecentMotivations extends StatelessWidget {
  final List<String> recentMotivations;
  final Map<String, dynamic>? currentTaskConfig;
  final Function(String) onGenerateMotivationForTask;

  const _ElectrifyingRecentMotivations({
    required this.recentMotivations,
    this.currentTaskConfig,
    required this.onGenerateMotivationForTask,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📜 Recent Motivations',
          style: TextStyle(
            color: _MotivatorDashboardState.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(recentMotivations.length, (index) {
          final motivation = recentMotivations[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (index * 150)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _MotivatorDashboardState.cardBackground.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: currentTaskConfig?['color'] ?? 
                                 _MotivatorDashboardState.accentTeal,
                          size: 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            motivation,
                            style: TextStyle(
                              color: _MotivatorDashboardState.textSecondary,
                              fontSize: 15,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => onGenerateMotivationForTask(motivation),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.replay_rounded,
                                color: currentTaskConfig?['color'] ?? 
                                       _MotivatorDashboardState.accentTeal,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// 🔧 Sleek Debug Button Component
class _DebugButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _DebugButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}