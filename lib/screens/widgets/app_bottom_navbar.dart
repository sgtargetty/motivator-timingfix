// lib/screens/widgets/app_bottom_navbar.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../motivator_home.dart';
import '../dictaphone_screen.dart';
import '../settings_screen.dart';

enum AppScreen { dashboard, calendar, dictaphone, settings }

class AppBottomNavBar extends StatelessWidget {
  final AppScreen currentScreen;
  final Function(AppScreen)? onScreenChanged;

  const AppBottomNavBar({
    Key? key,
    required this.currentScreen,
    this.onScreenChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            screen: AppScreen.dashboard,
            context: context,
          ),
          _buildNavButton(
            icon: Icons.calendar_today_rounded,
            label: 'Calendar',
            screen: AppScreen.calendar,
            context: context,
          ),
          _buildNavButton(
            icon: Icons.mic_rounded,
            label: 'Dictaphone',
            screen: AppScreen.dictaphone,
            context: context,
          ),
          _buildNavButton(
            icon: Icons.settings_rounded,
            label: 'Settings',
            screen: AppScreen.settings,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required AppScreen screen,
    required BuildContext context,
  }) {
    final isActive = currentScreen == screen;
    
    return GestureDetector(
      onTap: () => _handleNavigation(screen, context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFD4AF37).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFFD4AF37)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFF8B9DC3),
              size: 18,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFF8B9DC3),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w300,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(AppScreen targetScreen, BuildContext context) {
    HapticFeedback.selectionClick();

    if (currentScreen == targetScreen) return;

    // 🔧 THE FIX: Use callback for dashboard/calendar navigation
    if (onScreenChanged != null && 
        (targetScreen == AppScreen.dashboard || targetScreen == AppScreen.calendar)) {
      print('🎯 Using callback navigation to ${targetScreen.toString()}');
      onScreenChanged!(targetScreen);
      return;
    }

    // 🚀 For external screens (dictaphone, settings), use Navigator
    switch (targetScreen) {
      case AppScreen.dictaphone:
        Navigator.of(context).push(
          _createSmoothRoute(const DictaphoneScreen()),
        ).then((result) {
          // 🔄 If task was created successfully, refresh calendar
          if (result == true && onScreenChanged != null) {
            print('🔄 Dictaphone returned success - refreshing tasks');
            // Switch to calendar to show the new task
            onScreenChanged!(AppScreen.calendar);
          }
        });
        break;

      case AppScreen.settings:
        Navigator.of(context).push(
          _createSmoothRoute(
            SettingsScreen(
              currentTaskType: null,
              currentTaskConfig: null,
              currentVoice: null,
              currentToneStyle: null,
              onSettingsChanged: (taskType, config, voice, tone) {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
        break;

      case AppScreen.dashboard:
      case AppScreen.calendar:
        // 🚨 FALLBACK: If no callback, navigate to new MotivatorHome with initial view
        Navigator.of(context).pushAndRemoveUntil(
          _createSmoothRoute(
            MotivatorHome(
              // 🎯 Pass initial view to show correct screen
              initialView: targetScreen == AppScreen.dashboard 
                  ? ViewMode.dashboard 
                  : ViewMode.calendar,
            ),
          ),
          (route) => false,
        );
        break;
    }
  }

  // 🎨 SMOOTH TRANSITION - No white flash
  PageRouteBuilder _createSmoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: Container(
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
            child: child,
          ),
        );
      },
    );
  }
}