class ChartPointModel {
  const ChartPointModel({
    required this.timestamp,
    required this.close,
    this.open,
    this.high,
    this.low,
    this.volume,
  });

  final DateTime timestamp;
  final double close;
  final double? open;
  final double? high;
  final double? low;
  final double? volume;

  factory ChartPointModel.fromJson(Map<String, dynamic> json) {
    return ChartPointModel(
      timestamp: _readDateTime(json['timestamp']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      close: _readDouble(json['close']) ?? 0,
      open: _readDouble(json['open']),
      high: _readDouble(json['high']),
      low: _readDouble(json['low']),
      volume: _readDouble(json['volume']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'close': close,
      if (open != null) 'open': open,
      if (high != null) 'high': high,
      if (low != null) 'low': low,
      if (volume != null) 'volume': volume,
    };
  }

  ChartPointModel copyWith({
    DateTime? timestamp,
    double? close,
    double? open,
    double? high,
    double? low,
    double? volume,
    bool clearOpen = false,
    bool clearHigh = false,
    bool clearLow = false,
    bool clearVolume = false,
  }) {
    return ChartPointModel(
      timestamp: timestamp ?? this.timestamp,
      close: close ?? this.close,
      open: clearOpen ? null : open ?? this.open,
      high: clearHigh ? null : high ?? this.high,
      low: clearLow ? null : low ?? this.low,
      volume: clearVolume ? null : volume ?? this.volume,
    );
  }
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
