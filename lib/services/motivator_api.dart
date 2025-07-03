// lib/services/motivator_api.dart - COMPLETE FILE WITH GLOBAL TIMEZONE SUPPORT
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
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

  // 🌍 ENHANCED: Process speech with global timezone support
  Future<Map<String, dynamic>> processSpeech(
    String audioFilePath, {
    int? durationSeconds,
  }) async {
    try {
      print('🎤 Processing speech file: $audioFilePath');
      print('⏱️ Duration: ${durationSeconds ?? 0} seconds');

      // 🌍 NEW: Get user's actual timezone from device
      final now = DateTime.now();
      final localTimeZone = now.timeZoneName; // e.g., "EDT", "PST", "GMT"
      final timeZoneOffset = now.timeZoneOffset; // Duration offset from UTC
      final offsetHours = timeZoneOffset.inHours;
      final offsetMinutes = timeZoneOffset.inMinutes % 60;
      
      // Format timezone offset as "+05:30" or "-04:00"
      final offsetString = '${offsetHours >= 0 ? '+' : ''}${offsetHours.toString().padLeft(2, '0')}:${offsetMinutes.abs().toString().padLeft(2, '0')}';
      
      print('🌍 User timezone: $localTimeZone (UTC$offsetString)');
      print('🌍 Timezone offset: ${timeZoneOffset.inHours} hours from UTC');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process-speech'),
      );

      // Add audio file
      var audioFile = await http.MultipartFile.fromPath(
        'audio',
        audioFilePath,
        filename: 'recording.m4a', // ✅ M4A
      );
      request.files.add(audioFile);

      // Add duration if provided
      if (durationSeconds != null) {
        request.fields['duration'] = durationSeconds.toString();
      }

      // 🌍 NEW: Add timezone information to the request
      request.fields['userTimezone'] = localTimeZone; // e.g., "EDT"
      request.fields['timezoneOffset'] = offsetString; // e.g., "-04:00"
      request.fields['timezoneOffsetHours'] = offsetHours.toString(); // e.g., "-4"

      print('📤 Sending audio file to backend...');
      print('🌍 Sending timezone info: $localTimeZone (UTC$offsetString)');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('🌐 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validate response structure
        if (data['success'] == true && 
            data['transcribedText'] != null && 
            data['extractedData'] != null) {
          
          print('✅ Speech processed successfully!');
          print('📝 Transcribed: ${data['transcribedText']}');
          print('🤖 Extracted: ${data['extractedData']}');
          print('🌍 Timezone context: ${data['processing']?['currentContext']?['userTimezone'] ?? 'Unknown'}');
          
          return {
            'transcribedText': data['transcribedText'],
            'extractedData': data['extractedData'],
            'processing': data['processing'] ?? {},
          };
        } else {
          throw Exception('❌ Invalid response format from backend');
        }
      } else {
        throw Exception('❌ Speech processing failed — HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Error in processSpeech: $e');
      print('🪵 Stack trace:\n$stackTrace');
      rethrow;
    }
  }
}