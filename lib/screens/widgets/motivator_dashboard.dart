import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/amber_alert_service.dart';
import '../amber_alert_screen.dart';  // ✅ ADD THIS LINE

class MotivatorDashboard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Hello, ',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Text(
                '$userName! 👋',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildDailyQuote(),
          const SizedBox(height: 20),
          _buildMainMotivationCard(context),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildRecentMotivations(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: streakController,
            builder: (context, child) {
              return Transform.scale(
                scale: streakBounce.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        '$motivationStreak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Day Streak',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  '$totalMotivations',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Total Boosts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_quote, color: Colors.purpleAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Daily Inspiration',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dailyQuote,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMotivationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: currentTaskConfig != null
              ? (currentTaskConfig!['gradient'] as List<Color>).map<Color>((color) => color.withOpacity(0.1)).toList()
              : [
                  Colors.tealAccent.withOpacity(0.1),
                  Colors.cyanAccent.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (currentTaskConfig?['color'] ?? Colors.tealAccent).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                currentTaskConfig?['icon'] ?? Icons.psychology,
                color: currentTaskConfig?['color'] ?? Colors.tealAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentTaskType != null 
                      ? 'What ${currentTaskType?.toLowerCase()} goal needs your energy?'
                      : 'What needs your energy today?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: currentTaskType != null
                  ? 'e.g., ${_getHintForTaskType()}'
                  : 'e.g., Finish my presentation, workout, call mom...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: currentTaskConfig?['color'] ?? Colors.tealAccent),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
          const SizedBox(height: 20),
          
          // 🧪 ENHANCED DEBUG BUTTONS FOR AMBER ALERTS
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: loading ? null : onGenerateMotivation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.all(
                      loading ? Colors.grey[600] : (currentTaskConfig?['color'] ?? Colors.tealAccent),
                    ),
                  ),
                  child: loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Summoning Motivation...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'Get Motivated! 🚀',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              // 🧪 ENHANCED DEBUG BUTTONS FOR TESTING AMBER ALERTS
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testNotificationWithoutPayload(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('🧪 Basic', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testNotificationWithSimplePayload(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('🧪 Enhanced', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testNotificationWithJsonPayload(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('🧪 Full', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testAmberAlertNotification(context), // 🚨 AUTO-HIJACK TEST
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('🚨 AUTO', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
              // 🆕 NEW: Additional amber alert test buttons
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testImmediateAutoHijackAlert(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                      child: const Text('🚨 NOW', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testNativeAlarmAlert(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                      child: const Text('⚠️ Native', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testContinuousAlarm(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                      child: const Text('🔴 Continuous', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.checkScheduledNotifications(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: const Text('📋 Check', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
              // 🔧 DIAGNOSTIC BUTTONS
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.checkAllPermissions(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: const Text('🔐 Perms', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.checkBatteryOptimization(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: const Text('🔋 Battery', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.openDeviceSettings(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text('⚙️ Settings', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                ],
              ),
              // 🚨 ULTIMATE AMBER ALERT TESTS
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testTrueFullScreenAmberAlert(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                      child: const Text('🚨 ULTIMATE', style: TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => AmberAlertService.testAllAmberStrategies(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                      child: const Text('🔴 ALL', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Note: This would need to be passed as a callback from parent
                        // For now, using AmberAlertService directly
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const AmberAlertScreen(
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700),
                      child: const Text('🎭 DEMO', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (generatedLine.isNotEmpty)
            AnimatedBuilder(
              animation: motivationScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: motivationScale.value,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTaskConfig != null ? (currentTaskConfig!['gradient'] as List<Color>) : [Colors.teal, Colors.tealAccent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (currentTaskConfig?['color'] ?? Colors.tealAccent).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      '"$generatedLine"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentTaskType != null 
              ? '⚡ Quick ${currentTaskType} Actions'
              : '⚡ Quick Motivation',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              final color = currentTaskConfig?['gradient']?[0] ?? Colors.primaries[index % Colors.primaries.length];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelectQuickAction(action);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentTaskConfig != null ? (currentTaskConfig!['gradient'] as List<Color>) : [
                          color.withOpacity(0.7),
                          color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconForAction(action),
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForAction(String action) {
    // Enhanced icon mapping for task-specific actions
    final iconMap = {
      // Study actions
      "Focus Session": Icons.psychology,
      "Reading Time": Icons.menu_book,
      "Note Review": Icons.note_alt,
      "Quiz Prep": Icons.quiz,
      "Research Deep Dive": Icons.search,
      "Memory Practice": Icons.memory,
      
      // Exercise actions
      "Pre-Workout": Icons.play_arrow,
      "Cardio Boost": Icons.favorite,
      "Strength Push": Icons.fitness_center,
      "Cool Down": Icons.self_improvement,
      "Yoga Flow": Icons.spa,
      "Recovery": Icons.hotel,
      
      // Work actions
      "Project Focus": Icons.work,
      "Meeting Prep": Icons.groups,
      "Email Clear": Icons.email,
      "Creative Think": Icons.lightbulb,
      "Problem Solve": Icons.extension,
      "Team Sync": Icons.people,
      
      // Eat actions
      "Meal Prep": Icons.restaurant,
      "Healthy Choice": Icons.eco,
      "Portion Control": Icons.straighten,
      "Mindful Eating": Icons.self_improvement,
      "Hydration": Icons.local_drink,
      "Nutrition Plan": Icons.assignment,
      
      // Sleep actions
      "Wind Down": Icons.bedtime,
      "Relaxation": Icons.spa,
      "Sleep Prep": Icons.night_shelter,
      "Dream Well": Icons.cloud,
      "Recovery Rest": Icons.hotel,
      "Morning Rise": Icons.wb_sunny,
      
      // Default actions
      "Morning Motivation": Icons.wb_sunny,
      "Workout Boost": Icons.fitness_center,
      "Work Focus": Icons.work,
      "Evening Reflection": Icons.nightlight,
      "Study Session": Icons.school,
      "Creative Flow": Icons.palette,
    };
    
    return iconMap[action] ?? Icons.star;
  }

  Widget _buildRecentMotivations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📜 Recent Motivations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(recentMotivations.length, (index) {
          final motivation = recentMotivations[index];
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: currentTaskConfig?['color'] ?? Colors.tealAccent,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    motivation,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.replay,
                    color: currentTaskConfig?['color'] ?? Colors.tealAccent,
                    size: 16,
                  ),
                  onPressed: () => onGenerateMotivationForTask(motivation),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}