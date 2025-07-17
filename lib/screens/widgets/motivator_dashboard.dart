// lib/screens/widgets/motivator_dashboard.dart - COMPLETE WITH RESTORED DEBUG BUTTONS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../services/amber_alert_service.dart';
import '../amber_alert_screen.dart';
import 'voice_chat_modal.dart';
import '../widgets/voice_chat_modal.dart';


class MotivatorDashboard extends StatefulWidget {
  final String userName;
  final TextEditingController controller;
  final String? currentTaskType;
  final Map<String, dynamic>? currentTaskConfig;
  final bool loading;
  final VoidCallback onGenerateMotivation;
  final String generatedLine;
  final Animation<double> motivationScale;
  final Animation<double> streakBounce;
  final AnimationController streakController;
  final int totalMotivations;
  final int motivationStreak;
  final List<String> recentMotivations;
  final List<String> quickActions;
  final String dailyQuote;
  final Function(String) onSelectQuickAction;
  final Function(String) onGenerateMotivationForTask;

  const MotivatorDashboard({
    Key? key,
    required this.userName,
    required this.controller,
    this.currentTaskType,
    this.currentTaskConfig,
    required this.loading,
    required this.onGenerateMotivation,
    required this.generatedLine,
    required this.motivationScale,
    required this.streakBounce,
    required this.streakController,
    required this.totalMotivations,
    required this.motivationStreak,
    required this.recentMotivations,
    required this.quickActions,
    required this.dailyQuote,
    required this.onSelectQuickAction,
    required this.onGenerateMotivationForTask,
  }) : super(key: key);

  @override
  _MotivatorDashboardState createState() => _MotivatorDashboardState();
}

class _MotivatorDashboardState extends State<MotivatorDashboard>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 🎨 Keep existing color scheme
  static const Color cardBackground = Color(0xFF1a1a2e);
  static const Color textPrimary = Color(0xFFffffff);
  static const Color textSecondary = Color(0xFFa0a0a0);
  static const Color accentTeal = Color(0xFF00d2ff);
  static const Color accentOrange = Color(0xFFFF6B47);

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
              
              // 🎭 NEW: AI Conversation Card (replaces Get Motivated)
              _AIConversationCard(
                context: context,
                controller: widget.controller,
                currentTaskType: widget.currentTaskType,
                currentTaskConfig: widget.currentTaskConfig,
                loading: widget.loading,
                onStartConversation: widget.onGenerateMotivation,
                generatedLine: widget.generatedLine,
                motivationScale: widget.motivationScale,
              ),
              
              const SizedBox(height: 24),
              
              // 💭 Daily Quote
              _BlurredDailyQuote(quote: widget.dailyQuote),
              
              const SizedBox(height: 24),
              
              // 🎯 Quick Actions Grid
              _QuickActionsGrid(
                quickActions: widget.quickActions,
                onSelectQuickAction: widget.onSelectQuickAction,
                currentTaskConfig: widget.currentTaskConfig,
              ),
              
              const SizedBox(height: 24),
              
              // ⚡ Recent Motivations
              _ElectrifyingRecentMotivations(
                recentMotivations: widget.recentMotivations,
                currentTaskConfig: widget.currentTaskConfig,
                onGenerateMotivationForTask: widget.onGenerateMotivationForTask,
              ),
              
              const SizedBox(height: 24),
              
              // 🔧 Debug Buttons (RESTORED ORIGINAL FUNCTIONALITY)
              _buildDebugButtons(context),
              
              const SizedBox(height: 100), // Extra padding for scroll
            ],
          ),
        ),
      ),
    );
  }

  // 🔧 RESTORED: Original Debug Buttons with Amber Alert Functionality
  Widget _buildDebugButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 Amber Alert Debug Controls',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Row 1: Basic notification tests
          Row(
            children: [
              Expanded(
                child: _DebugButton(
                  label: '🔔 BASIC',
                  color: Colors.blue,
                  onPressed: () => AmberAlertService.testNotificationWithoutPayload(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DebugButton(
                  label: '📱 JSON',
                  color: Colors.green,
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
          
          // Row 2: Advanced amber alert tests
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
          
          // Row 3: Permissions and system tests
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
                  label: '⚙️ Settings',
                  color: Colors.orange,
                  onPressed: () => AmberAlertService.openDeviceSettings(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DebugButton(
                  label: '🚨 ULTIMATE',
                  color: Colors.teal,
                  onPressed: () => AmberAlertService.testTrueFullScreenAmberAlert(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DebugButton(
                  label: '🔥 ALL',
                  color: Colors.deepPurple,
                  onPressed: () => AmberAlertService.testAllAmberStrategies(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 👋 Sleek Welcome Header (PRESERVED)
class _SleekWelcomeHeader extends StatelessWidget {
  final String userName;

  const _SleekWelcomeHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Hey ${userName.isEmpty ? 'there' : userName}',
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
    );
  }
}

// 🎭 AI Conversation Card (NEW - replaces Get Motivated)
class _AIConversationCard extends StatelessWidget {
  final BuildContext context;
  final TextEditingController controller;
  final String? currentTaskType;
  final Map<String, dynamic>? currentTaskConfig;
  final bool loading;
  final VoidCallback onStartConversation;
  final String generatedLine;
  final Animation<double> motivationScale;

  const _AIConversationCard({
    required this.context,
    required this.controller,
    this.currentTaskType,
    this.currentTaskConfig,
    required this.loading,
    required this.onStartConversation,
    required this.generatedLine,
    required this.motivationScale,
  });

  String _getHintForTaskType() {
    switch (currentTaskType) {
      case 'Study':
        return 'Tell me about your study goals...';
      case 'Exercise':
        return 'What workout are you planning?';
      case 'Work':
        return 'What work challenge can I help with?';
      case 'Eat':
        return 'Need help with healthy eating?';
      case 'Sleep':
        return 'Want to talk about sleep habits?';
      default:
        return 'What\'s on your mind today?';
    }
  }

  String _getAIPersonalityName() {
    // Get from user preferences - for now default to Lana Croft
    return 'Lana Croft';
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
                    Icons.chat_bubble_outline,
                    color: currentTaskConfig?['color'] ?? 
                           _MotivatorDashboardState.accentTeal,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Talk to ${_getAIPersonalityName()}',
                          style: TextStyle(
                            color: _MotivatorDashboardState.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Start a live conversation with your AI coach',
                          style: TextStyle(
                            color: _MotivatorDashboardState.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Input Field
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
                      hintText: _getHintForTaskType(),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Conversation Buttons
              Row(
                children: [
                  // Voice Input Button
                  Expanded(
                    child: Container(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _startVoiceConversation,
                        icon: Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          'Voice Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.8),
                          elevation: 6,
                          shadowColor: Colors.red.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Text Chat Button
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: motivationScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: motivationScale.value,
                          child: Container(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: loading ? null : onStartConversation,
                              icon: loading 
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : Icon(Icons.chat, color: Colors.black, size: 20),
                              label: Text(
                                loading 
                                    ? 'Connecting...'
                                    : 'Talk to Lana',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentTaskConfig?['color'] ?? 
                                               _MotivatorDashboardState.accentTeal,
                                elevation: 8,
                                shadowColor: (currentTaskConfig?['color'] ?? 
                                             _MotivatorDashboardState.accentTeal).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              // Generated line display (if any)
              if (generatedLine.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (currentTaskConfig?['color'] ?? _MotivatorDashboardState.accentTeal).withOpacity(0.2),
                        (currentTaskConfig?['color'] ?? _MotivatorDashboardState.accentTeal).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (currentTaskConfig?['color'] ?? _MotivatorDashboardState.accentTeal).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    generatedLine,
                    style: TextStyle(
                      color: _MotivatorDashboardState.textPrimary,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startVoiceConversation() {
    HapticFeedback.lightImpact();
    
    // Show full-screen voice chat modal
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Voice Chat',
      barrierColor: Colors.black87,
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return VoiceChatModal(
          aiPersonalityName: _getAIPersonalityName(),
          userName: 'Bob', // Get from your user settings
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }
}

// 💭 Daily Quote (PRESERVED)
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

// 🎯 Quick Actions Grid (PRESERVED)
class _QuickActionsGrid extends StatelessWidget {
  final List<String> quickActions;
  final Function(String) onSelectQuickAction;
  final Map<String, dynamic>? currentTaskConfig;

  const _QuickActionsGrid({
    required this.quickActions,
    required this.onSelectQuickAction,
    this.currentTaskConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎯 Quick Actions',
          style: TextStyle(
            color: _MotivatorDashboardState.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            final colors = _getColorsForAction(action);
            
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 100)),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Transform.rotate(
                    angle: (1 - value) * 0.1,
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
      ],
    );
  }

  List<Color> _getColorsForAction(String action) {
    if (action.toLowerCase().contains('study')) {
      return [Colors.blue, Colors.indigo];
    } else if (action.toLowerCase().contains('exercise')) {
      return [Colors.orange, Colors.red];
    } else if (action.toLowerCase().contains('work')) {
      return [Colors.green, Colors.teal];
    }
    return [_MotivatorDashboardState.accentTeal, Colors.blue];
  }

  IconData _getIconForAction(String action) {
    if (action.toLowerCase().contains('study')) return Icons.school;
    if (action.toLowerCase().contains('exercise')) return Icons.fitness_center;
    if (action.toLowerCase().contains('work')) return Icons.work;
    if (action.toLowerCase().contains('eat')) return Icons.restaurant;
    return Icons.star;
  }
}

// ⚡ Recent Motivations (PRESERVED)
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
          '⚡ Recent Motivations',
          style: TextStyle(
            color: _MotivatorDashboardState.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentMotivations.length,
          itemBuilder: (context, index) {
            final motivation = recentMotivations[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _MotivatorDashboardState.cardBackground.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote,
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
              ),
            );
          },
        ),
      ],
    );
  }
}

// 🔧 Debug Button (PRESERVED)
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