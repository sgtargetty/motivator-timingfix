// lib/screens/learning_debug_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/simple_learning_service.dart';
import '../services/authentic_tone_detection.dart';
import '../services/hybrid_tone_detection.dart';

class LearningDebugScreen extends StatefulWidget {
  const LearningDebugScreen({Key? key}) : super(key: key);

  @override
  _LearningDebugScreenState createState() => _LearningDebugScreenState();
}

class _LearningDebugScreenState extends State<LearningDebugScreen> {
  Map<String, dynamic> _learningStats = {};
  final TextEditingController _testResponseController = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic> _lastHybridAnalysis = {};

  @override
  void initState() {
    super.initState();
    _loadLearningStats();
  }

  @override
  void dispose() {
    _testResponseController.dispose();
    super.dispose();
  }

  Future<void> _loadLearningStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final stats = await SimpleLearningService.getLearningStats();
      if (mounted) {
        setState(() {
          _learningStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testResponse(String response) async {
    if (response.trim().isEmpty) return;
    
    try {
      // 🎭 Show immediate HYBRID tone analysis
      final hybridAnalysis = HybridToneDetection.analyzeHybridTones(response);
      
      if (mounted) {
        setState(() {
          _lastHybridAnalysis = hybridAnalysis;
        });
      }
      
      // Learn from response
      await SimpleLearningService.learnFromResponse(response);
      _testResponseController.clear();
      await _loadLearningStats();
      
      // Show hybrid results
      if (mounted) {
        _showAnalysisDialog(response, hybridAnalysis);
      }
    } catch (e) {
      print('Error analyzing response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing response: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAnalysisDialog(String response, Map<String, dynamic> hybridAnalysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F2E),
        title: Text('🎭 HYBRID Tone Analysis', style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Response: "$response"', 
                     style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                SizedBox(height: 12),
                Text('Analysis: ${HybridToneDetection.getHybridAnalysisString(hybridAnalysis)}',
                     style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                if (hybridAnalysis['type'] == 'hybrid') ...[
                  Text('🎯 Detected Blend:', style: TextStyle(color: Colors.white)),
                  SizedBox(height: 4),
                  if (hybridAnalysis['hybrid'] != null) ...[
                    Text('Name: ${hybridAnalysis['hybrid']['name']}',
                         style: TextStyle(color: Color(0xFFD4AF37))),
                    Text('Description: ${hybridAnalysis['hybrid']['description']}',
                         style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 8),
                  ],
                  Text('🔥 Component Tones:', style: TextStyle(color: Colors.white)),
                  if (hybridAnalysis['significantTones'] != null)
                    ...((hybridAnalysis['significantTones'] as List<dynamic>).map((tone) => 
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text('${_getToneDisplayName(tone['tone'])}: ${tone['score']}',
                                   style: TextStyle(color: Colors.white70)),
                      ))),
                ] else ...[
                  Text('Single Tone Detected:', style: TextStyle(color: Colors.white)),
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('${_getToneDisplayName(hybridAnalysis['primary'])}',
                               style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Roger that! 🎖️', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  Future<void> _resetLearning() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1F2E),
        title: Text('Reset Learning Data?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will clear all learned patterns and tone profiles. Start fresh?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SimpleLearningService.resetLearningData();
                Navigator.pop(context);
                await _loadLearningStats();
                if (mounted) {
                  setState(() => _lastHybridAnalysis = {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔄 Learning data reset - ready for fresh hybrid analysis!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print('Error resetting data: $e');
                Navigator.pop(context);
              }
            },
            child: Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1F2E),
        title: Text('🎭 HYBRID AI Learning Debug'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLearningStats,
          ),
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _resetLearning,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  SizedBox(height: 16),
                  Text('Loading hybrid analysis...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildOverallProfile()),
                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(child: _buildTestSection()),
                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(child: _buildToneFrequencies()),
                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(child: _buildRecentAnalysis()),
                    SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(child: _buildDetailedStats()),
                    SliverToBoxAdapter(child: SizedBox(height: 40)), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallProfile() {
    final hasData = _learningStats['hasEnoughData'] ?? false;
    final primaryTone = _learningStats['primaryTone'] ?? 'unknown';
    final hybridBlend = _learningStats['hybridBlend'];
    final confidence = _learningStats['toneConfidence'] ?? 'unknown';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎭 YOUR HYBRID COMMUNICATION PROFILE',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (hasData) ...[
            if (hybridBlend != null) ...[
              _buildProfileRow('🔥 Dominant Blend', _getHybridDisplayName(hybridBlend)),
              _buildProfileRow('Primary Fallback', _getToneDisplayName(primaryTone)),
            ] else ...[
              _buildProfileRow('Primary Style', _getToneDisplayName(primaryTone)),
            ],
            _buildProfileRow('Confidence', confidence.toUpperCase()),
            _buildProfileRow('Conversations', '${_learningStats['conversationCount']}'),
            if (_learningStats['hybridProfile'] != null)
              _buildProfileRow('Hybrid Combos', '${_learningStats['hybridProfile']['totalCombos']}'),
          ] else ...[
            Text(
              'Need ${3 - (_learningStats['conversationCount'] ?? 0)} more conversations for hybrid analysis',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.white70)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value, 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 TEST TONE DETECTION',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _testResponseController,
            style: TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Try hybrid: "Roger that bro, the algorithmic approach is fire!" or "¡Órale! Mission accomplished, no cap!"',
              hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFFD4AF37)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFFD4AF37).withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFFD4AF37)),
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _testResponse(_testResponseController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('🎯 Analyze Tone', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_lastHybridAnalysis.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last Analysis:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  if (_lastHybridAnalysis['type'] == 'hybrid') ...[
                    Text(
                      '${HybridToneDetection.getHybridAnalysisString(_lastHybridAnalysis)}',
                      style: TextStyle(color: Color(0xFFD4AF37)),
                    ),
                    SizedBox(height: 4),
                    if (_lastHybridAnalysis['significantTones'] != null)
                      ...(_lastHybridAnalysis['significantTones'] as List<dynamic>).map((tone) =>
                        Padding(
                          padding: EdgeInsets.only(left: 16, top: 2),
                          child: Text(
                            '• ${_getToneDisplayName(tone['tone'])}: ${tone['score']}',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        )),
                  ] else ...[
                    Text(
                      'Single: ${_getToneDisplayName(_lastHybridAnalysis['primary'])}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToneFrequencies() {
    final frequencies = _learningStats['toneFrequencies'] as Map<String, dynamic>? ?? {};
    final hybridFreqs = _learningStats['hybridFrequencies'] as Map<String, dynamic>? ?? {};
    
    if (frequencies.isEmpty && hybridFreqs.isEmpty) return Container();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 TONE & HYBRID FREQUENCY BREAKDOWN',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (hybridFreqs.isNotEmpty) ...[
            Text('🔥 Hybrid Patterns:', style: TextStyle(color: Color(0xFFD4AF37))),
            SizedBox(height: 8),
            ...hybridFreqs.entries.map((entry) {
              final percentage = (_learningStats['conversationCount'] > 0)
                  ? (entry.value / _learningStats['conversationCount'] * 100).round()
                  : 0;
              return Padding(
                padding: EdgeInsets.only(bottom: 6, left: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(_getHybridDisplayName(entry.key), 
                           style: TextStyle(color: Color(0xFFD4AF37))),
                    ),
                    Text('${entry.value} (${percentage}%)', 
                         style: TextStyle(color: Color(0xFFD4AF37))),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 12),
          ],
          if (frequencies.isNotEmpty) ...[
            Text('🎭 Individual Tones:', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            ...frequencies.entries.map((entry) {
              final percentage = (_learningStats['conversationCount'] > 0)
                  ? (entry.value / _learningStats['conversationCount'] * 100).round()
                  : 0;
              return Padding(
                padding: EdgeInsets.only(bottom: 6, left: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(_getToneDisplayName(entry.key), 
                           style: TextStyle(color: Colors.white70)),
                    ),
                    Text('${entry.value} (${percentage}%)', 
                         style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentAnalysis() {
    final recentTones = _learningStats['recentTones'] as List<dynamic>? ?? [];
    if (recentTones.isEmpty) return Container();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔄 RECENT CONVERSATION TONES',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...recentTones.reversed.take(5).map((tone) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conversation #${tone['conversation']}',
                     style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (tone['type'] == 'hybrid' && tone['hybrid'] != null)
                        Text('🔥 ${tone['hybrid']}',
                             style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12))
                      else
                        Text('${_getToneDisplayName(tone['primary'])}',
                             style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text('${((tone['confidence'] ?? 0.0) * 100).round()}% conf',
                           style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 DETAILED ANALYTICS',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildDetailRow('Total Conversations', '${_learningStats['conversationCount']}'),
          _buildDetailRow('Average Response Length', 
                         '${(_learningStats['averageResponseLength'] ?? 0).round()} chars'),
          _buildDetailRow('Profile Confidence', _learningStats['toneConfidence'] ?? 'Unknown'),
          _buildDetailRow('Data Status', 
                         _learningStats['hasEnoughData'] ? '✅ Ready for personalization' : '⏳ Still learning'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.white70)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value, 
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getToneDisplayName(String toneKey) {
    final toneNames = {
      'nerdy': '🤓 Nerdy/Academic',
      'street': '🗣️ Street/Urban',
      'latin': '🌮 Latin Colloquial',
      'southern': '🤠 Southern Eccentric',
      'theatrical': '🎭 Theatrical/Dramatic',
      'finance_bro': '💰 Finance Bro',
      'gamer': '🎮 Gamer/Internet',
      'spiritual': '🧘 Spiritual/Wellness',
      'gen_z': '🔥 Gen Z Core',
      'military': '🎖️ Trained Soldier',
      'neutral': '⚖️ Neutral/Balanced'
    };
    return toneNames[toneKey] ?? toneKey;
  }

  String _getHybridDisplayName(String hybridKey) {
    final hybridNames = {
      'military_street': '🎖️🗣️ Military Hood',
      'nerdy_street': '🤓🗣️ Smart Street',
      'military_nerdy': '🎖️🤓 Tactical Scholar',
      'military_southern': '🎖️🤠 Country Soldier',
      'street_gen_z': '🗣️🔥 Urban Gen Z',
      'military_gamer': '🎖️🎮 Tactical Gamer',
      'nerdy_theatrical': '🤓🎭 Dramatic Scholar',
      'street_finance_bro': '🗣️💰 Hood Entrepreneur',
      'military_street_nerdy': '🎖️🗣️🤓 Scholar Warrior Hood',
    };
    
    if (hybridNames.containsKey(hybridKey)) {
      return hybridNames[hybridKey]!;
    }
    
    // Handle custom hybrids
    if (hybridKey.startsWith('custom_')) {
      final parts = hybridKey.replaceFirst('custom_', '').split('_');
      return parts.map((p) => _getToneDisplayName(p).split(' ').first).join(' + ');
    }
    
    return hybridKey;
  }
}