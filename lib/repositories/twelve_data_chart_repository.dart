import 'dart:convert';
import 'dart:io';

import '../core/services/app_error.dart';
import '../models/models.dart';

class TwelveDataChartRepository {
  TwelveDataChartRepository({
    HttpClient? client,
    String apiKey = _defaultApiKey,
    String baseUrl = _baseUrl,
  })  : _client = client ?? HttpClient(),
        _apiKey = apiKey,
        _baseUrlValue = baseUrl;

  static const String _defaultApiKey = String.fromEnvironment(
    'TWELVE_DATA_API_KEY',
    defaultValue: 'c2ebd9e712624d64a4f7d3182ca5b070',
  );
  static const String _baseUrl = 'https://api.twelvedata.com';

  final HttpClient _client;
  final String _apiKey;
  final String _baseUrlValue;

  bool get isConfigured =>
      _apiKey.trim().isNotEmpty && _apiKey != 'YOUR_TWELVE_DATA_API_KEY';

  Future<List<ChartPointModel>> getChartData({
    required String symbol,
    required String timeframe,
  }) async {
    _ensureConfigured();

    final json = await _get('/time_series', {
      'symbol': symbol.trim().toUpperCase(),
      'interval': _interval(timeframe),
      'outputsize': '${_outputSize(timeframe)}',
      'order': 'ASC',
    });

    final values = json['values'];
    if (values is! List) return const [];

    return values.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      final timestamp = DateTime.tryParse(_readString(data['datetime'])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final close = _readDouble(data['close']);
      if (close == null) return null;

      return ChartPointModel(
        timestamp: timestamp,
        close: close,
        open: _readDouble(data['open']),
        high: _readDouble(data['high']),
        low: _readDouble(data['low']),
        volume: _readDouble(data['volume']),
      );
    }).whereType<ChartPointModel>().toList(growable: false);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final url = Uri.parse('$_baseUrlValue$path').replace(
      queryParameters: {
        ...query,
        'apikey': _apiKey,
      },
    );

    try {
      final request = await _client.getUrl(url);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        throw const FormatException('Unexpected Twelve Data response.');
      }

      final json = Map<String, dynamic>.from(decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _errorFromResponse(response.statusCode, json);
      }

      if (_readString(json['status']).toLowerCase() == 'error' ||
          json.containsKey('code')) {
        throw _errorFromResponse(
          _readInt(json['code']) ?? response.statusCode,
          json,
        );
      }

      return json;
    } on AppError {
      rethrow;
    } on SocketException catch (error) {
      throw AppError(
        message: 'Network connection failed while contacting chart data.',
        type: AppErrorType.network,
        cause: error,
      );
    } on FormatException catch (error) {
      throw AppError(
        message: 'Chart data response could not be decoded.',
        type: AppErrorType.parsing,
        cause: error,
      );
    }
  }

  AppError _errorFromResponse(int statusCode, Map<String, dynamic> json) {
    final message = _readString(
      json['message'],
      fallback: 'Twelve Data chart request failed.',
    );
    return AppError(
      message: _messageFor(statusCode, message),
      type: _typeFor(statusCode, message),
      statusCode: statusCode,
    );
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw AppError.unavailable(
        'Add a Twelve Data API key to enable chart history.',
      );
    }
  }

  String _messageFor(int statusCode, String message) {
    final normalized = message.toLowerCase();
    if (statusCode == 401 || normalized.contains('api key')) {
      return 'Twelve Data authentication failed.';
    }
    if (statusCode == 429 ||
        normalized.contains('limit') ||
        normalized.contains('credits')) {
      return 'Twelve Data chart rate limit reached.';
    }
    if (normalized.contains('not available') ||
        normalized.contains('not supported')) {
      return 'Chart data is unavailable for this symbol or timeframe.';
    }
    return message;
  }

  AppErrorType _typeFor(int statusCode, String message) {
    final normalized = message.toLowerCase();
    if (statusCode == 401 || normalized.contains('api key')) {
      return AppErrorType.unauthorized;
    }
    if (statusCode == 429 ||
        normalized.contains('limit') ||
        normalized.contains('credits')) {
      return AppErrorType.rateLimited;
    }
    if (statusCode >= 500 ||
        normalized.contains('not available') ||
        normalized.contains('not supported')) {
      return AppErrorType.unavailable;
    }
    return AppErrorType.unknown;
  }

  String _interval(String timeframe) {
    return switch (timeframe.toUpperCase()) {
      '1D' => '5min',
      _ => '1day',
    };
  }

  int _outputSize(String timeframe) {
    return switch (timeframe.toUpperCase()) {
      '1D' => 78,
      '1W' => 8,
      '1M' => 32,
      '6M' => 132,
      '1Y' => 264,
      _ => 32,
    };
  }

  String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  double? _readDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void dispose() {
    _client.close(force: true);
  }
}
