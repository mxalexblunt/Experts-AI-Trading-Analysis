import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'app_error.dart';
import 'app_log.dart';

class GeminiService {
  GeminiService({
    HttpClient? client,
    String apiKey = _defaultApiKey,
    String textModel = _textModel,
    String baseUrl = _baseUrl,
  })  : _client = client ?? HttpClient(),
        _apiKey = apiKey,
        _textModelName = textModel,
        _baseUrlValue = baseUrl;

  static const String _defaultApiKey = String.fromEnvironment(
    'GOOGLE_API_KEY',
    defaultValue: 'AIzaSyAQQxKv995mcFFIBsBVs2SsBXqQ2tGQ9Zc',
  );
  static const String _textModel = 'gemini-flash-latest';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  final HttpClient _client;
  final String _apiKey;
  final String _textModelName;
  final String _baseUrlValue;

  bool get isConfigured => _apiKey.trim().isNotEmpty && _apiKey != 'YOUR_API_KEY';

  Future<String> generateJson(String prompt) {
    return generateContent(
      prompt: prompt,
      responseMimeType: 'application/json',
      temperature: 0.35,
      maxOutputTokens: 4096,
    );
  }

  Future<String> generateContent({
    required String prompt,
    String? responseMimeType = 'text/plain',
    double temperature = 0.45,
    int? maxOutputTokens = 4096,
  }) async {
    _ensureConfigured();
    final generationConfig = <String, dynamic>{
      'temperature': temperature,
      'maxOutputTokens': ?maxOutputTokens,
      'responseMimeType': ?responseMimeType,
    };
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': generationConfig,
    };

    return _postGenerateContent(
      body,
      operation: 'text-json',
      responseMimeType: responseMimeType,
      hasImage: false,
      maxOutputTokens: maxOutputTokens,
    );
  }

  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String prompt,
    String mimeType = 'image/jpeg',
    String responseMimeType = 'application/json',
  }) async {
    _ensureConfigured();
    final body = {
      'contents': [
        {
          'parts': [
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.35,
        'maxOutputTokens': 4096,
        'responseMimeType': responseMimeType,
      },
    };

    return _postGenerateContent(
      body,
      operation: 'image-json',
      responseMimeType: responseMimeType,
      hasImage: true,
      maxOutputTokens: 4096,
    );
  }

  Future<String> _postGenerateContent(
    Map<String, dynamic> body, {
    required String operation,
    required String? responseMimeType,
    required bool hasImage,
    required int? maxOutputTokens,
  }) async {
    final url = Uri.parse(
      '$_baseUrlValue/$_textModelName:generateContent?key=$_apiKey',
    );
    final encodedBody = utf8.encode(jsonEncode(body));
    final startedAt = DateTime.now();

    AppLog.ai(
      'Gemini request start operation=$operation model=$_textModelName '
      'hasImage=$hasImage responseMimeType=${responseMimeType ?? 'none'} '
      'maxOutputTokens=${maxOutputTokens ?? 'default'}',
    );

    try {
      final request = await _client.postUrl(url);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.add(encodedBody);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLog.ai(
          'Gemini request failed operation=$operation model=$_textModelName '
          'status=${response.statusCode} elapsedMs=$elapsedMs '
          'type=${_statusType(response.statusCode).name} '
          'message="${_statusMessage(response.statusCode)}" '
          'apiError="${_apiErrorPreview(responseBody)}"',
        );
        throw AppError(
          message: _statusMessage(response.statusCode),
          type: _statusType(response.statusCode),
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const AppError(
          message: 'Gemini returned an unexpected response.',
          type: AppErrorType.invalidData,
        );
      }

      final text = _extractText(decoded);
      if (text.trim().isEmpty) {
        AppLog.ai(
          'Gemini returned empty text operation=$operation '
          'status=${response.statusCode} elapsedMs=$elapsedMs '
          'responsePreview="${AppLog.preview(responseBody)}"',
        );
        throw const AppError(
          message: 'Gemini returned an empty response.',
          type: AppErrorType.invalidData,
        );
      }
      AppLog.ai(
        'Gemini request success operation=$operation model=$_textModelName '
        'status=${response.statusCode} elapsedMs=$elapsedMs '
        'textLength=${text.length}',
      );
      return text;
    } on AppError {
      rethrow;
    } on SocketException catch (error) {
      AppLog.ai(
        'Gemini network failure operation=$operation model=$_textModelName',
        error: error,
      );
      throw AppError(
        message: 'Network connection failed while contacting Gemini.',
        type: AppErrorType.network,
        cause: error,
      );
    } on FormatException catch (error) {
      AppLog.ai(
        'Gemini response parsing failure operation=$operation model=$_textModelName',
        error: error,
      );
      throw AppError(
        message: 'Gemini response could not be decoded.',
        type: AppErrorType.parsing,
        cause: error,
      );
    }
  }

  String _extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';

    final first = candidates.first;
    if (first is! Map) return '';

    final content = first['content'];
    if (content is! Map) return '';

    final parts = content['parts'];
    if (parts is! List) return '';

    return parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      AppLog.ai('Gemini configuration missing GOOGLE_API_KEY');
      throw AppError.unavailable(
        'AI service is unavailable until GOOGLE_API_KEY is configured.',
      );
    }
  }

  String _statusMessage(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return 'Gemini authentication failed.';
    }
    if (statusCode == 429) {
      return 'Gemini rate limit reached.';
    }
    return 'Gemini request failed.';
  }

  String _apiErrorPreview(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map) {
          final code = error['code'];
          final status = error['status'];
          final message = error['message'];
          return AppLog.preview(
            'code=$code status=$status message=$message',
            maxLength: 700,
          );
        }
      }
    } on FormatException {
      // Fall through to raw preview.
    }
    return AppLog.preview(responseBody);
  }

  AppErrorType _statusType(int statusCode) {
    if (statusCode == 401 || statusCode == 403) return AppErrorType.unauthorized;
    if (statusCode == 429) return AppErrorType.rateLimited;
    if (statusCode >= 500) return AppErrorType.unavailable;
    return AppErrorType.unknown;
  }

  void dispose() {
    _client.close(force: true);
  }
}
