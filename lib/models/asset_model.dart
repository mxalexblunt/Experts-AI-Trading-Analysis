enum AssetType {
  stock,
  etf,
  unknown,
}

class AssetModel {
  const AssetModel({
    required this.symbol,
    required this.name,
    this.type = AssetType.unknown,
    this.currency = 'USD',
    this.exchange,
    this.logoUrl,
    this.currentPrice,
    this.change,
    this.changePercent,
    this.updatedAt,
  });

  final String symbol;
  final String name;
  final AssetType type;
  final String currency;
  final String? exchange;
  final String? logoUrl;
  final double? currentPrice;
  final double? change;
  final double? changePercent;
  final DateTime? updatedAt;

  bool? get isPositiveChange {
    final value = change ?? changePercent;
    if (value == null) return null;
    return value >= 0;
  }

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      symbol: _readString(json['symbol']).toUpperCase(),
      name: _readString(json['name'], fallback: _readString(json['symbol'])),
      type: parseAssetType(json['type'] as String?),
      currency: _readString(json['currency'], fallback: 'USD'),
      exchange: _nullableString(json['exchange']),
      logoUrl: _nullableString(json['logoUrl']),
      currentPrice: _readDouble(json['currentPrice']),
      change: _readDouble(json['change']),
      changePercent: _readDouble(json['changePercent']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'type': type.name,
      'currency': currency,
      if (exchange != null) 'exchange': exchange,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (currentPrice != null) 'currentPrice': currentPrice,
      if (change != null) 'change': change,
      if (changePercent != null) 'changePercent': changePercent,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  AssetModel copyWith({
    String? symbol,
    String? name,
    AssetType? type,
    String? currency,
    String? exchange,
    String? logoUrl,
    double? currentPrice,
    double? change,
    double? changePercent,
    DateTime? updatedAt,
    bool clearExchange = false,
    bool clearLogoUrl = false,
    bool clearCurrentPrice = false,
    bool clearChange = false,
    bool clearChangePercent = false,
    bool clearUpdatedAt = false,
  }) {
    return AssetModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      exchange: clearExchange ? null : exchange ?? this.exchange,
      logoUrl: clearLogoUrl ? null : logoUrl ?? this.logoUrl,
      currentPrice: clearCurrentPrice ? null : currentPrice ?? this.currentPrice,
      change: clearChange ? null : change ?? this.change,
      changePercent:
          clearChangePercent ? null : changePercent ?? this.changePercent,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
    );
  }
}

AssetType parseAssetType(String? value) {
  final normalized = value?.trim().toLowerCase();
  return switch (normalized) {
    'stock' || 'common stock' || 'equity' => AssetType.stock,
    'etf' || 'etp' || 'exchange traded fund' => AssetType.etf,
    _ => AssetType.unknown,
  };
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
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

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
