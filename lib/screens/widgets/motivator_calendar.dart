import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../services/task_scheduler.dart';
import '../../services/task_storage.dart';
import 'task_dialog.dart';

enum TaskFilter { all, active, completed, archived }

class MotivatorCalendar extends StatefulWidget {
  // State passed from parent
  final DateTime selectedDay;
  final Map<DateTime, List<Map<String, dynamic>>> tasks;
  final String generatedLine;
  final bool loading;
  final String? currentTaskType;
  
  // Callback functions
  final Function(DateTime) onDaySelected;
  final Function(DateTime, Map<String, dynamic>) onTaskAdded;
  final Function(String) onGenerateMotivationForTask;
  final Function()? onTasksChanged; // New callback for task updates

  const MotivatorCalendar({
    Key? key,
    required this.selectedDay,
    required this.tasks,
    required this.generatedLine,
    required this.loading,
    this.currentTaskType,
    required this.onDaySelected,
    required this.onTaskAdded,
    required this.onGenerateMotivationForTask,
    this.onTasksChanged,
  }) : super(key: key);

  @override
  State<MotivatorCalendar> createState() => _MotivatorCalendarState();
}

class _MotivatorCalendarState extends State<MotivatorCalendar> {
  TTaskFilter _currentFilter = TaskFilter.all;
final TaskStorage _taskStorage = TaskStorage();

@override
Widget build(BuildContext context) {
  // 🚀 NEW: Clean, smooth scrolling without refresh
  return SingleChildScrollView(
    physics: const BouncingScrollPhysics(), // Smooth iOS-style scroll
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        // 📅 Calendar widget
        _buildCalendar(),
        
        const SizedBox(height: 20),
        
        // 🔴 Add Task button
        _buildAddTaskButton(context),
        
        const SizedBox(height: 20),
        
        // 🎛️ Filter Controls
        _buildFilterControls(),
        
        const SizedBox(height: 16),
        
        // 🔴 Tasks list for selected day
        _buildTasksList(context),
        
        // 🔴 Show generated motivation line
        if (widget.generatedLine.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildGeneratedLine(),
        ],
        
        // 🔑 Bottom padding for smooth scrolling
        const SizedBox(height: 100),
      ],
    ),
  );
}

  Widget _buildCalendar() {
    return TableCalendar(
      focusedDay: widget.selectedDay,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      calendarStyle: CalendarStyle(
        weekendTextStyle: const TextStyle(color: Color(0xFFD4AF37)), // Gold
        todayDecoration: const BoxDecoration(
          color: Color(0xFFD4AF37), // Gold
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.8), // Gold
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerDecoration: const BoxDecoration(
          color: Color(0xFF8B9DC3), // Muted blue-gray
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w300, // Ultra-light
          color: Colors.white,
        ),
      ),
      selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
      eventLoader: (day) => _getTasksForDay(day).map((task) => task['description'] as String).toList(),
      onDaySelected: (selectedDay, focusedDay) {
        widget.onDaySelected(selectedDay);
      },
    );
  }

  Widget _buildAddTaskButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'Add Task for ${widget.selectedDay.month}/${widget.selectedDay.day}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37), // Gold
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0a1428), Color(0xFF000000)], // Navy to Black
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3), // Gold border
          width: 1,
        ),
      ),
      child: Row(
        children: TaskFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          final filterName = _getFilterName(filter);
          final filterIcon = _getFilterIcon(filter);
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentFilter = filter;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFFD4AF37) // Gold when selected
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      filterIcon,
                      color: isSelected ? Colors.black : const Color(0xFF8B9DC3),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      filterName,
                      style: TextStyle(
                        color: isSelected ? Colors.black : const Color(0xFF8B9DC3),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksList(BuildContext context) {
    final filteredTasks = _getFilteredTasksForDay(widget.selectedDay);
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: filteredTasks.isEmpty
          ? Container(
              height: 120,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getEmptyStateIcon(),
                    color: const Color(0xFF8B9DC3),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B9DC3),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final taskData = filteredTasks[index];
                return _buildSwipeableTaskItem(taskData);
              },
            ),
    );
  }

  Widget _buildSwipeableTaskItem(Map<String, dynamic> taskData) {
    final taskId = taskData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final isCompleted = taskData['isCompleted'] ?? false;
    final isArchived = taskData['isArchived'] ?? false;
    
    return Dismissible(
      key: Key(taskId),
      background: _buildSwipeBackground(true), // Left swipe (complete/archive)
      secondaryBackground: _buildSwipeBackground(false), // Right swipe (delete)
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Left swipe - Complete/Archive
          return await _handleLeftSwipe(taskData);
        } else {
          // Right swipe - Delete
          return await _handleRightSwipe(taskData);
        }
      },
      child: _buildTaskItem(taskData),
    );
  }

  Widget _buildSwipeBackground(bool isLeftSwipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isLeftSwipe 
            ? const Color(0xFFD4AF37).withOpacity(0.8) // Gold for complete/archive
            : Colors.red.withOpacity(0.8), // Red for delete
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isLeftSwipe ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLeftSwipe ? Icons.check_circle : Icons.delete,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            isLeftSwipe ? 'Complete' : 'Delete',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> taskData) {
    final task = taskData['description'] as String;
    final scheduledTime = taskData['dateTime'] as DateTime?;
    final voiceStyle = taskData['voiceStyle'] as String?;
    final toneStyle = taskData['toneStyle'] as String?;
    final isRecurring = taskData['isRecurring'] as bool? ?? false;
    final isAmberAlert = taskData['isAmberAlert'] as bool? ?? false;
    final isCompleted = taskData['isCompleted'] as bool? ?? false;
    final isArchived = taskData['isArchived'] as bool? ?? false;
    final completedAt = taskData['completedAt'] as DateTime?;
    final recurringFrequency = taskData['recurringFrequency'] as String?;
    final selectedDays = taskData['selectedDays'] as List<dynamic>?;
    
    // Determine task status color and styling
    Color taskColor = Colors.white;
    Color borderColor = Colors.white.withOpacity(0.1);
    Color backgroundOpacity = Colors.white.withOpacity(0.05);
    FontWeight fontWeight = FontWeight.normal;
    
    if (isArchived) {
      taskColor = const Color(0xFF8B9DC3).withOpacity(0.6);
      borderColor = const Color(0xFF8B9DC3).withOpacity(0.3);
      backgroundOpacity = const Color(0xFF8B9DC3).withOpacity(0.05);
    } else if (isCompleted) {
      taskColor = const Color(0xFFD4AF37);
      borderColor = const Color(0xFFD4AF37).withOpacity(0.5);
      backgroundOpacity = const Color(0xFFD4AF37).withOpacity(0.1);
    } else if (isAmberAlert) {
      taskColor = Colors.red;
      borderColor = Colors.red.withOpacity(0.5);
      backgroundOpacity = Colors.red.withOpacity(0.1);
      fontWeight = FontWeight.bold;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundOpacity,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isAmberAlert ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isArchived)
              const Icon(Icons.archive, color: Color(0xFF8B9DC3), size: 20)
            else if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20)
            else if (isAmberAlert)
              const Icon(Icons.warning, color: Colors.red, size: 20),
          ],
        ),
        title: Row(
          children: [
            if (isAmberAlert && !isCompleted && !isArchived) ...[
              const Text(
                '🚨 ',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
            Expanded(
              child: Text(
                task,
                style: TextStyle(
                  color: taskColor,
                  fontWeight: fontWeight,
                  decoration: isCompleted && !isArchived 
                      ? TextDecoration.lineThrough 
                      : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scheduledTime != null)
              Text(
                '⏰ ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: taskColor.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            if (voiceStyle != null)
              Text(
                '🎵 $voiceStyle · $toneStyle',
                style: TextStyle(
                  color: taskColor.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            if (isAmberAlert && !isCompleted && !isArchived) ...[
              const Text(
                '🚨 AMBER ALERT - CRITICAL PRIORITY',
                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
            if (isRecurring) ...[
              Text(
                '🔄 ${recurringFrequency?.toLowerCase()}${recurringFrequency == 'Weekly' && selectedDays != null ? ' • ${selectedDays.map((d) => _getDayName(d as int)).join(', ')}' : ''}',
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10),
              ),
            ],
            if (isCompleted && completedAt != null) ...[
              Text(
                '✅ Completed ${_formatCompletionTime(completedAt)}',
                style: TextStyle(
                  color: taskColor.withOpacity(0.7),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (isArchived) ...[
              Text(
                '📦 Archived',
                style: TextStyle(
                  color: taskColor.withOpacity(0.7),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isArchived)
              const Icon(Icons.archive, color: Color(0xFF8B9DC3), size: 16)
            else if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 16)
            else if (isAmberAlert)
              const Icon(Icons.warning, color: Colors.red, size: 16),
            if (isRecurring && !isArchived)
              const Icon(Icons.repeat, color: Color(0xFFD4AF37), size: 16),
            if (scheduledTime != null && !isCompleted && !isArchived) ...[
              const SizedBox(width: 4),
              const Icon(Icons.schedule, color: Color(0xFF8B9DC3), size: 16),
            ],
            const SizedBox(width: 8),
            if (!isCompleted && !isArchived)
              widget.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                      ),
                    )
                  : Icon(
                      Icons.play_arrow, 
                      color: isAmberAlert ? Colors.red : const Color(0xFFD4AF37),
                    ),
          ],
        ),
        onTap: (!isCompleted && !isArchived && !widget.loading)
            ? () => widget.onGenerateMotivationForTask(task)
            : null,
      ),
    );
  }

  Widget _buildGeneratedLine() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.1),
            const Color(0xFFD4AF37).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Text(
        '"${widget.generatedLine}"',
        style: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Color(0xFFD4AF37),
          fontWeight: FontWeight.w300,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Helper functions
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Map<String, dynamic>> _getTasksForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    return widget.tasks[normalizedDay] ?? [];
  }

  // 🆕 NEW METHOD: Get all tasks from all dates (not just selected day)
  List<Map<String, dynamic>> _getAllTasksAcrossAllDates() {
    final allTasks = <Map<String, dynamic>>[];
    
    // Loop through all dates and collect all tasks
    for (final taskList in widget.tasks.values) {
      allTasks.addAll(taskList);
    }
    
    // Sort by date (earliest first)
    allTasks.sort((a, b) {
      final dateA = a['dateTime'] as DateTime?;
      final dateB = b['dateTime'] as DateTime?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    });
    
    return allTasks;
  }

  List<Map<String, dynamic>> _getFilteredTasksForDay(DateTime day) {
    List<Map<String, dynamic>> tasksToFilter;
    
    // 🚀 FIX: For "All" tab, get tasks from all dates, not just selected day
    if (_currentFilter == TaskFilter.all) {
      tasksToFilter = _getAllTasksAcrossAllDates();
    } else {
      // For other tabs, only show tasks for the selected day
      tasksToFilter = _getTasksForDay(day);
    }
    
    switch (_currentFilter) {
      case TaskFilter.active: // ✅ CHANGED: upcoming → active
        return tasksToFilter.where((task) => 
            !(task['isCompleted'] ?? false) && !(task['isArchived'] ?? false)).toList();
      case TaskFilter.completed:
        return tasksToFilter.where((task) => 
            (task['isCompleted'] ?? false) && !(task['isArchived'] ?? false)).toList();
      case TaskFilter.archived:
        return tasksToFilter.where((task) => task['isArchived'] ?? false).toList();
      case TaskFilter.all:
      default:
        // For "All" tab, only show active tasks (not completed/archived)
        return tasksToFilter.where((task) => 
            !(task['isCompleted'] ?? false) && !(task['isArchived'] ?? false)).toList();
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getFilterName(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All'; // Shows all active tasks across all dates
      case TaskFilter.active: // ✅ CHANGED: upcoming → active
        return 'Active';
      case TaskFilter.completed:
        return 'Done';
      case TaskFilter.archived:
        return 'Archive';
    }
  }

  IconData _getFilterIcon(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return Icons.view_list; // All tasks
      case TaskFilter.active: // ✅ CHANGED: upcoming → active
        return Icons.radio_button_unchecked; // Original icon for active tasks
      case TaskFilter.completed:
        return Icons.check_circle;
      case TaskFilter.archived:
        return Icons.archive;
    }
  }

  IconData _getEmptyStateIcon() {
    switch (_currentFilter) {
      case TaskFilter.active: // ✅ CHANGED: upcoming → active
        return Icons.add_task;
      case TaskFilter.completed:
        return Icons.check_circle_outline;
      case TaskFilter.archived:
        return Icons.archive_outlined;
      case TaskFilter.all:
      default:
        return Icons.calendar_today;
    }
  }

  String _getEmptyStateText() {
    switch (_currentFilter) {
      case TaskFilter.active: // ✅ CHANGED: upcoming → active
        return 'No active tasks for this day.\nTap "Add Task" to get started! 🎯';
      case TaskFilter.completed:
        return 'No completed tasks yet.\nComplete some tasks to see them here! ✅';
      case TaskFilter.archived:
        return 'No archived tasks.\nArchive completed tasks to organize your history! 📦';
      case TaskFilter.all:
      default:
        return 'No active tasks found.\nTap "Add Task" to create your first task! 🎯';
    }
  }

  String _formatCompletionTime(DateTime completedAt) {
    final now = DateTime.now();
    final difference = now.difference(completedAt);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Swipe handlers
  Future<bool> _handleLeftSwipe(Map<String, dynamic> taskData) async {
    final isCompleted = taskData['isCompleted'] ?? false;
    final isArchived = taskData['isArchived'] ?? false;
    
    try {
      if (!isCompleted && !isArchived) {
        // Active task -> Complete it
        await _taskStorage.completeTask(taskData['id']);
        _showActionSnackBar('Task completed! ✅', const Color(0xFFD4AF37));
      } else if (isCompleted && !isArchived) {
        // Completed task -> Archive it
        await _taskStorage.archiveTask(taskData['id']);
        _showActionSnackBar('Task archived! 📦', const Color(0xFF8B9DC3));
      } else {
        // Archived task -> Can't swipe left
        return false;
      }
      
      widget.onTasksChanged?.call();
      return true;
    } catch (e) {
      _showActionSnackBar('Error updating task', Colors.red);
      return false;
    }
  }

  Future<bool> _handleRightSwipe(Map<String, dynamic> taskData) async {
    try {
      await _taskStorage.deleteTask(taskData['id']);
      widget.onTasksChanged?.call();
      _showActionSnackBar('Task deleted! 🗑️', Colors.red);
      return true;
    } catch (e) {
      _showActionSnackBar('Error deleting task', Colors.red);
      return false;
    }
  }

  void _showActionSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show task dialog
  Future<void> _showAddTaskDialog(BuildContext context) async {
    await UltraResponsiveTaskDialog.show(
      context,
      widget.selectedDay,
      widget.onTaskAdded,
      currentTaskType: widget.currentTaskType,
    );
  }
}