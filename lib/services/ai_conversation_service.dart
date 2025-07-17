// lib/services/ai_conversation_service.dart - Complete AI Learning System
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class AIConversationService {
  static const String baseUrl = 'https://motivator-ai-backend.onrender.com';
  
  // 💭 Local Memory Cache
  Map<String, UserMemoryCache> _memoryCache = {};
  String? _currentUserId;
  
  // 🎯 Conversation Analytics
  List<ConversationInsight> _insights = [];
  Map<String, dynamic> _userPatterns = {};
  
  // 🧠 Learning Patterns
  Map<String, int> _motivationTriggers = {};
  Map<String, double> _effectiveStrategies = {};
  List<String> _personalKeywords = [];

  /// Initialize AI conversation service with user context
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _loadLocalMemory();
    await _syncWithServer();
    await _analyzeUserPatterns();
  }

  /// 🎤 Send voice message and get AI response with learning
  Future<AIConversationResponse> sendVoiceMessage({
    required File audioFile,
    required String personality,
    String? conversationId,
  }) async {
    try {
      print("🚀 Sending voice message to AI with learning...");
      
      // 1. Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/voice-conversation/voice-message'),
      );
      
      // 2. Add audio file
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      
      // 3. Add conversation data with learning context
      request.fields['userId'] = _currentUserId!;
      request.fields['personality'] = personality;
      if (conversationId != null) {
        request.fields['conversationId'] = conversationId;
      }
      
      // 4. Add learning context
      request.fields['userContext'] = json.encode(_buildUserContext());
      
      // 5. Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 6. Process AI response and extract learning
        final aiResponse = AIConversationResponse.fromJson(data);
        await _processLearningFromResponse(aiResponse);
        
        return aiResponse;
      } else {
        throw Exception('AI Conversation failed: ${response.statusCode}');
      }
      
    } catch (e) {
      print("❌ Voice conversation error: $e");
      throw AIConversationException('Failed to process voice message: $e');
    }
  }

  /// 🧠 Build user context for personalized AI responses
  Map<String, dynamic> _buildUserContext() {
    final cache = _getMemoryCache();
    
    return {
      'conversationHistory': cache.recentConversations.length,
      'preferredPersonality': cache.preferredPersonality,
      'motivationTriggers': _motivationTriggers,
      'effectiveStrategies': _effectiveStrategies.keys.toList(),
      'personalKeywords': _personalKeywords,
      'recentTopics': cache.recentTopics,
      'currentGoals': cache.currentGoals,
      'timeOfDay': _getCurrentTimeContext(),
      'userMood': cache.lastKnownMood,
      'engagementLevel': cache.engagementScore,
    };
  }

  /// 📊 Process learning from AI conversation response
  Future<void> _processLearningFromResponse(AIConversationResponse response) async {
    try {
      // 1. Update conversation cache
      await _updateConversationCache(response);
      
      // 2. Extract learning patterns
      await _extractLearningPatterns(response);
      
      // 3. Update user preferences
      await _updateUserPreferences(response);
      
      // 4. Generate insights
      await _generateNewInsights(response);
      
      // 5. Save to local storage
      await _saveLocalMemory();
      
      // 6. Sync with server
      await _syncWithServer();
      
      print("🧠 Learning processed and saved");
      
    } catch (e) {
      print("❌ Learning processing error: $e");
    }
  }

  /// 🎯 Extract learning patterns from conversation
  Future<void> _extractLearningPatterns(AIConversationResponse response) async {
    // Analyze user message for patterns
    final userMessage = response.userMessage.toLowerCase();
    
    // 1. Update motivation triggers
    _updateMotivationTriggers(userMessage);
    
    // 2. Track effective strategies
    if (response.userSatisfaction != null && response.userSatisfaction! > 0.7) {
      _trackEffectiveStrategy(response.personality, response.aiResponse);
    }
    
    // 3. Extract personal keywords
    _extractPersonalKeywords(userMessage);
    
    // 4. Update conversation patterns
    _updateConversationPatterns(response);
  }

  void _updateMotivationTriggers(String userMessage) {
    final triggers = {
      'stress': ['stressed', 'overwhelmed', 'pressure', 'anxious'],
      'energy': ['tired', 'exhausted', 'low energy', 'drained'],
      'focus': ['distracted', 'unfocused', 'scattered'],
      'confidence': ['doubt', 'uncertain', 'not sure', 'worried'],
      'motivation': ['unmotivated', 'procrastinating', 'lazy'],
    };
    
    triggers.forEach((trigger, keywords) {
      if (keywords.any((keyword) => userMessage.contains(keyword))) {
        _motivationTriggers[trigger] = (_motivationTriggers[trigger] ?? 0) + 1;
      }
    });
  }

  void _trackEffectiveStrategy(String personality, String aiResponse) {
    final strategies = _analyzeAIStrategy(aiResponse);
    strategies.forEach((strategy) {
      final key = '${personality}_$strategy';
      _effectiveStrategies[key] = (_effectiveStrategies[key] ?? 0.0) + 0.1;
    });
  }

  List<String> _analyzeAIStrategy(String aiResponse) {
    final strategies = <String>[];
    final response = aiResponse.toLowerCase();
    
    if (response.contains('adventure') || response.contains('explore')) {
      strategies.add('adventure_metaphors');
    }
    if (response.contains('step') || response.contains('break down')) {
      strategies.add('step_by_step');
    }
    if (response.contains('celebrate') || response.contains('achievement')) {
      strategies.add('celebration_focus');
    }
    if (response.contains('data') || response.contains('analyze')) {
      strategies.add('analytical_approach');
    }
    
    return strategies;
  }

  void _extractPersonalKeywords(String userMessage) {
    final words = userMessage.split(' ');
    final meaningfulWords = words.where((word) => 
      word.length > 3 && 
      !['this', 'that', 'with', 'have', 'been', 'will'].contains(word)
    ).toList();
    
    meaningfulWords.forEach((word) {
      if (!_personalKeywords.contains(word)) {
        _personalKeywords.add(word);
      }
    });
    
    // Keep only top 50 keywords
    if (_personalKeywords.length > 50) {
      _personalKeywords = _personalKeywords.sublist(_personalKeywords.length - 50);
    }
  }

  /// 📈 Generate insights from user patterns
  Future<void> _generateNewInsights(AIConversationResponse response) async {
    final insights = <ConversationInsight>[];
    
    // 1. Motivation pattern insights
    if (_motivationTriggers.isNotEmpty) {
      final topTrigger = _motivationTriggers.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      insights.add(ConversationInsight(
        type: InsightType.motivationPattern,
        title: 'Your Main Challenge',
        description: 'You often mention ${topTrigger.key} in conversations',
        actionable: 'Consider focused ${topTrigger.key} management strategies',
        confidence: 0.8,
        discoveredAt: DateTime.now(),
      ));
    }
    
    // 2. Effective strategy insights
    if (_effectiveStrategies.isNotEmpty) {
      final topStrategy = _effectiveStrategies.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      insights.add(ConversationInsight(
        type: InsightType.effectiveStrategy,
        title: 'What Works For You',
        description: 'You respond well to ${topStrategy.key.split('_')[1]} approaches',
        actionable: 'Continue using this strategy in future conversations',
        confidence: 0.9,
        discoveredAt: DateTime.now(),
      ));
    }
    
    // 3. Engagement pattern insights
    final cache = _getMemoryCache();
    if (cache.recentConversations.length >= 5) {
      final avgLength = cache.recentConversations
          .map((c) => c.duration)
          .reduce((a, b) => a + b) / cache.recentConversations.length;
      
      insights.add(ConversationInsight(
        type: InsightType.engagementPattern,
        title: 'Your Conversation Style',
        description: 'Your average conversation lasts ${avgLength.toInt()} minutes',
        actionable: avgLength > 5 
            ? 'You enjoy detailed conversations' 
            : 'Quick, focused sessions work best for you',
        confidence: 0.7,
        discoveredAt: DateTime.now(),
      ));
    }
    
    _insights.addAll(insights);
    
    // Keep only last 20 insights
    if (_insights.length > 20) {
      _insights = _insights.sublist(_insights.length - 20);
    }
  }

  /// 💾 Local memory management
  Future<void> _loadLocalMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load memory cache
      final cacheData = prefs.getString('memory_cache_$_currentUserId');
      if (cacheData != null) {
        _memoryCache[_currentUserId!] = UserMemoryCache.fromJson(json.decode(cacheData));
      }
      
      // Load learning patterns
      final patternsData = prefs.getString('patterns_$_currentUserId');
      if (patternsData != null) {
        final patterns = json.decode(patternsData);
        _motivationTriggers = Map<String, int>.from(patterns['triggers'] ?? {});
        _effectiveStrategies = Map<String, double>.from(patterns['strategies'] ?? {});
        _personalKeywords = List<String>.from(patterns['keywords'] ?? []);
      }
      
      // Load insights
      final insightsData = prefs.getString('insights_$_currentUserId');
      if (insightsData != null) {
        final insightsList = json.decode(insightsData) as List;
        _insights = insightsList.map((i) => ConversationInsight.fromJson(i)).toList();
      }
      
      print("💾 Local memory loaded");
      
    } catch (e) {
      print("❌ Error loading local memory: $e");
    }
  }

  Future<void> _saveLocalMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save memory cache
      final cache = _getMemoryCache();
      await prefs.setString('memory_cache_$_currentUserId', json.encode(cache.toJson()));
      
      // Save learning patterns
      final patterns = {
        'triggers': _motivationTriggers,
        'strategies': _effectiveStrategies,
        'keywords': _personalKeywords,
        'updatedAt': DateTime.now().toISOString(),
      };
      await prefs.setString('patterns_$_currentUserId', json.encode(patterns));
      
      // Save insights
      final insightsData = _insights.map((i) => i.toJson()).toList();
      await prefs.setString('insights_$_currentUserId', json.encode(insightsData));
      
      print("💾 Local memory saved");
      
    } catch (e) {
      print("❌ Error saving local memory: $e");
    }
  }

  /// ☁️ Server synchronization
  Future<void> _syncWithServer() async {
    try {
      // Upload local patterns to server
      await _uploadPatternsToServer();
      
      // Download server insights
      await _downloadInsightsFromServer();
      
      print("☁️ Server sync completed");
      
    } catch (e) {
      print("❌ Server sync error: $e");
    }
  }

  Future<void> _uploadPatternsToServer() async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-user-pattern'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': _currentUserId,
        'patterns': {
          'motivationTriggers': _motivationTriggers,
          'effectiveStrategies': _effectiveStrategies,
          'personalKeywords': _personalKeywords,
        }
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to upload patterns');
    }
  }

  Future<void> _downloadInsightsFromServer() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user-analytics/$_currentUserId'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Process server insights and merge with local insights
      // Implementation depends on server response format
    }
  }

  /// 🎯 Public API methods
  
  List<ConversationInsight> getInsights() => List.from(_insights);
  
  Map<String, int> getMotivationTriggers() => Map.from(_motivationTriggers);
  
  Map<String, double> getEffectiveStrategies() => Map.from(_effectiveStrategies);
  
  List<String> getPersonalKeywords() => List.from(_personalKeywords);
  
  UserMemoryCache getUserMemory() => _getMemoryCache();

  String getRecommendedPersonality() {
    if (_effectiveStrategies.isEmpty) return 'Lana Croft';
    
    final personalityScores = <String, double>{};
    _effectiveStrategies.forEach((key, value) {
      final personality = key.split('_')[0];
      personalityScores[personality] = (personalityScores[personality] ?? 0.0) + value;
    });
    
    if (personalityScores.isEmpty) return 'Lana Croft';
    
    return personalityScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 🛠️ Utility methods
  
  UserMemoryCache _getMemoryCache() {
    return _memoryCache[_currentUserId!] ??= UserMemoryCache(
      userId: _currentUserId!,
      preferredPersonality: 'Lana Croft',
      recentConversations: [],
      recentTopics: [],
      currentGoals: [],
      lastKnownMood: 'neutral',
      engagementScore: 0.5,
      createdAt: DateTime.now(),
    );
  }

  String _getCurrentTimeContext() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  Future<void> _updateConversationCache(AIConversationResponse response) async {
    final cache = _getMemoryCache();
    
    cache.recentConversations.add(ConversationSummary(
      id: response.conversationId,
      personality: response.personality,
      duration: 2, // Estimate, could be tracked more precisely
      topics: [], // Could be extracted from AI response
      satisfaction: response.userSatisfaction ?? 0.5,
      timestamp: DateTime.now(),
    ));
    
    // Keep only last 10 conversations
    if (cache.recentConversations.length > 10) {
      cache.recentConversations = cache.recentConversations.sublist(
        cache.recentConversations.length - 10
      );
    }
  }

  Future<void> _updateUserPreferences(AIConversationResponse response) async {
    // Implementation for updating user preferences based on conversation
  }

  void _updateConversationPatterns(AIConversationResponse response) {
    // Implementation for updating conversation patterns
  }

  Future<void> _analyzeUserPatterns() async {
    // Implementation for analyzing user patterns
  }
}

// 📊 Data Models for AI Learning System

class AIConversationResponse {
  final String conversationId;
  final String userMessage;
  final String aiResponse;
  final String personality;
  final String? audioUrl;
  final double? userSatisfaction;
  final Map<String, dynamic>? learningExtracted;

  AIConversationResponse({
    required this.conversationId,
    required this.userMessage,
    required this.aiResponse,
    required this.personality,
    this.audioUrl,
    this.userSatisfaction,
    this.learningExtracted,
  });

  factory AIConversationResponse.fromJson(Map<String, dynamic> json) {
    return AIConversationResponse(
      conversationId: json['conversationId'],
      userMessage: json['userMessage'],
      aiResponse: json['aiResponse'],
      personality: json['personality'],
      audioUrl: json['audioUrl'],
      userSatisfaction: json['userSatisfaction']?.toDouble(),
      learningExtracted: json['learningExtracted'],
    );
  }
}

class ConversationInsight {
  final InsightType type;
  final String title;
  final String description;
  final String actionable;
  final double confidence;
  final DateTime discoveredAt;

  ConversationInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.actionable,
    required this.confidence,
    required this.discoveredAt,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'title': title,
    'description': description,
    'actionable': actionable,
    'confidence': confidence,
    'discoveredAt': discoveredAt.toISOString(),
  };

  factory ConversationInsight.fromJson(Map<String, dynamic> json) {
    return ConversationInsight(
      type: InsightType.values.firstWhere((e) => e.toString() == json['type']),
      title: json['title'],
      description: json['description'],
      actionable: json['actionable'],
      confidence: json['confidence'],
      discoveredAt: DateTime.parse(json['discoveredAt']),
    );
  }
}

enum InsightType {
  motivationPattern,
  effectiveStrategy,
  engagementPattern,
  personalityMatch,
  goalProgress
}

class UserMemoryCache {
  final String userId;
  String preferredPersonality;
  List<ConversationSummary> recentConversations;
  List<String> recentTopics;
  List<String> currentGoals;
  String lastKnownMood;
  double engagementScore;
  final DateTime createdAt;

  UserMemoryCache({
    required this.userId,
    required this.preferredPersonality,
    required this.recentConversations,
    required this.recentTopics,
    required this.currentGoals,
    required this.lastKnownMood,
    required this.engagementScore,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'preferredPersonality': preferredPersonality,
    'recentConversations': recentConversations.map((c) => c.toJson()).toList(),
    'recentTopics': recentTopics,
    'currentGoals': currentGoals,
    'lastKnownMood': lastKnownMood,
    'engagementScore': engagementScore,
    'createdAt': createdAt.toISOString(),
  };

  factory UserMemoryCache.fromJson(Map<String, dynamic> json) {
    return UserMemoryCache(
      userId: json['userId'],
      preferredPersonality: json['preferredPersonality'],
      recentConversations: (json['recentConversations'] as List)
          .map((c) => ConversationSummary.fromJson(c))
          .toList(),
      recentTopics: List<String>.from(json['recentTopics']),
      currentGoals: List<String>.from(json['currentGoals']),
      lastKnownMood: json['lastKnownMood'],
      engagementScore: json['engagementScore'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ConversationSummary {
  final String id;
  final String personality;
  final int duration;
  final List<String> topics;
  final double satisfaction;
  final DateTime timestamp;

  ConversationSummary({
    required this.id,
    required this.personality,
    required this.duration,
    required this.topics,
    required this.satisfaction,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'personality': personality,
    'duration': duration,
    'topics': topics,
    'satisfaction': satisfaction,
    'timestamp': timestamp.toISOString(),
  };

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'],
      personality: json['personality'],
      duration: json['duration'],
      topics: List<String>.from(json['topics']),
      satisfaction: json['satisfaction'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class AIConversationException implements Exception {
  final String message;
  AIConversationException(this.message);
  
  @override
  String toString() => 'AIConversationException: $message';
}