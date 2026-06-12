import 'dart:convert';
import 'dart:io';

import '../core/services/app_error.dart';
import '../models/models.dart';

class FinnhubRepository {
  FinnhubRepository({
    HttpClient? client,
    String apiKey = _defaultApiKey,
    String baseUrl = _baseUrl,
  })  : _client = client ?? HttpClient(),
        _apiKey = apiKey,
        _baseUrlValue = baseUrl;

  static const String _defaultApiKey = String.fromEnvironment(
    'FINNHUB_API_KEY',
    defaultValue: 'd8k91j9r01qjgd6st4q0d8k91j9r01qjgd6st4qg',
  );
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  final HttpClient _client;
  final String _apiKey;
  final String _baseUrlValue;

  bool get isConfigured =>
      _apiKey.trim().isNotEmpty && _apiKey != 'YOUR_FINNHUB_API_KEY';

  Future<List<AssetModel>> searchAssets(String query) async {
    _ensureConfigured();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final json = await _get('/search', {'q': trimmed});
    final result = json['result'];
    if (result is! List) return const [];

    return result.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      final symbol = _readString(data['symbol']).toUpperCase();
      return AssetModel(
        symbol: symbol,
        name: _readString(data['description'], fallback: symbol),
        type: parseAssetType(data['type'] as String?),
        exchange: _readNullableString(data['primaryExchange']),
      );
    }).where((asset) {
      return asset.symbol.isNotEmpty &&
          (asset.type == AssetType.stock || asset.type == AssetType.etf);
    }).toList(growable: false);
  }

  Future<AssetModel> getAssetDetails(String symbol) async {
    _ensureConfigured();
    final normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw const AppError(
        message: 'Ticker symbol is required.',
        type: AppErrorType.invalidData,
      );
    }

    final quote = await _get('/quote', {'symbol': normalized});
    final profile = await _tryGet('/stock/profile2', {'symbol': normalized}) ??
        const <String, dynamic>{};
    final searchAssetJson = await _tryGet('/search', {'q': normalized});
    final searchAsset = searchAssetJson == null
        ? null
        : _assetFromSearchResponse(searchAssetJson, normalized);
    final currentPrice = _readDouble(quote['c']);
    final updatedAt = _readUnixDate(quote['t']) ??
        (currentPrice == null ? null : DateTime.now());
    final profileName = _readNullableString(profile['name']);
    final profileType = profile['finnhubIndustry'] == null
        ? AssetType.unknown
        : AssetType.stock;

    return AssetModel(
      symbol: normalized,
      name: profileName ?? searchAsset?.name ?? normalized,
      type: searchAsset?.type == AssetType.etf
          ? AssetType.etf
          : profileType == AssetType.unknown
              ? searchAsset?.type ?? AssetType.unknown
              : profileType,
      currency: _readString(profile['currency'], fallback: 'USD'),
      exchange: _readNullableString(profile['exchange']) ?? searchAsset?.exchange,
      logoUrl: _readNullableString(profile['logo']),
      currentPrice: currentPrice,
      change: _readDouble(quote['d']),
      changePercent: _readDouble(quote['dp']),
      updatedAt: updatedAt,
    );
  }

  Future<Map<String, dynamic>?> _tryGet(
    String path,
    Map<String, String> query,
  ) async {
    try {
      return await _get(path, query);
    } on AppError {
      return null;
    }
  }

  AssetModel? _assetFromSearchResponse(
    Map<String, dynamic> json,
    String normalizedSymbol,
  ) {
    final result = json['result'];
    if (result is! List) return null;

    for (final item in result.whereType<Map>()) {
      final data = Map<String, dynamic>.from(item);
      final symbol = _readString(data['symbol']).toUpperCase();
      final displaySymbol = _readString(data['displaySymbol']).toUpperCase();
      if (symbol != normalizedSymbol && displaySymbol != normalizedSymbol) {
        continue;
      }

      return AssetModel(
        symbol: symbol.isEmpty ? normalizedSymbol : symbol,
        name: _readString(data['description'], fallback: normalizedSymbol),
        type: parseAssetType(data['type'] as String?),
        exchange: _readNullableString(data['primaryExchange']),
      );
    }

    return null;
  }

  Future<List<ChartPointModel>> getChartData({
    required String symbol,
    required String timeframe,
  }) async {
    _ensureConfigured();
    final now = DateTime.now();
    final from = _fromDate(now, timeframe);
    final resolution = _resolution(timeframe);
    final json = await _get('/stock/candle', {
      'symbol': symbol.trim().toUpperCase(),
      'resolution': resolution,
      'from': '${from.millisecondsSinceEpoch ~/ 1000}',
      'to': '${now.millisecondsSinceEpoch ~/ 1000}',
    });

    if (json['s'] != 'ok') return const [];

    final timestamps = _readList(json['t']);
    final closes = _readList(json['c']);
    final opens = _readList(json['o']);
    final highs = _readList(json['h']);
    final lows = _readList(json['l']);
    final volumes = _readList(json['v']);

    final points = <ChartPointModel>[];
    for (var i = 0; i < timestamps.length && i < closes.length; i += 1) {
      final timestamp = _readDouble(timestamps[i]);
      final close = _readDouble(closes[i]);
      if (timestamp == null || close == null) continue;
      points.add(
        ChartPointModel(
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            timestamp.toInt() * 1000,
          ),
          close: close,
          open: i < opens.length ? _readDouble(opens[i]) : null,
          high: i < highs.length ? _readDouble(highs[i]) : null,
          low: i < lows.length ? _readDouble(lows[i]) : null,
          volume: i < volumes.length ? _readDouble(volumes[i]) : null,
        ),
      );
    }
    return points;
  }

  Future<List<NewsItemModel>> getNews(String symbol) async {
    _ensureConfigured();
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 14));
    final Map<String, dynamic> json;
    try {
      json = await _get('/company-news', {
        'symbol': symbol.trim().toUpperCase(),
        'from': _dateOnly(from),
        'to': _dateOnly(to),
      });
    } on AppError catch (error) {
      if (error.type == AppErrorType.network ||
          error.type == AppErrorType.rateLimited ||
          error.type == AppErrorType.unavailable) {
        return const [];
      }
      rethrow;
    }

    final items = json['items'];
    final sourceList = items is List ? items : json['data'];
    if (sourceList is! List) return const [];

    return sourceList.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      final id = _readString(data['id'], fallback: _readString(data['url']));
      return NewsItemModel(
        id: id,
        headline: _readString(data['headline'], fallback: 'Market update'),
        summary: _readNullableString(data['summary']),
        source: _readNullableString(data['source']),
        url: _readNullableString(data['url']),
        imageUrl: _readNullableString(data['image']),
        publishedAt: _readUnixDate(data['datetime']),
        relatedSymbols: [symbol.trim().toUpperCase()],
      );
    }).toList(growable: false);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final url = Uri.parse('$_baseUrlValue$path').replace(
      queryParameters: {
        ...query,
        'token': _apiKey,
      },
    );

    try {
      final request = await _client.getUrl(url);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decodedError = _decodeErrorBody(body);
        throw AppError(
          message: _statusMessage(response.statusCode, decodedError),
          type: _statusType(response.statusCode, decodedError),
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is List) return {'items': decoded};
      throw const FormatException('Unexpected Finnhub response.');
    } on AppError {
      rethrow;
    } on SocketException catch (error) {
      throw AppError(
        message: 'Network connection failed while contacting market data.',
        type: AppErrorType.network,
        cause: error,
      );
    } on HttpException catch (error) {
      throw AppError(
        message: 'Network connection failed while contacting market data.',
        type: AppErrorType.network,
        cause: error,
      );
    } on FormatException catch (error) {
      throw AppError(
        message: 'Market data response could not be decoded.',
        type: AppErrorType.parsing,
        cause: error,
      );
    }
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw AppError.unavailable(
        'Market data is unavailable until a Finnhub API key is configured.',
      );
    }
  }

  Map<String, dynamic>? _decodeErrorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  String _statusMessage(int statusCode, Map<String, dynamic>? body) {
    final error = _readNullableString(body?['error']);
    if (statusCode == 403 &&
        error != null &&
        error.toLowerCase().contains("don't have access")) {
      return 'This Finnhub plan does not include the requested market data endpoint.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Finnhub authentication failed.';
    }
    if (statusCode == 429) return 'Finnhub rate limit reached.';
    return 'Finnhub request failed.';
  }

  AppErrorType _statusType(int statusCode, Map<String, dynamic>? body) {
    final error = _readNullableString(body?['error']);
    if (statusCode == 403 &&
        error != null &&
        error.toLowerCase().contains("don't have access")) {
      return AppErrorType.unavailable;
    }
    if (statusCode == 401 || statusCode == 403) return AppErrorType.unauthorized;
    if (statusCode == 429) return AppErrorType.rateLimited;
    if (statusCode >= 500) return AppErrorType.unavailable;
    return AppErrorType.unknown;
  }

  DateTime _fromDate(DateTime now, String timeframe) {
    return switch (timeframe.toUpperCase()) {
      '1D' => now.subtract(const Duration(days: 1)),
      '1W' => now.subtract(const Duration(days: 7)),
      '1M' => DateTime(now.year, now.month - 1, now.day),
      '6M' => DateTime(now.year, now.month - 6, now.day),
      '1Y' => DateTime(now.year - 1, now.month, now.day),
      _ => DateTime(now.year, now.month - 1, now.day),
    };
  }

  String _resolution(String timeframe) {
    return switch (timeframe.toUpperCase()) {
      '1D' => '5',
      '1W' => '30',
      _ => 'D',
    };
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<dynamic> _readList(Object? value) {
    return value is List ? value : const [];
  }

  String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  double? _readDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime? _readUnixDate(Object? value) {
    final seconds = _readDouble(value);
    if (seconds == null || seconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
  }

  void dispose() {
    _client.close(force: true);
  }
}
