import 'asset_model.dart';
import 'chart_point_model.dart';
import 'news_item_model.dart';

class AnalysisRequest {
  const AnalysisRequest({
    required this.asset,
    this.timeframe = '1M',
    this.chartPoints = const [],
    this.newsItems = const [],
    this.userNote,
    this.chartImagePath,
    this.chartImageBase64,
    this.chartImageMimeType,
    this.chartObservations,
  });

  final AssetModel asset;
  final String timeframe;
  final List<ChartPointModel> chartPoints;
  final List<NewsItemModel> newsItems;
  final String? userNote;
  final String? chartImagePath;
  final String? chartImageBase64;
  final String? chartImageMimeType;
  final String? chartObservations;

  bool get hasChartImage => chartImageBase64?.isNotEmpty == true;

  factory AnalysisRequest.fromJson(Map<String, dynamic> json) {
    return AnalysisRequest(
      asset: AssetModel.fromJson(json['asset'] as Map<String, dynamic>? ?? {}),
      timeframe: json['timeframe'] as String? ?? '1M',
      chartPoints: _readMapList(json['chartPoints'])
          .map(ChartPointModel.fromJson)
          .toList(growable: false),
      newsItems: _readMapList(json['newsItems'])
          .map(NewsItemModel.fromJson)
          .toList(growable: false),
      userNote: _nullableString(json['userNote']),
      chartImagePath: _nullableString(json['chartImagePath']),
      chartImageBase64: _nullableString(json['chartImageBase64']),
      chartImageMimeType: _nullableString(json['chartImageMimeType']),
      chartObservations: _nullableString(json['chartObservations']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset': asset.toJson(),
      'timeframe': timeframe,
      'chartPoints': chartPoints.map((point) => point.toJson()).toList(),
      'newsItems': newsItems.map((item) => item.toJson()).toList(),
      if (userNote != null) 'userNote': userNote,
      if (chartImagePath != null) 'chartImagePath': chartImagePath,
      if (chartImageBase64 != null) 'chartImageBase64': chartImageBase64,
      if (chartImageMimeType != null) 'chartImageMimeType': chartImageMimeType,
      if (chartObservations != null) 'chartObservations': chartObservations,
    };
  }

  AnalysisRequest copyWith({
    AssetModel? asset,
    String? timeframe,
    List<ChartPointModel>? chartPoints,
    List<NewsItemModel>? newsItems,
    String? userNote,
    String? chartImagePath,
    String? chartImageBase64,
    String? chartImageMimeType,
    String? chartObservations,
    bool clearUserNote = false,
    bool clearChartImage = false,
    bool clearChartObservations = false,
  }) {
    return AnalysisRequest(
      asset: asset ?? this.asset,
      timeframe: timeframe ?? this.timeframe,
      chartPoints: chartPoints ?? this.chartPoints,
      newsItems: newsItems ?? this.newsItems,
      userNote: clearUserNote ? null : userNote ?? this.userNote,
      chartImagePath:
          clearChartImage ? null : chartImagePath ?? this.chartImagePath,
      chartImageBase64:
          clearChartImage ? null : chartImageBase64 ?? this.chartImageBase64,
      chartImageMimeType:
          clearChartImage ? null : chartImageMimeType ?? this.chartImageMimeType,
      chartObservations: clearChartObservations
          ? null
          : chartObservations ?? this.chartObservations,
    );
  }
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
