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
      print('🚀 Calling generateLine...');
      print('📝 Task: $task');
      print('🎭 Tone Style: $toneStyle');
      print('🎤 Voice Style: $voiceStyle');
      print('📋 Task Type: $taskType');
      print('🔗 Endpoint: $baseUrl/generate-line');

      // Build the request body with all parameters
      final requestBody = {
        'task': task,
        if (toneStyle != null) 'toneStyle': toneStyle,
        if (voiceStyle != null) 'voiceStyle': voiceStyle,
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
      print('🎤 Calling generateVoice...');
      print('📝 Text: $text');
      print('🎵 Voice Style: $voiceStyle');
      print('🎭 Tone Style: $toneStyle');

      // Build the request body with voice parameters
      final requestBody = {
        'text': text,
        if (voiceStyle != null) 'voiceStyle': voiceStyle,
        if (toneStyle != null) 'toneStyle': toneStyle,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/generate-voice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🌐 Voice Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Voice generated successfully');
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