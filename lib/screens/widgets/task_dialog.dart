import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/task_scheduler.dart';
import '../../services/amber_alert_service.dart';
import '../amber_alert_screen.dart';

// 🚨 NUCLEAR OPTION: Global overlay that ALWAYS works
class NuclearLoadingOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, {required bool isAmberAlert}) {
    hide(); // Remove any existing overlay
    
    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isAmberAlert ? Colors.red.shade900 : const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isAmberAlert ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spinning indicator
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAmberAlert ? '🚨 CREATING CRITICAL ALERT' : '⏱️ CREATING REMINDER',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isAmberAlert 
                      ? 'Generating emergency-level\nmotivational content...'
                      : 'Generating personalized\nmotivational content...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    '⚠️ Please wait - this may take 5-10 seconds',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Insert the overlay
    Overlay.of(context).insert(_currentOverlay!);
    print('🚨 NUCLEAR OVERLAY: Shown successfully!');
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    print('🚨 NUCLEAR OVERLAY: Hidden successfully!');
  }
}

class UltraResponsiveTaskDialog extends StatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime, Map<String, dynamic>) onTaskAdded;
  final String? currentTaskType;

  const UltraResponsiveTaskDialog({
    Key? key,
    required this.selectedDay,
    required this.onTaskAdded,
    this.currentTaskType,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    DateTime selectedDay,
    Function(DateTime, Map<String, dynamic>) onTaskAdded, {
    String? currentTaskType,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return UltraResponsiveTaskDialog(
          selectedDay: selectedDay,
          onTaskAdded: onTaskAdded,
          currentTaskType: currentTaskType,
        );
      },
    );
  }

  @override
  State<UltraResponsiveTaskDialog> createState() => _UltraResponsiveTaskDialogState();
}

class _UltraResponsiveTaskDialogState extends State<UltraResponsiveTaskDialog> {
  final TextEditingController _taskController = TextEditingController();
  
  // Core settings
  String _selectedVoiceCategory = 'male';
  String _selectedVoiceStyle = 'Default Male'; 
  String _selectedToneStyle = 'Cheerleader';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isAmberAlert = false;
  
  // Simple loading state
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.selectedDay.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  // 🚨 NUCLEAR VERSION - ONLY ONE _createTask METHOD!
  Future<void> _createTask() async {
    final task = _taskController.text.trim();
    if (task.isEmpty || _isCreating) return;

    print('🚨 NUCLEAR: Starting task creation...');
    
    // 🚨 NUCLEAR OPTION: Show overlay IMMEDIATELY
    NuclearLoadingOverlay.show(context, isAmberAlert: _isAmberAlert);
    
    // Immediate haptic feedback
    HapticFeedback.heavyImpact();
    
    setState(() {
      _isCreating = true;
    });

    try {
      print('🚨 NUCLEAR: Building enhanced task...');
      
      final enhancedTask = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isCompleted': false,
        'completedAt': null,
        'isArchived': false,
        'archivedAt': null,
        'description': task,
        'dateTime': _selectedDateTime,
        'voiceCategory': _selectedVoiceCategory,
        'voiceStyle': _selectedVoiceStyle,
        'toneStyle': _selectedToneStyle,
        'backendVoiceStyle': '$_selectedVoiceCategory:$_selectedVoiceStyle',
        'backendToneStyle': _selectedToneStyle,
        'forceOverrideSilent': _isAmberAlert,
        'enableVibration': true,
        'notificationPriority': _isAmberAlert ? 'Max' : 'High',
        'isAmberAlert': _isAmberAlert,
        'isRecurring': false,
      };

      print('🚨 NUCLEAR: Starting API work...');
      
      // Handle amber alert vs regular task
      if (_isAmberAlert) {
        await _createAmberAlertTask(enhancedTask, task);
      } else {
        await TaskScheduler.instance.scheduleNotification(
          enhancedTask, 
          context,
          currentTaskType: widget.currentTaskType,
        );
      }

      print('🚨 NUCLEAR: API work completed!');

      // Add task and navigate
      widget.onTaskAdded(widget.selectedDay, enhancedTask);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        HapticFeedback.heavyImpact();
        
        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAmberAlert ? '🚨 Critical Alert Created!' : '✅ Reminder Scheduled!'),
            backgroundColor: _isAmberAlert ? Colors.green : const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

    } catch (e) {
      print('❌ NUCLEAR: Error occurred: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      print('🚨 NUCLEAR: Cleaning up...');
      
      // Hide the nuclear overlay
      NuclearLoadingOverlay.hide();
      
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  // Simplified amber alert creation
  Future<void> _createAmberAlertTask(Map<String, dynamic> taskData, String taskDescription) async {
    await TaskScheduler.instance.scheduleNotification(
      taskData, 
      context,
      currentTaskType: widget.currentTaskType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0a1428),
              const Color(0xFF16213e),
              const Color(0xFF000000),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isAmberAlert ? Colors.red : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _isAmberAlert ? Icons.warning : Icons.add_task,
                color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isAmberAlert ? '🚨 Create Critical Alert' : 'Create Reminder',
                  style: TextStyle(
                    color: _isAmberAlert ? Colors.red : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Task input
          TextField(
            controller: _taskController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'What do you need motivation for?',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                ),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),
          
          // Amber Alert Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAmberAlert ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isAmberAlert ? Colors.red : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: _isAmberAlert ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚨 Emergency Alert Mode',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Bypasses silent mode with emergency-level priority',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAmberAlert,
                  onChanged: (value) {
                    setState(() {
                      _isAmberAlert = value;
                    });
                    HapticFeedback.selectionClick();
                  },
                  activeColor: Colors.red,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isAmberAlert ? '🚨 Create Alert' : '✅ Create Reminder',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}