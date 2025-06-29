import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MotivatorApi {
  final String baseUrl = 'https://motivator-ai-backend.onrender.com';
  
  Future<String> generateLine(
    String task, {
    String? toneStyle,
    String? voiceStyle,
    String? taskType,
  }) async {
    try {
      // 🎯 FIXED: Send full voice format to backend (don't extract)
      final fullVoiceStyle = voiceStyle ?? 'male:Default Male';
      
      print('🚀 Calling generateLine...');
      print('📝 Task: $task');
      print('🎭 Tone Style: $toneStyle');
      print('🎤 Original Voice Style: $voiceStyle');
      print('🎯 Full Voice Style: $fullVoiceStyle');
      print('📋 Task Type: $taskType');
      print('🔗 Endpoint: $baseUrl/generate-line');

      // Build the request body with FULL voice format
      final requestBody = {
        'task': task,
        if (toneStyle != null) 'toneStyle': toneStyle,
        if (fullVoiceStyle.isNotEmpty) 'voiceStyle': fullVoiceStyle,
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
      // 🎯 FIXED: Send full voice format to backend (don't extract)
      final fullVoiceStyle = voiceStyle ?? 'male:Default Male';
      
      print('🎤 Calling generateVoice...');
      print('📝 Text: $text');
      print('🎵 Original Voice Style: $voiceStyle');
      print('🎯 Full Voice Style: $fullVoiceStyle');
      print('🎭 Tone Style: $toneStyle');

      // Build the request body with FULL voice format
      final requestBody = {
        'text': text,
        if (fullVoiceStyle.isNotEmpty) 'voiceStyle': fullVoiceStyle,
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
        print('✅ Voice generated successfully for: $fullVoiceStyle');
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