import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MotivatorApi {
  final String baseUrl = 'https://motivator-ai-backend.onrender.com';
  
  // 🎯 NEW: Extract just the voice name from combined format
  String _extractVoiceName(String? voiceStyle) {
    if (voiceStyle == null) return 'Default Male';
    
    // If it contains ":", extract just the voice name part
    if (voiceStyle.contains(':')) {
      final parts = voiceStyle.split(':');
      if (parts.length >= 2) {
        final voiceName = parts[1].trim();
        print('🎤 Extracted voice name: "$voiceName" from "$voiceStyle"');
        return voiceName;
      }
    }
    
    // Otherwise return as-is
    print('🎤 Using voice as-is: "$voiceStyle"');
    return voiceStyle;
  }
  
  Future<String> generateLine(
    String task, {
    String? toneStyle,
    String? voiceStyle,
    String? taskType,
  }) async {
    try {
      // 🎯 CHANGE: Extract just the voice name for backend
      final extractedVoice = _extractVoiceName(voiceStyle);
      
      print('🚀 Calling generateLine...');
      print('📝 Task: $task');
      print('🎭 Tone Style: $toneStyle');
      print('🎤 Original Voice Style: $voiceStyle');
      print('🎯 Extracted Voice Name: $extractedVoice');
      print('📋 Task Type: $taskType');
      print('🔗 Endpoint: $baseUrl/generate-line');

      // Build the request body with EXTRACTED voice name
      final requestBody = {
        'task': task,
        if (toneStyle != null) 'toneStyle': toneStyle,
        if (extractedVoice.isNotEmpty) 'voiceStyle': extractedVoice, // 🎯 CHANGED: Use extracted name
        if (taskType != null) 'taskType': taskType,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/generate-line'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🌐 Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['line'];
      } else {
        throw Exception('❌ Failed to generate line — HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Full Exception: $e');
      print('🪵 Stack Trace:\n$stackTrace');
      rethrow;
    }
  }

  Future<Uint8List> generateVoice(
    String text, {
    String? voiceStyle,
    String? toneStyle,
  }) async {
    try {
      // 🎯 CHANGE: Extract just the voice name for backend
      final extractedVoice = _extractVoiceName(voiceStyle);
      
      print('🎤 Calling generateVoice...');
      print('📝 Text: $text');
      print('🎵 Original Voice Style: $voiceStyle');
      print('🎯 Extracted Voice Name: $extractedVoice');
      print('🎭 Tone Style: $toneStyle');

      // Build the request body with EXTRACTED voice name
      final requestBody = {
        'text': text,
        if (extractedVoice.isNotEmpty) 'voiceStyle': extractedVoice, // 🎯 CHANGED: Use extracted name
        if (toneStyle != null) 'toneStyle': toneStyle,
      };

      print('📤 Sending to backend: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/generate-voice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🌐 Voice Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Voice generated successfully for: $extractedVoice');
        return response.bodyBytes;
      } else {
        print('❌ Voice generation failed: ${response.body}');
        throw Exception('❌ Failed to generate voice — HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error generating voice: $e');
      print('🪵 Stack trace:\n$stackTrace');
      rethrow;
    }
  }
}