// lib/screens/memory_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_bottom_navbar.dart';
import 'dart:convert';
import 'dart:math' as math;

class MemoryManagementScreen extends StatefulWidget {
  final String? selectedPersona;

  const MemoryManagementScreen({
    Key? key,
    this.selectedPersona,
  }) : super(key: key);

  @override
  State<MemoryManagementScreen> createState() => _MemoryManagementScreenState();
}

class _MemoryManagementScreenState extends State<MemoryManagementScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  
  // 🧠 Memory Data
  List<Map<String, dynamic>> _conversationHistory = [];
  Map<String, dynamic> _relationshipData = {};
  Map<String, dynamic> _memoryStats = {};
  List<Map<String, dynamic>> _customMemories = [];
  
  // 🔍 Search functionality
  String _currentSearchQuery = '';
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isSearching = false;
  bool _isLoading = true;
  
  // Get current persona
  String get currentPersona => widget.selectedPersona ?? 'Lana Croft';
  
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
    _initAnimations();
    _loadMemoryData();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoryData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 🔍 Try multiple key formats to find conversation data
      List<String> possibleKeys = [
        'conversation_history_$currentPersona',
        'conversation_history_Lana Croft',
        'conversation_history',
        'persistent_memory_$currentPersona',
        'conversations_$currentPersona',
        'conversations',
        'chat_history',
        'voice_chat_history',
      ];
      
      // Load conversation history
      String? historyJson;
      String foundKey = '';
      for (String key in possibleKeys) {
        historyJson = prefs.getString(key);
        if (historyJson != null) {
          foundKey = key;
          print('✅ Found conversation data at key: $key');
          break;
        }
      }
      
      if (historyJson != null) {
        try {
          final decoded = json.decode(historyJson);
          if (decoded is List) {
            _conversationHistory = List<Map<String, dynamic>>.from(decoded);
            print('✅ Loaded ${_conversationHistory.length} conversations from $foundKey');
          } else if (decoded is Map) {
            _conversationHistory = [Map<String, dynamic>.from(decoded)];
            print('✅ Converted map to list: 1 conversation from $foundKey');
          }
        } catch (e) {
          print('❌ Error parsing conversation history: $e');
          _conversationHistory = [];
        }
      } else {
        print('⚠️ No conversation history found');
        _conversationHistory = [];
      }
      
      // Load relationship data
      List<String> relationshipKeys = [
        'relationship_data_$currentPersona',
        'relationship_$currentPersona',
        'memory_stats_$currentPersona',
        'backend_memory_stats',
        'total_conversations',
      ];
      
      String? relationshipJson;
      for (String key in relationshipKeys) {
        final value = prefs.get(key);
        if (value != null) {
          print('🔍 Found relationship data at key: $key, value: $value');
          if (value is String) {
            relationshipJson = value;
          } else {
            _relationshipData[key.replaceAll('_$currentPersona', '')] = value;
          }
        }
      }
      
      if (relationshipJson != null) {
        try {
          _relationshipData.addAll(Map<String, dynamic>.from(json.decode(relationshipJson)));
        } catch (e) {
          print('❌ Error parsing relationship JSON: $e');
        }
      }
      
      // Create default relationship data if none exists
      if (_relationshipData.isEmpty) {
        _relationshipData = {
          'points': 0,
          'level': 'Acquaintance',
          'totalConversations': _conversationHistory.length,
        };
      }
      
      // 🧠 Load custom memories
      final customMemoriesJson = prefs.getString('custom_memories_$currentPersona') ?? '[]';
      try {
        _customMemories = List<Map<String, dynamic>>.from(json.decode(customMemoriesJson));
        print('🧠 Loaded ${_customMemories.length} custom memories');
      } catch (e) {
        print('❌ Error loading custom memories: $e');
        _customMemories = [];
      }
      
      // Generate memory stats
      _generateMemoryStats();
      
    } catch (e) {
      print('❌ Error loading memory data: $e');
      _conversationHistory = [];
      _relationshipData = {'points': 0, 'level': 'Acquaintance'};
    }
    
    setState(() => _isLoading = false);
  }

  void _generateMemoryStats() {
    final totalConversations = _conversationHistory.length;
    final backendTotalConversations = _relationshipData['totalConversations'] ?? totalConversations;
    final relationshipPoints = _relationshipData['points'] ?? math.max(0, (backendTotalConversations * 2));
    final currentLevel = _getCurrentRelationshipLevel(relationshipPoints);
    
    // Calculate additional stats
    int totalMessages = 0;
    for (var conversation in _conversationHistory) {
      if (conversation['user'] != null) totalMessages++;
      if (conversation['assistant'] != null) totalMessages++;
    }
    
    final avgConversationLength = totalConversations > 0 ? (totalMessages / totalConversations).round() : 0;
    
    _memoryStats = {
      'totalConversations': backendTotalConversations,
      'localConversations': totalConversations,
      'totalMessages': totalMessages,
      'averageConversationLength': avgConversationLength,
      'relationshipPoints': relationshipPoints,
      'currentLevel': currentLevel,
      'daysSinceFirstChat': _getDaysSinceFirstChat(),
    };
    
    print('📊 Memory Stats Generated: $_memoryStats');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0a1428),
              Color(0xFF1a2332),
              Color(0xFF0f1419),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _slideAnimation.value)),
                      child: Opacity(
                        opacity: _slideAnimation.value,
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
                    );
                  },
                ),
              ),
              AppBottomNavBar(currentScreen: AppScreen.memory),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.memory,
              color: Color(0xFFFF5722),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Memory & Relationships',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$currentPersona • ${_memoryStats['currentLevel'] ?? 'Loading...'}',
                  style: const TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFFF5722),
        indicatorWeight: 3,
        labelColor: const Color(0xFFFF5722),
        unselectedLabelColor: const Color(0xFF8B9DC3),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.chat, size: 20), text: 'Chats'),
          Tab(icon: Icon(Icons.favorite, size: 20), text: 'Relationship'),
          Tab(icon: Icon(Icons.psychology, size: 20), text: 'Memory'),
          Tab(icon: Icon(Icons.settings, size: 20), text: 'Controls'),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
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
      padding: const EdgeInsets.all(20),
      children: [
        // Stats Card with Search
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSearching ? 'Search Results' : 'Conversation Statistics',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (_isSearching) ...[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearching = false;
                              _filteredConversations.clear();
                              _currentSearchQuery = '';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.clear, color: Colors.orange, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      GestureDetector(
                        onTap: _showSearchDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.search, color: Color(0xFF4A90E2), size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isSearching) ...[
                Text(
                  'Searching for: "$_currentSearchQuery"',
                  style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 14),
                ),
                Text(
                  'Found ${_filteredConversations.length} matches',
                  style: const TextStyle(color: Color(0xFF4A90E2), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ] else ...[
                _buildMemoryStatRow('Total Conversations', '${_memoryStats['totalConversations']}'),
                _buildMemoryStatRow('Total Messages', '${_memoryStats['totalMessages']}'),
                _buildMemoryStatRow('Days Since First Chat', '${_memoryStats['daysSinceFirstChat']}'),
                _buildMemoryStatRow('Avg Messages/Conversation', '${_memoryStats['averageConversationLength']}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _isSearching ? _buildSearchResults() : _buildConversationList(),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredConversations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Column(
          children: [
            Icon(Icons.search_off, color: Color(0xFF8B9DC3), size: 48),
            SizedBox(height: 16),
            Text(
              'No matches found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching for different keywords',
              style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._filteredConversations.map((result) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Conversation ${result['conversationIndex']}',
                      style: const TextStyle(
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatTimestamp(DateTime.tryParse(result['timestamp'] ?? '') ?? DateTime.now()),
                      style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...result['matchedContent'].map<Widget>((content) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      content,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildConversationList() {
    if (_conversationHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Column(
          children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF8B9DC3), size: 48),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Start chatting to see your history here',
              style: TextStyle(color: Color(0xFF8B9DC3), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Conversations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._conversationHistory.map((conversation) {
          final index = _conversationHistory.indexOf(conversation);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Conversation ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => _deleteConversation(conversation),
                      child: Icon(Icons.delete, color: Colors.red.withOpacity(0.7), size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  conversation['timestamp'] ?? 'Unknown time',
                  style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                ),
                if (conversation['user'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You: ${conversation['user']}',
                    style: const TextStyle(color: Color(0xFF8B9DC3)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRelationshipTab() {
    final currentLevel = _memoryStats['currentLevel'] ?? 'Acquaintance';
    final points = _memoryStats['relationshipPoints'] ?? 0;
    final levelData = _relationshipLevels[currentLevel]!;
    final progress = ((points - levelData['min']) / (levelData['max'] - levelData['min'])).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Current Relationship Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (levelData['color'] as Color).withOpacity(0.3),
                  (levelData['color'] as Color).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: levelData['color'].withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Icon(
                  levelData['icon'],
                  color: levelData['color'],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  currentLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$points relationship points',
                  style: const TextStyle(
                    color: Color(0xFF8B9DC3),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(levelData['color']),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${levelData['min']} pts',
                      style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                    ),
                    Text(
                      '${levelData['max']} pts',
                      style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Relationship Journey
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relationship Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: _relationshipLevels.entries.map((entry) {
                      final isUnlocked = points >= entry.value['min'];
                      final isCurrent = entry.key == currentLevel;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
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
                              color: isUnlocked ? entry.value['color'] : const Color(0xFF8B9DC3),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : const Color(0xFF8B9DC3),
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value['min']}-${entry.value['max']} pts',
                              style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 12),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.star, color: entry.value['color'], size: 16),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'What $currentPersona Remembers',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Memory Stats Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology, color: Color(0xFFFF5722), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Memory Statistics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMemoryStatRow('Total Conversations', '${_memoryStats['totalConversations']}'),
              _buildMemoryStatRow('Relationship Points', '${_memoryStats['relationshipPoints']}'),
              _buildMemoryStatRow('Current Level', '${_memoryStats['currentLevel']}'),
              _buildMemoryStatRow('Days Chatting', '${_memoryStats['daysSinceFirstChat']}'),
              _buildMemoryStatRow('Custom Memories', '${_customMemories.length}'),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Add Custom Memory Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAddMemoryDialog,
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text('Add Custom Memory', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Custom Memories Section
        if (_customMemories.isNotEmpty) ...[
          const Text(
            'Custom Memories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._customMemories.map((memory) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        memory['category'] ?? 'General',
                        style: const TextStyle(
                          color: Color(0xFF4A90E2),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteCustomMemory(memory),
                        child: Icon(Icons.delete, color: Colors.red.withOpacity(0.7), size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    memory['memory'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added: ${_formatTimestamp(DateTime.tryParse(memory['timestamp'] ?? '') ?? DateTime.now())}',
                    style: const TextStyle(
                      color: Color(0xFF8B9DC3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
        ],
        
        // Recent Topics (from backend logs)
        const Text(
          'Recent Topics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['hobbies', 'relationships', 'health', 'walks', 'evening activities'].map((topic) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                topic,
                style: const TextStyle(
                  color: Color(0xFF34C759),
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMemoryStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Color(0xFFFF5722), size: 6),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildActionButton(
          'Delete All Conversations',
          'Remove all chat history',
          Icons.delete_forever,
          Colors.red,
          _showDeleteAllDialog,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'Reset Relationship',
          'Start over as acquaintances',
          Icons.refresh,
          Colors.orange,
          _showResetRelationshipDialog,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          'Export Data',
          'Download conversation history',
          Icons.download,
          Colors.blue,
          _exportData,
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF8B9DC3), fontSize: 12)),
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

  // SEARCH AND DIALOG METHODS
  Future<void> _showSearchDialog() async {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2332),
        title: const Text('Search Conversations', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            hintStyle: TextStyle(color: Color(0xFF8B9DC3)),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch(searchController.text);
            },
            child: const Text('Search', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredConversations.clear();
        _currentSearchQuery = '';
      });
      return;
    }

    final lowerQuery = query.toLowerCase().trim();
    final results = <Map<String, dynamic>>[];

    // Search through all conversations
    for (int i = 0; i < _conversationHistory.length; i++) {
      final conversation = _conversationHistory[i];
      bool hasMatch = false;
      List<String> matchedContent = [];

      // Search in user message
      final userMessage = conversation['user']?.toString().toLowerCase() ?? '';
      if (userMessage.contains(lowerQuery)) {
        hasMatch = true;
        matchedContent.add('You: ${conversation['user']}');
      }

      // Search in assistant message  
      final assistantMessage = conversation['assistant']?.toString().toLowerCase() ?? '';
      if (assistantMessage.contains(lowerQuery)) {
        hasMatch = true;
        matchedContent.add('$currentPersona: ${conversation['assistant']}');
      }

      if (hasMatch) {
        results.add({
          ...conversation,
          'conversationIndex': i + 1,
          'matchedContent': matchedContent,
        });
      }
    }

    setState(() {
      _isSearching = true;
      _filteredConversations = results;
      _currentSearchQuery = query;
    });

    // Show results
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔍 Found ${results.length} conversations containing "$query"'),
        backgroundColor: results.isEmpty ? Colors.orange : const Color(0xFF4A90E2),
        action: results.isEmpty ? null : SnackBarAction(
          label: 'Clear',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _isSearching = false;
              _filteredConversations.clear();
              _currentSearchQuery = '';
            });
          },
        ),
      ),
    );
  }

  // MEMORY MANAGEMENT METHODS
  Future<void> _showAddMemoryDialog() async {
    final memoryController = TextEditingController();
    final categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2332),
        title: const Text('Add Custom Memory', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Color(0xFF8B9DC3)),
                hintText: 'e.g., preferences, goals, facts',
                hintStyle: TextStyle(color: Color(0xFF8B9DC3)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: memoryController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Memory',
                labelStyle: TextStyle(color: Color(0xFF8B9DC3)),
                hintText: 'What should the AI remember about you?',
                hintStyle: TextStyle(color: Color(0xFF8B9DC3)),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addCustomMemory(categoryController.text, memoryController.text);
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );
  }

  Future<void> _addCustomMemory(String category, String memory) async {
    if (category.trim().isEmpty || memory.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final customMemoriesJson = prefs.getString('custom_memories_$currentPersona') ?? '[]';
    final customMemories = List<Map<String, dynamic>>.from(json.decode(customMemoriesJson));
    
    customMemories.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'category': category.trim(),
      'memory': memory.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString('custom_memories_$currentPersona', json.encode(customMemories));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧠 Custom memory added!'),
        backgroundColor: Color(0xFF4A90E2),
      ),
    );
    
    // Refresh the memory data
    _loadMemoryData();
  }

  Future<void> _deleteCustomMemory(Map<String, dynamic> memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2332),
        title: const Text('Delete Custom Memory', style: TextStyle(color: Colors.white)),
        content: const Text('Delete this custom memory?', style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      final prefs = await SharedPreferences.getInstance();
      final customMemoriesJson = prefs.getString('custom_memories_$currentPersona') ?? '[]';
      final customMemories = List<Map<String, dynamic>>.from(json.decode(customMemoriesJson));
      
      customMemories.removeWhere((m) => m['id'] == memory['id']);
      
      await prefs.setString('custom_memories_$currentPersona', json.encode(customMemories));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Custom memory deleted'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {});
      _loadMemoryData(); // Refresh all data
    }
  }

  Future<void> _deleteConversation(Map<String, dynamic> conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2332),
        title: const Text('Delete Conversation', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this conversation?', style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B9DC3))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      setState(() {
        _conversationHistory.remove(conversation);
      });
      await _saveMemoryData();
      _generateMemoryStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Conversation deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2332),
        title: const Text('Delete All Conversations', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently delete ALL conversations. Continue?', style: TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      setState(() => _conversationHistory.clear());
      await _saveMemoryData();
      _generateMemoryStats();
    }
  }

  Future<void> _showResetRelationshipDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2332),
        title: const Text('Reset Relationship', style: TextStyle(color: Colors.white)),
        content: Text('Reset relationship with $currentPersona to Acquaintance level?', style: const TextStyle(color: Color(0xFF8B9DC3))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset', style: TextStyle(color: Colors.orange))),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      setState(() {
        _relationshipData['points'] = 0;
        _relationshipData['level'] = 'Acquaintance';
      });
      await _saveMemoryData();
      _generateMemoryStats();
    }
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📤 Export feature coming soon'), backgroundColor: Colors.blue),
    );
  }

  Future<void> _saveMemoryData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conversation_history_$currentPersona', json.encode(_conversationHistory));
    await prefs.setString('relationship_data_$currentPersona', json.encode(_relationshipData));
  }

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
}