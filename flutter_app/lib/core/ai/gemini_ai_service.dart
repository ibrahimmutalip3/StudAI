import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'ai_service.dart';

/// Concrete [AIService] backed directly by the Gemini REST API.
///
/// Architecture note: this is the ONLY file in the app that constructs a
/// network request to Gemini. Nothing in `features/*` should ever import
/// `package:http` for AI purposes — everything goes through [AIService].
///
/// Per the product's security requirements: no backend, no proxy. This
/// service calls `generativelanguage.googleapis.com` directly from the
/// device, authenticated with the key injected at build time via
/// [AppConfig.geminiApiKey].
class GeminiAIService implements AIService {
  final http.Client _client;

  GeminiAIService({http.Client? client}) : _client = client ?? http.Client();

  Uri _endpointFor(String model) => Uri.parse(
        '${AppConfig.geminiBaseUrl}/$model:generateContent'
        '?key=${AppConfig.geminiApiKey}',
      );

  void _assertConfigured() {
    if (!AppConfig.hasValidApiKeyConfigured) {
      throw const MissingApiKeyException();
    }
  }

  @override
  Future<AIResponse> generate({
    required String systemPrompt,
    required String userPrompt,
    AIContext? context,
  }) async {
    _assertConfigured();

    final fullUserPrompt = context == null
        ? userPrompt
        : '${context.toPromptBlock()}\n$userPrompt';

    final body = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': fullUserPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.6,
        'maxOutputTokens': 2048,
      },
    };

    final text = await _post(body);
    return AIResponse(text: text, generatedAt: DateTime.now());
  }

  @override
  Future<String> generateStructuredJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    _assertConfigured();

    final body = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 4096,
        'responseMimeType': 'application/json',
      },
    };

    return _post(body);
  }

  @override
  Future<HomeworkRecognitionResult> recognizeHomeworkImage({
    required Uint8List imageBytes,
    required String mimeType,
    AIContext? context,
  }) async {
    _assertConfigured();

    final base64Image = base64Encode(imageBytes);

    final body = {
      'system_instruction': {
        'parts': [
          {'text': _imageRecognitionSystemPrompt(context?.localeCode ?? 'en')}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image}
            },
            {
              'text':
                  'Extract the homework assignment from this image as JSON.'
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1024,
        'responseMimeType': 'application/json',
      },
    };

    final text = await _post(body);
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return HomeworkRecognitionResult(
        subjectGuessKey: (json['subjectGuessKey'] as String?) ?? 'other',
        title: (json['title'] as String?) ?? 'Unrecognized assignment',
        description: (json['description'] as String?) ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      throw AIParsingException(
        'Could not parse homework recognition response: $e',
      );
    }
  }

  String _imageRecognitionSystemPrompt(String localeCode) {
    // Imported lazily to avoid a hard dependency cycle; kept local since
    // this is the only call site needing the raw string outside prompts/.
    return '''
You read a photo of a school homework assignment and extract details as
strict JSON: {"subjectGuessKey": string, "title": string,
"description": string, "confidence": 0.0-1.0}. Read Armenian, Russian,
or English text accurately. Respond only with the JSON object, no
markdown fences, no extra commentary.
''';
  }

  Future<String> _post(Map<String, dynamic> body) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            _endpointFor(AppConfig.geminiModel),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(AppConfig.aiRequestTimeout);
    } on TimeoutException {
      throw const AINetworkException('Request timed out.');
    } catch (e) {
      throw AINetworkException(e.toString());
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AIApiException(response.statusCode, 'Invalid or unauthorized API key.');
    }
    if (response.statusCode == 429) {
      throw AIApiException(response.statusCode, 'Rate limit exceeded.');
    }
    if (response.statusCode >= 500) {
      throw AIApiException(response.statusCode, 'Gemini server error.');
    }
    if (response.statusCode != 200) {
      throw AIApiException(response.statusCode, response.body);
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        final blockReason =
            (json['promptFeedback'] as Map?)?['blockReason'] as String?;
        throw AIParsingException(
          blockReason != null
              ? 'Content was blocked: $blockReason'
              : 'No response candidates returned.',
        );
      }
      final parts = (candidates.first as Map)['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw const AIParsingException('Empty response content.');
      }
      final buffer = StringBuffer();
      for (final part in parts) {
        final t = (part as Map)['text'] as String?;
        if (t != null) buffer.write(t);
      }
      final result = buffer.toString().trim();
      if (result.isEmpty) {
        throw const AIParsingException('Empty response text.');
      }
      return result;
    } on AIParsingException {
      rethrow;
    } catch (e) {
      throw AIParsingException('Failed to parse Gemini response: $e');
    }
  }

  void dispose() => _client.close();
}
