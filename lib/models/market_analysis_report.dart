import 'analysis_request.dart';
import 'analyst_output.dart';
import 'asset_model.dart';

class MarketAnalysisReport {
  const MarketAnalysisReport({
    required this.id,
    required this.asset,
    required this.request,
    required this.bullCase,
    required this.bearCase,
    required this.centristCase,
    required this.leadConclusion,
    required this.finalSummary,
    this.scenario = MarketScenario.unknown,
    this.keyRisks = const [],
    required this.disclaimer,
    required this.createdAt,
    this.isFallback = false,
  });

  final String id;
  final AssetModel asset;
  final AnalysisRequest request;
  final AnalystOutput bullCase;
  final AnalystOutput bearCase;
  final AnalystOutput centristCase;
  final AnalystOutput leadConclusion;
  final String finalSummary;
  final MarketScenario scenario;
  final List<String> keyRisks;
  final String disclaimer;
  final DateTime createdAt;
  final bool isFallback;

  AnalystOutput get riskAnalysis => centristCase;

  AnalystOutput get consensus => leadConclusion;

  factory MarketAnalysisReport.fromJson(Map<String, dynamic> json) {
    return MarketAnalysisReport(
      id: json['id'] as String? ?? '',
      asset: AssetModel.fromJson(json['asset'] as Map<String, dynamic>? ?? {}),
      request: AnalysisRequest.fromJson(
        json['request'] as Map<String, dynamic>? ?? {},
      ),
      bullCase: AnalystOutput.fromJson(
        _readMap(json['bullCase']),
      ),
      bearCase: AnalystOutput.fromJson(
        _readMap(json['bearCase']),
      ),
      centristCase: AnalystOutput.fromJson(
        _readMap(json['centristCase'] ?? json['riskAnalysis']),
      ),
      leadConclusion: AnalystOutput.fromJson(
        _readMap(json['leadConclusion'] ?? json['consensus']),
      ),
      finalSummary: json['finalSummary'] as String? ?? '',
      scenario: parseMarketScenario(json['scenario'] as String?),
      keyRisks: _readStringList(json['keyRisks']),
      disclaimer: json['disclaimer'] as String? ?? defaultReportDisclaimer,
      createdAt: _readDateTime(json['createdAt']) ?? DateTime.now(),
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset': asset.toJson(),
      'request': request.toJson(),
      'bullCase': bullCase.toJson(),
      'bearCase': bearCase.toJson(),
      'centristCase': centristCase.toJson(),
      'leadConclusion': leadConclusion.toJson(),
      'finalSummary': finalSummary,
      'scenario': scenario.name,
      'keyRisks': keyRisks,
      'disclaimer': disclaimer,
      'createdAt': createdAt.toIso8601String(),
      'isFallback': isFallback,
    };
  }

  MarketAnalysisReport copyWith({
    String? id,
    AssetModel? asset,
    AnalysisRequest? request,
    AnalystOutput? bullCase,
    AnalystOutput? bearCase,
    AnalystOutput? centristCase,
    AnalystOutput? leadConclusion,
    String? finalSummary,
    MarketScenario? scenario,
    List<String>? keyRisks,
    String? disclaimer,
    DateTime? createdAt,
    bool? isFallback,
  }) {
    return MarketAnalysisReport(
      id: id ?? this.id,
      asset: asset ?? this.asset,
      request: request ?? this.request,
      bullCase: bullCase ?? this.bullCase,
      bearCase: bearCase ?? this.bearCase,
      centristCase: centristCase ?? this.centristCase,
      leadConclusion: leadConclusion ?? this.leadConclusion,
      finalSummary: finalSummary ?? this.finalSummary,
      scenario: scenario ?? this.scenario,
      keyRisks: keyRisks ?? this.keyRisks,
      disclaimer: disclaimer ?? this.disclaimer,
      createdAt: createdAt ?? this.createdAt,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}

const defaultReportDisclaimer =
    'Experts does not provide financial advice, trading recommendations, or guarantees of future performance.';

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _readDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
