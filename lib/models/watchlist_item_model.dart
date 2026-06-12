import 'asset_model.dart';

class WatchlistItemModel {
  const WatchlistItemModel({
    required this.symbol,
    required this.name,
    this.type = AssetType.unknown,
    required this.addedAt,
    this.logoUrl,
    this.lastPrice,
    this.changePercent,
  });

  final String symbol;
  final String name;
  final AssetType type;
  final DateTime addedAt;
  final String? logoUrl;
  final double? lastPrice;
  final double? changePercent;

  factory WatchlistItemModel.fromAsset(
    AssetModel asset, {
    DateTime? addedAt,
  }) {
    return WatchlistItemModel(
      symbol: asset.symbol,
      name: asset.name,
      type: asset.type,
      addedAt: addedAt ?? DateTime.now(),
      logoUrl: asset.logoUrl,
      lastPrice: asset.currentPrice,
      changePercent: asset.changePercent,
    );
  }

  factory WatchlistItemModel.fromJson(Map<String, dynamic> json) {
    return WatchlistItemModel(
      symbol: _readString(json['symbol']).toUpperCase(),
      name: _readString(json['name'], fallback: _readString(json['symbol'])),
      type: parseAssetType(json['type'] as String?),
      addedAt: _readDateTime(json['addedAt']) ?? DateTime.now(),
      logoUrl: _nullableString(json['logoUrl']),
      lastPrice: _readDouble(json['lastPrice']),
      changePercent: _readDouble(json['changePercent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'type': type.name,
      'addedAt': addedAt.toIso8601String(),
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (lastPrice != null) 'lastPrice': lastPrice,
      if (changePercent != null) 'changePercent': changePercent,
    };
  }

  WatchlistItemModel copyWith({
    String? symbol,
    String? name,
    AssetType? type,
    DateTime? addedAt,
    String? logoUrl,
    double? lastPrice,
    double? changePercent,
    bool clearLogoUrl = false,
    bool clearLastPrice = false,
    bool clearChangePercent = false,
  }) {
    return WatchlistItemModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      logoUrl: clearLogoUrl ? null : logoUrl ?? this.logoUrl,
      lastPrice: clearLastPrice ? null : lastPrice ?? this.lastPrice,
      changePercent:
          clearChangePercent ? null : changePercent ?? this.changePercent,
    );
  }
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
  if (value is String) return DateTime.tryParse(value);
  return null;
}
