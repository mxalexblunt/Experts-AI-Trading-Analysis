class AssetQuoteModel {
  const AssetQuoteModel({
    required this.symbol,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.previousClose,
    this.timestamp,
  });

  final String symbol;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final double? previousClose;
  final DateTime? timestamp;

  factory AssetQuoteModel.fromJson(Map<String, dynamic> json) {
    return AssetQuoteModel(
      symbol: _readString(json['symbol']).toUpperCase(),
      currentPrice: _readDouble(json['currentPrice']) ?? 0,
      change: _readDouble(json['change']) ?? 0,
      changePercent: _readDouble(json['changePercent']) ?? 0,
      openPrice: _readDouble(json['openPrice']),
      highPrice: _readDouble(json['highPrice']),
      lowPrice: _readDouble(json['lowPrice']),
      previousClose: _readDouble(json['previousClose']),
      timestamp: _readDateTime(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'currentPrice': currentPrice,
      'change': change,
      'changePercent': changePercent,
      if (openPrice != null) 'openPrice': openPrice,
      if (highPrice != null) 'highPrice': highPrice,
      if (lowPrice != null) 'lowPrice': lowPrice,
      if (previousClose != null) 'previousClose': previousClose,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  AssetQuoteModel copyWith({
    String? symbol,
    double? currentPrice,
    double? change,
    double? changePercent,
    double? openPrice,
    double? highPrice,
    double? lowPrice,
    double? previousClose,
    DateTime? timestamp,
    bool clearOpenPrice = false,
    bool clearHighPrice = false,
    bool clearLowPrice = false,
    bool clearPreviousClose = false,
    bool clearTimestamp = false,
  }) {
    return AssetQuoteModel(
      symbol: symbol ?? this.symbol,
      currentPrice: currentPrice ?? this.currentPrice,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      openPrice: clearOpenPrice ? null : openPrice ?? this.openPrice,
      highPrice: clearHighPrice ? null : highPrice ?? this.highPrice,
      lowPrice: clearLowPrice ? null : lowPrice ?? this.lowPrice,
      previousClose:
          clearPreviousClose ? null : previousClose ?? this.previousClose,
      timestamp: clearTimestamp ? null : timestamp ?? this.timestamp,
    );
  }
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

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
