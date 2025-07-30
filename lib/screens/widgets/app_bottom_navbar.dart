// lib/screens/widgets/app_bottom_navbar.dart - UPDATED with Memory Tab
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../motivator_home.dart';
import '../dictaphone_screen.dart';
import '../settings_screen.dart';
import '../memory_management_screen.dart';

enum AppScreen { dashboard, calendar, dictaphone, memory, settings }

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
            icon: Icons.memory_rounded,
            label: 'Memory',
            screen: AppScreen.memory,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFF8B9DC3),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(AppScreen screen, BuildContext context) {
    if (screen == currentScreen) return; // Don't navigate to current screen
    
    // Add haptic feedback
    HapticFeedback.selectionClick();
    
    // Handle navigation based on screen
    switch (screen) {
      case AppScreen.dashboard:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MotivatorHome(initialView: ViewMode.dashboard),
          ),
          (route) => false,
        );
        break;
        
      case AppScreen.calendar:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MotivatorHome(initialView: ViewMode.calendar),
          ),
          (route) => false,
        );
        break;
        
      case AppScreen.dictaphone:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MotivatorHome(initialView: ViewMode.dictaphone),
          ),
          (route) => false,
        );
        break;
        
      case AppScreen.memory:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MemoryManagementScreen(),
          ),
          (route) => false,
        );
        break;
        
      case AppScreen.settings:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              currentTaskType: null,
              currentTaskConfig: null,
              onSettingsChanged: (taskType, config, voice, tone) {
                // Handle settings changes if needed
              },
            ),
          ),
          (route) => false,
        );
        break;
    }
    
    // Call callback if provided
    if (onScreenChanged != null) {
      onScreenChanged!(screen);
    }
  }
}