// lib/screens/learning_debug_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/simple_learning_service.dart';

class LearningDebugScreen extends StatefulWidget {
  const LearningDebugScreen({Key? key}) : super(key: key);

  @override
  _LearningDebugScreenState createState() => _LearningDebugScreenState();
}

class _LearningDebugScreenState extends State<LearningDebugScreen> {
  Map<String, dynamic> _learningStats = {};
  final TextEditingController _testResponseController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLearningStats();
  }

  Future<void> _loadLearningStats() async {
    setState(() => _isLoading = true);
    final stats = await SimpleLearningService.getLearningStats();
    setState(() {
      _learningStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _testResponse(String response) async {
    if (response.trim().isEmpty) return;
    
    await SimpleLearningService.learnFromResponse(response);
    _testResponseController.clear();
    await _loadLearningStats();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Response analyzed and learned!'),
        backgroundColor: Color(0xFFD4AF37),
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
          'This will clear all learned patterns and start fresh.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await SimpleLearningService.resetLearningData();
              Navigator.pop(context);
              await _loadLearningStats();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Learning data reset!'),
                  backgroundColor: Colors.red,
                ),
              );
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
        title: Text('🧠 AI Learning Debug'),
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
          ? Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTestInput(),
                  SizedBox(height: 24),
                  _buildStatsCard(),
                  SizedBox(height: 16),
                  _buildPatternAnalysis(),
                  SizedBox(height: 16),
                  _buildPersonalizationStatus(),
                  SizedBox(height: 16),
                  _buildExamplePrompt(),
                ],
              ),
            ),
    );
  }

  Widget _buildTestInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFD4AF37).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 Test Response Input',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Type test responses to see how the AI learns:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _testResponseController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Try: "Great! Had an amazing time!" or "yeah, was ok"',
                    hintStyle: TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _testResponse,
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Color(0xFFD4AF37)),
                onPressed: () => _testResponse(_testResponseController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final conversationCount = _learningStats['conversationCount'] ?? 0;
    final avgLength = (_learningStats['averageResponseLength'] ?? 0.0).toStringAsFixed(1);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD4AF37).withOpacity(0.1),
            Color(0xFF1A1F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Learning Statistics',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildStatRow('Total Conversations', conversationCount.toString()),
          _buildStatRow('Average Response Length', '$avgLength chars'),
          _buildStatRow('Enthusiastic Responses', '${_learningStats['enthusiasticResponses'] ?? 0}'),
          _buildStatRow('Casual Responses', '${_learningStats['casualResponses'] ?? 0}'),
          _buildStatRow('Short Responses', '${_learningStats['shortResponses'] ?? 0}'),
          _buildStatRow('Detailed Responses', '${_learningStats['detailedResponses'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternAnalysis() {
    final conversationCount = _learningStats['conversationCount'] ?? 0;
    final enthusiasticCount = _learningStats['enthusiasticResponses'] ?? 0;
    final casualCount = _learningStats['casualResponses'] ?? 0;
    
    final enthusiasticPercent = conversationCount > 0 
        ? (enthusiasticCount / conversationCount * 100).toStringAsFixed(0)
        : '0';
    final casualPercent = conversationCount > 0
        ? (casualCount / conversationCount * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎭 Communication Pattern Analysis',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildPercentageBar('Enthusiastic', double.parse(enthusiasticPercent), Colors.orange),
          SizedBox(height: 12),
          _buildPercentageBar('Casual', double.parse(casualPercent), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildPercentageBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white70)),
            Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(color: Colors.white)),
          ],
        ),
        SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizationStatus() {
    final hasEnoughData = _learningStats['hasEnoughData'] ?? false;
    final preferredTone = _learningStats['preferredTone'] ?? 'unknown';
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasEnoughData 
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasEnoughData 
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasEnoughData ? Icons.check_circle : Icons.info,
                color: hasEnoughData ? Colors.green : Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                hasEnoughData 
                    ? '✅ Personalization Active'
                    : '⏳ Learning in Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            hasEnoughData
                ? 'AI has learned your communication style!'
                : 'Need ${3 - (_learningStats['conversationCount'] ?? 0)} more conversations',
            style: TextStyle(color: Colors.white70),
          ),
          if (hasEnoughData) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFD4AF37).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Preferred Tone: ${preferredTone.toUpperCase()}',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamplePrompt() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Example Personalized Prompt',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          FutureBuilder<String>(
            future: SimpleLearningService.generatePersonalizedPrompt(
              'Check in about a medical appointment',
              'medical',
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator(color: Color(0xFFD4AF37));
              }
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  snapshot.data!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _testResponseController.dispose();
    super.dispose();
  }
}