enum AnalystRole {
  bull,
  bear,
  centrist,
  lead,
}

enum RiskLevel {
  low,
  medium,
  high,
  unknown,
}

enum MarketScenario {
  bullish,
  neutral,
  bearish,
  mixed,
  unknown,
}

class AnalystOutput {
  const AnalystOutput({
    required this.role,
    required this.summary,
    this.points = const [],
    this.confidence,
    this.riskLevel = RiskLevel.unknown,
    this.scenario = MarketScenario.unknown,
    this.keyRisks = const [],
    this.disclaimer,
    this.isFallback = false,
  });

  final AnalystRole role;
  final String summary;
  final List<String> points;
  final double? confidence;
  final RiskLevel riskLevel;
  final MarketScenario scenario;
  final List<String> keyRisks;
  final String? disclaimer;
  final bool isFallback;

  factory AnalystOutput.fromJson(Map<String, dynamic> json) {
    return AnalystOutput(
      role: parseAnalystRole(json['role'] as String?),
      summary: _readString(json['summary']),
      points: _readStringList(json['points']),
      confidence: _readDouble(json['confidence']),
      riskLevel: parseRiskLevel(json['riskLevel'] as String?),
      scenario: parseMarketScenario(json['scenario'] as String?),
      keyRisks: _readStringList(json['keyRisks']),
      disclaimer: _nullableString(json['disclaimer']),
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'summary': summary,
      'points': points,
      if (confidence != null) 'confidence': confidence,
      'riskLevel': riskLevel.name,
      'scenario': scenario.name,
      'keyRisks': keyRisks,
      if (disclaimer != null) 'disclaimer': disclaimer,
      'isFallback': isFallback,
    };
  }

  AnalystOutput copyWith({
    AnalystRole? role,
    String? summary,
    List<String>? points,
    double? confidence,
    RiskLevel? riskLevel,
    MarketScenario? scenario,
    List<String>? keyRisks,
    String? disclaimer,
    bool? isFallback,
    bool clearConfidence = false,
    bool clearDisclaimer = false,
  }) {
    return AnalystOutput(
      role: role ?? this.role,
      summary: summary ?? this.summary,
      points: points ?? this.points,
      confidence: clearConfidence ? null : confidence ?? this.confidence,
      riskLevel: riskLevel ?? this.riskLevel,
      scenario: scenario ?? this.scenario,
      keyRisks: keyRisks ?? this.keyRisks,
      disclaimer: clearDisclaimer ? null : disclaimer ?? this.disclaimer,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}

AnalystRole parseAnalystRole(String? value) {
  final normalized = value
      ?.trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_-]+'), '');
  return switch (normalized) {
    'bull' || 'bullcase' || 'bullanalyst' => AnalystRole.bull,
    'bear' || 'bearcase' || 'bearanalyst' => AnalystRole.bear,
    'centrist' ||
    'centristcase' ||
    'centristanalyst' ||
    'neutral' ||
    'risk' ||
    'riskanalysis' ||
    'riskanalyst' =>
      AnalystRole.centrist,
    'lead' ||
    'leadanalyst' ||
    'teamlead' ||
    'consensus' ||
    'consensusanalyst' ||
    'arbiter' ||
    'arbitrator' =>
      AnalystRole.lead,
    _ => AnalystRole.lead,
  };
}

RiskLevel parseRiskLevel(String? value) {
  return RiskLevel.values.firstWhere(
    (level) => level.name == value?.trim().toLowerCase(),
    orElse: () => RiskLevel.unknown,
  );
}

MarketScenario parseMarketScenario(String? value) {
  return MarketScenario.values.firstWhere(
    (scenario) => scenario.name == value?.trim().toLowerCase(),
    orElse: () => MarketScenario.unknown,
  );
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

double? _readDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
