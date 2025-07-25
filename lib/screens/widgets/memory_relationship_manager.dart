// Memory & Relationship Manager - Complete Implementation
// Replace the placeholder modal in your settings screen with this

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryRelationshipManager extends StatefulWidget {
  final String selectedPersona;

  const MemoryRelationshipManager({
    Key? key,
    required this.selectedPersona,
  }) : super(key: key);

  @override
  State<MemoryRelationshipManager> createState() => _MemoryRelationshipManagerState();
}

class _MemoryRelationshipManagerState extends State<MemoryRelationshipManager>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  // 🧠 Memory Data
  List<Map<String, dynamic>> _conversationHistory = [];
  Map<String, dynamic> _relationshipData = {};
  Map<String, dynamic> _memoryStats = {};
  Map<String, List<String>> _personalKeywords = {};
  bool _isLoading = true;
  
  // 🎭 Relationship Levels
  final Map<String, Map<String, dynamic>> _relationshipLevels = {
    'Acquaintance': {'min': 0, 'max': 30, 'color': Colors.grey, 'icon': Icons.person_outline},
    'Friend': {'min': 31, 'max': 80, 'color': Colors.blue, 'icon': Icons.person},
    'Close Friend': {'min': 81, 'max': 150, 'color': Colors.green, 'icon': Icons.favorite_border},
    'Romantic Interest': {'min': 151, 'max': 250, 'color': Colors.pink, 'icon': Icons.favorite},
    'Partner': {'min': 251, 'max': 999, 'color': Colors.red, 'icon': Icons.favorite},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMemoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoryData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load conversation history
      final historyJson = prefs.getString('conversation_history_${widget.selectedPersona}') ?? '[]';
      _conversationHistory = List<Map<String, dynamic>>.from(json.decode(historyJson));
      
      // Load relationship data
      final relationshipJson = prefs.getString('relationship_data_${widget.selectedPersona}') ?? '{}';
      _relationshipData = Map<String, dynamic>.from(json.decode(relationshipJson));
      
      // Generate memory stats
      _generateMemoryStats();
      _extractPersonalKeywords();
      
    } catch (e) {
      print('Error loading memory data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _generateMemoryStats() {
    final totalConversations = _conversationHistory.length;
    final totalMessages = _conversationHistory.fold<int>(0, (sum, conv) => sum + (conv['messages']?.length ?? 1));
    final relationshipPoints = _relationshipData['points'] ?? 0;
    final currentLevel = _getCurrentRelationshipLevel(relationshipPoints);
    
    _memoryStats = {
      'totalConversations': totalConversations,
      'totalMessages': totalMessages,
      'relationshipPoints': relationshipPoints,
      'currentLevel': currentLevel,
      'daysSinceFirstChat': _getDaysSinceFirstChat(),
      'averageConversationLength': totalConversations > 0 ? (totalMessages / totalConversations).round() : 0,
    };
  }

  String _getCurrentRelationshipLevel(int points) {
    for (final entry in _relationshipLevels.entries) {
      if (points >= entry.value['min'] && points <= entry.value['max']) {
        return entry.key;
      }
    }
    return 'Acquaintance';
  }

  int _getDaysSinceFirstChat() {
    if (_conversationHistory.isEmpty) return 0;
    final firstChat = DateTime.tryParse(_conversationHistory.first['timestamp'] ?? '');
    if (firstChat == null) return 0;
    return DateTime.now().difference(firstChat).inDays;
  }

  void _extractPersonalKeywords() {
    _personalKeywords = {
      'interests': [],
      'goals': [],
      'concerns': [],
      'preferences': [],
    };
    
    // Simple keyword extraction from conversations
    for (final conversation in _conversationHistory) {
      final messages = conversation['messages'] as List<dynamic>? ?? [];
      for (final message in messages) {
        if (message['role'] == 'user') {
          final text = message['content']?.toString().toLowerCase() ?? '';
          
          // Extract interests
          if (text.contains('love') || text.contains('enjoy') || text.contains('like')) {
            _extractKeywordsFromContext(text, 'interests');
          }
          
          // Extract goals
          if (text.contains('want to') || text.contains('goal') || text.contains('hope to')) {
            _extractKeywordsFromContext(text, 'goals');
          }
          
          // Extract concerns
          if (text.contains('worried') || text.contains('stressed') || text.contains('problem')) {
            _extractKeywordsFromContext(text, 'concerns');
          }
        }
      }
    }
  }

  void _extractKeywordsFromContext(String text, String category) {
    // Simple keyword extraction - could be enhanced with NLP
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r'[^\w]'), '');
      if (word.length > 3 && !_personalKeywords[category]!.contains(word)) {
        _personalKeywords[category]!.add(word);
        if (_personalKeywords[category]!.length > 10) break; // Limit to top 10
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0a1428),
            Color(0xFF1a2332),
            Color(0xFF0f1419),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading 
                ? _buildLoadingView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConversationTab(),
                      _buildRelationshipTab(), 
                      _buildMemoryTab(),
                      _buildControlsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF5722).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.memory,
              color: Color(0xFFFF5722),
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Memory & Relationship Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.selectedPersona} • ${_memoryStats['currentLevel'] ?? 'Loading...'}',
                  style: TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Color(0xFFFF5722),
        indicatorWeight: 3,
        labelColor: Color(0xFFFF5722),
        unselectedLabelColor: Color(0xFF8B9DC3),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(icon: Icon(Icons.chat, size: 20), text: 'Chats'),
          Tab(icon: Icon(Icons.favorite, size: 20), text: 'Relationship'),
          Tab(icon: Icon(Icons.psychology, size: 20), text: 'Memory'),
          Tab(icon: Icon(Icons.settings, size: 20), text: 'Controls'),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFF5722)),
          SizedBox(height: 16),
          Text(
            'Loading memory data...',
            style: TextStyle(color: Color(0xFF8B9DC3)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildStatsCard(
          'Conversation Statistics',
          Icons.chat_bubble_outline,
          [
            'Total Conversations: ${_memoryStats['totalConversations']}',
            'Total Messages: ${_memoryStats['totalMessages']}', 
            'Days Since First Chat: ${_memoryStats['daysSinceFirstChat']}',
            'Avg Messages/Conversation: ${_memoryStats['averageConversationLength']}',
          ],
        ),
        SizedBox(height: 16),
        _buildConversationList(),
      ],
    );
  }

  Widget _buildConversationList() {
    if (_conversationHistory.isEmpty) {
      return _buildEmptyState('No conversations yet', 'Start chatting to see your history here');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Conversations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ..._conversationHistory.reversed.take(10).map((conversation) {
          return _buildConversationCard(conversation);
        }).toList(),
      ],
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final timestamp = DateTime.tryParse(conversation['timestamp'] ?? '') ?? DateTime.now();
    final preview = conversation['preview'] ?? 'Conversation';
    final messageCount = conversation['messages']?.length ?? 1;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF8B9DC3), size: 16),
              SizedBox(width: 8),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
              ),
              Spacer(),
              Text(
                '$messageCount messages',
                style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteConversation(conversation),
                child: Icon(Icons.delete, color: Colors.red.withOpacity(0.7), size: 16),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            preview,
            style: TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipTab() {
    final currentLevel = _memoryStats['currentLevel'] ?? 'Acquaintance';
    final points = _memoryStats['relationshipPoints'] ?? 0;
    final levelData = _relationshipLevels[currentLevel]!;
    final progress = ((points - levelData['min']) / (levelData['max'] - levelData['min'])).clamp(0.0, 1.0);
    
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildRelationshipProgress(currentLevel, points, progress, levelData),
        SizedBox(height: 20),
        _buildRelationshipTimeline(),
        SizedBox(height: 20),
        _buildRelationshipActions(),
      ],
    );
  }

  Widget _buildRelationshipProgress(String level, int points, double progress, Map<String, dynamic> levelData) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (levelData['color'] as Color).withOpacity(0.2),
            (levelData['color'] as Color).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: levelData['color'].withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                levelData['icon'],
                color: levelData['color'],
                size: 32,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$points relationship points',
                      style: TextStyle(
                        color: Color(0xFF8B9DC3),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(levelData['color']),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${levelData['min']} pts',
                style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
              ),
              Text(
                '${levelData['max']} pts',
                style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationship Journey',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ..._relationshipLevels.entries.map((entry) {
          final isUnlocked = (_memoryStats['relationshipPoints'] ?? 0) >= entry.value['min'];
          final isCurrent = entry.key == _memoryStats['currentLevel'];
          
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent 
                  ? entry.value['color'].withOpacity(0.2)
                  : Colors.white.withOpacity(isUnlocked ? 0.05 : 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent 
                    ? entry.value['color']
                    : Colors.white.withOpacity(isUnlocked ? 0.2 : 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  entry.value['icon'],
                  color: isUnlocked ? entry.value['color'] : Color(0xFF8B9DC3),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Color(0xFF8B9DC3),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Text(
                  '${entry.value['min']}-${entry.value['max']} pts',
                  style: TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 12,
                  ),
                ),
                if (isCurrent) ...[
                  SizedBox(width: 8),
                  Icon(Icons.star, color: entry.value['color'], size: 16),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRelationshipActions() {
    return Column(
      children: [
        _buildActionButton(
          'Reset Relationship',
          'Start over as acquaintances',
          Icons.refresh,
          Colors.orange,
          _showResetRelationshipDialog,
        ),
        SizedBox(height: 12),
        _buildActionButton(
          'Export Relationship Data',
          'Download your journey together',
          Icons.download,
          Colors.blue,
          _exportRelationshipData,
        ),
      ],
    );
  }

  Widget _buildMemoryTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildStatsCard(
          'What ${widget.selectedPersona} Remembers',
          Icons.psychology,
          [
            'Personal Keywords: ${_personalKeywords.values.expand((x) => x).length}',
            'Conversation Topics: ${_getUniqueTopics().length}',
            'Behavioral Patterns: ${_getBehavioralPatterns().length}',
            'Memory Accuracy: ${_getMemoryAccuracy()}%',
          ],
        ),
        SizedBox(height: 16),
        _buildPersonalKeywords(),
        SizedBox(height: 16),
        _buildTopicCloud(),
      ],
    );
  }

  Widget _buildPersonalKeywords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Keywords',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ..._personalKeywords.entries.map((entry) {
          if (entry.value.isEmpty) return SizedBox.shrink();
          
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFFFF5722),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((keyword) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF5722).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        keyword,
                        style: TextStyle(
                          color: Color(0xFFFF5722),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildControlsTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildDangerZone(),
        SizedBox(height: 20),
        _buildExportOptions(),
        SizedBox(height: 20),
        _buildPrivacyControls(),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildActionButton(
            'Delete All Conversations',
            'Permanently remove all chat history',
            Icons.delete_forever,
            Colors.red,
            _showDeleteAllDialog,
          ),
          SizedBox(height: 12),
          _buildActionButton(
            'Reset All Memory',
            'Wipe everything and start fresh',
            Icons.memory,
            Colors.red,
            _showResetAllDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export & Backup',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _buildActionButton(
          'Export All Data',
          'Download complete conversation history',
          Icons.download,
          Colors.blue,
          _exportAllData,
        ),
        SizedBox(height: 12),
        _buildActionButton(
          'Export Relationship Summary',
          'Get a summary of your journey',
          Icons.summarize,
          Colors.green,
          _exportRelationshipSummary,
        ),
      ],
    );
  }

  Widget _buildPrivacyControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Controls',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _buildToggleCard(
          'Memory Learning',
          'Allow AI to learn from conversations',
          true,
          (value) {
            // TODO: Implement memory learning toggle
          },
        ),
        SizedBox(height: 8),
        _buildToggleCard(
          'Relationship Progression',
          'Enable automatic relationship development',
          true,
          (value) {
            // TODO: Implement relationship progression toggle
          },
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildStatsCard(String title, IconData icon, List<String> stats) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFFFF5722), size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...stats.map((stat) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFFFF5722), size: 8),
                  SizedBox(width: 12),
                  Text(
                    stat,
                    style: TextStyle(color: Color(0xFF8B9DC3)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Color(0xFF8B9DC3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFFFF5722),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Color(0xFF8B9DC3),
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Color(0xFF8B9DC3),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCloud() {
    final topics = _getUniqueTopics();
    if (topics.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversation Topics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topics.map((topic) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                topic,
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper Methods
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  List<String> _getUniqueTopics() {
    // Extract topics from conversation data
    return ['work', 'hobbies', 'goals', 'relationships']; // Placeholder
  }

  List<String> _getBehavioralPatterns() {
    // Analyze behavioral patterns
    return ['morning_person', 'goal_oriented', 'analytical']; // Placeholder
  }

  int _getMemoryAccuracy() {
    // Calculate memory accuracy score
    return 85; // Placeholder
  }

  // Action Methods
  Future<void> _deleteConversation(Map<String, dynamic> conversation) async {
    final confirmed = await _showConfirmDialog(
      'Delete Conversation',
      'This will permanently delete this conversation. Continue?',
    );
    
    if (confirmed) {
      setState(() {
        _conversationHistory.remove(conversation);
      });
      await _saveMemoryData();
      _generateMemoryStats();
    }
  }

  Future<void> _showResetRelationshipDialog() async {
    final confirmed = await _showConfirmDialog(
      'Reset Relationship',
      'This will reset your relationship with ${widget.selectedPersona} back to acquaintances. All relationship progress will be lost. Continue?',
    );
    
    if (confirmed) {
      setState(() {
        _relationshipData['points'] = 0;
        _relationshipData['level'] = 'Acquaintance';
      });
      await _saveMemoryData();
      _generateMemoryStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relationship reset to Acquaintance level'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await _showConfirmDialog(
      'Delete All Conversations',
      'This will permanently delete ALL conversation history with ${widget.selectedPersona}. This cannot be undone. Continue?',
    );
    
    if (confirmed) {
      setState(() {
        _conversationHistory.clear();
      });
      await _saveMemoryData();
      _generateMemoryStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All conversations deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showResetAllDialog() async {
    final confirmed = await _showConfirmDialog(
      'Reset All Memory',
      'This will delete EVERYTHING - all conversations, relationship progress, and memories with ${widget.selectedPersona}. This cannot be undone. Continue?',
    );
    
    if (confirmed) {
      setState(() {
        _conversationHistory.clear();
        _relationshipData.clear();
        _personalKeywords.clear();
      });
      await _saveMemoryData();
      _generateMemoryStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All memory data reset'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportAllData() async {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📤 Export feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _exportRelationshipData() async {
    // TODO: Implement relationship data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📊 Relationship export coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _exportRelationshipSummary() async {
    // TODO: Implement relationship summary export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Summary export coming soon'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1a2332),
        title: Text(title, style: TextStyle(color: Colors.white)),
        content: Text(content, style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveMemoryData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conversation_history_${widget.selectedPersona}', json.encode(_conversationHistory));
    await prefs.setString('relationship_data_${widget.selectedPersona}', json.encode(_relationshipData));
  }
}