import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskStorage {
  static const String _key = 'tasks';

  /// Load all tasks (active, completed, and archived)
  Future<List<Map<String, dynamic>>> loadAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = prefs.getStringList(_key) ?? [];

    return taskList.map((taskJson) {
      final map = jsonDecode(taskJson) as Map<String, dynamic>;
      
      // Ensure all tasks have the required completion fields
      map['isCompleted'] = map['isCompleted'] ?? false;
      map['completedAt'] = map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null;
      map['isArchived'] = map['isArchived'] ?? false;
      map['archivedAt'] = map['archivedAt'] != null 
          ? DateTime.parse(map['archivedAt']) 
          : null;
      map['id'] = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Convert dateTime back to DateTime object if it's a string
      if (map['dateTime'] is String) {
        map['dateTime'] = DateTime.parse(map['dateTime']);
      }
      
      return map;
    }).toList();
  }

  /// Load only active tasks (not completed or archived)
  Future<List<Map<String, dynamic>>> loadActiveTasks() async {
    final allTasks = await loadAllTasks();
    return allTasks.where((task) => 
        !(task['isCompleted'] ?? false) && 
        !(task['isArchived'] ?? false)
    ).toList();
  }

  /// Load only completed tasks (completed but not archived)
  Future<List<Map<String, dynamic>>> loadCompletedTasks() async {
    final allTasks = await loadAllTasks();
    return allTasks.where((task) => 
        (task['isCompleted'] ?? false) && 
        !(task['isArchived'] ?? false)
    ).toList();
  }

  /// Load only archived tasks
  Future<List<Map<String, dynamic>>> loadArchivedTasks() async {
    final allTasks = await loadAllTasks();
    return allTasks.where((task) => task['isArchived'] ?? false).toList();
  }

  /// Save a new task
  Future<void> saveTask(Map<String, dynamic> task) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    // Ensure task has all required fields
    task['id'] = task['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    task['isCompleted'] = task['isCompleted'] ?? false;
    task['isArchived'] = task['isArchived'] ?? false;

    // Convert DateTime objects to strings for storage
    final taskToSave = Map<String, dynamic>.from(task);
    if (taskToSave['completedAt'] is DateTime) {
      taskToSave['completedAt'] = (taskToSave['completedAt'] as DateTime).toIso8601String();
    }
    if (taskToSave['archivedAt'] is DateTime) {
      taskToSave['archivedAt'] = (taskToSave['archivedAt'] as DateTime).toIso8601String();
    }
    if (taskToSave['dateTime'] is DateTime) {
      taskToSave['dateTime'] = (taskToSave['dateTime'] as DateTime).toIso8601String();
    }

    final updated = List<String>.from(existing)..add(jsonEncode(taskToSave));
    await prefs.setStringList(_key, updated);
  }

  /// Update an existing task
  Future<void> updateTask(Map<String, dynamic> updatedTask) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    // Convert DateTime objects to strings for storage
    final taskToSave = Map<String, dynamic>.from(updatedTask);
    if (taskToSave['completedAt'] is DateTime) {
      taskToSave['completedAt'] = (taskToSave['completedAt'] as DateTime).toIso8601String();
    }
    if (taskToSave['archivedAt'] is DateTime) {
      taskToSave['archivedAt'] = (taskToSave['archivedAt'] as DateTime).toIso8601String();
    }
    if (taskToSave['dateTime'] is DateTime) {
      taskToSave['dateTime'] = (taskToSave['dateTime'] as DateTime).toIso8601String();
    }

    final updated = existing.map((taskJson) {
      final map = jsonDecode(taskJson) as Map<String, dynamic>;
      if (map['id'] == updatedTask['id']) {
        return jsonEncode(taskToSave);
      }
      return taskJson;
    }).toList();

    await prefs.setStringList(_key, updated);
  }

  /// Mark a task as completed
  Future<void> completeTask(String taskId) async {
    final tasks = await loadAllTasks();
    final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
    
    if (taskIndex != -1) {
      tasks[taskIndex]['isCompleted'] = true;
      tasks[taskIndex]['completedAt'] = DateTime.now();
      await updateTask(tasks[taskIndex]);
    }
  }

  /// Mark a completed task as archived
  Future<void> archiveTask(String taskId) async {
    final tasks = await loadAllTasks();
    final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
    
    if (taskIndex != -1) {
      tasks[taskIndex]['isArchived'] = true;
      tasks[taskIndex]['archivedAt'] = DateTime.now();
      await updateTask(tasks[taskIndex]);
    }
  }

  /// Restore a completed task back to active
  Future<void> restoreTask(String taskId) async {
    final tasks = await loadAllTasks();
    final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
    
    if (taskIndex != -1) {
      tasks[taskIndex]['isCompleted'] = false;
      tasks[taskIndex]['completedAt'] = null;
      tasks[taskIndex]['isArchived'] = false;
      tasks[taskIndex]['archivedAt'] = null;
      await updateTask(tasks[taskIndex]);
    }
  }

  /// Delete a task permanently
  Future<void> deleteTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];

    final updated = existing.where((taskJson) {
      final map = jsonDecode(taskJson) as Map<String, dynamic>;
      return map['id'] != taskId;
    }).toList();

    await prefs.setStringList(_key, updated);
  }

  /// Clear all tasks
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Clear only completed tasks (keep active ones)
  Future<void> clearCompleted() async {
    final activeTasks = await loadActiveTasks();
    final prefs = await SharedPreferences.getInstance();
    
    final taskStrings = activeTasks.map((task) {
      // Convert DateTime back to string for storage
      final taskCopy = Map<String, dynamic>.from(task);
      if (taskCopy['dateTime'] is DateTime) {
        taskCopy['dateTime'] = (taskCopy['dateTime'] as DateTime).toIso8601String();
      }
      return jsonEncode(taskCopy);
    }).toList();
    
    await prefs.setStringList(_key, taskStrings);
  }

  /// Clear only archived tasks
  Future<void> clearArchived() async {
    final nonArchivedTasks = await loadAllTasks();
    final filtered = nonArchivedTasks.where((task) => !(task['isArchived'] ?? false)).toList();
    
    final prefs = await SharedPreferences.getInstance();
    final taskStrings = filtered.map((task) {
      // Convert DateTime back to string for storage
      final taskCopy = Map<String, dynamic>.from(task);
      if (taskCopy['dateTime'] is DateTime) {
        taskCopy['dateTime'] = (taskCopy['dateTime'] as DateTime).toIso8601String();
      }
      return jsonEncode(taskCopy);
    }).toList();
    
    await prefs.setStringList(_key, taskStrings);
  }

  /// Get task statistics
  Future<Map<String, int>> getTaskStats() async {
    final allTasks = await loadAllTasks();
    
    final active = allTasks.where((task) => 
        !(task['isCompleted'] ?? false) && !(task['isArchived'] ?? false)).length;
    final completed = allTasks.where((task) => 
        (task['isCompleted'] ?? false) && !(task['isArchived'] ?? false)).length;
    final archived = allTasks.where((task) => task['isArchived'] ?? false).length;
    
    return {
      'total': allTasks.length,
      'active': active,
      'completed': completed,
      'archived': archived,
    };
  }

  // Legacy methods for backward compatibility with existing Task model
  Future<List<dynamic>> loadTasks() async {
    return await loadAllTasks();
  }

  Future<void> saveTaskLegacy(dynamic task) async {
    if (task is Map<String, dynamic>) {
      await saveTask(task);
    }
  }
}