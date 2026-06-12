import 'package:experts/core/services/gemini_service.dart';
import 'package:experts/core/services/market_analysis_ai_service.dart';
import 'package:experts/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recovers a valid JSON object when Gemini appends trailing prose', () async {
    final service = MarketAnalysisAiService(
      geminiService: _FakeGeminiService([
        _analystJson('bull'),
        '${_analystJson('bear')}\nresults."',
        _analystJson('centrist'),
        '${_analystJson('lead')}\nresults."',
      ]),
    );

    final report = await service.generateFinalReport(
      AnalysisRequest(asset: _asset()),
    );

    expect(report.isFallback, isFalse);
    expect(report.bearCase.isFallback, isFalse);
    expect(report.leadConclusion.isFallback, isFalse);
    expect(report.leadConclusion.summary, 'lead summary');
  });

  test('repairs common LLM JSON syntax before falling back', () async {
    final service = MarketAnalysisAiService(
      geminiService: _FakeGeminiService([
        _almostJson('bull'),
        _analystJson('bear'),
        _almostJson('centrist'),
        _almostJson('lead'),
      ]),
    );

    final report = await service.generateFinalReport(
      AnalysisRequest(asset: _asset()),
    );

    expect(report.isFallback, isFalse);
    expect(report.bullCase.isFallback, isFalse);
    expect(report.centristCase.isFallback, isFalse);
    expect(report.leadConclusion.isFallback, isFalse);
    expect(report.bullCase.summary, contains('line two'));
  });
}

class _FakeGeminiService extends GeminiService {
  _FakeGeminiService(this._responses) : super(apiKey: 'test-key');

  final List<String> _responses;
  int _index = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<String> generateJson(String prompt) async {
    if (_index >= _responses.length) {
      throw StateError('No fake Gemini response left.');
    }
    return _responses[_index++];
  }
}

AssetModel _asset() {
  return const AssetModel(
    symbol: 'AAPL',
    name: 'Apple Inc',
    type: AssetType.stock,
    currency: 'USD',
    currentPrice: 295.63,
    change: 4.05,
    changePercent: 1.39,
  );
}

String _analystJson(String role) {
  final scenario = switch (role) {
    'bull' => 'bullish',
    'bear' => 'bearish',
    _ => 'mixed',
  };
  return '''
{
  "role": "$role",
  "summary": "$role summary",
  "points": ["Point one", "Point two", "Point three"],
  "confidence": 0.6,
  "riskLevel": "medium",
  "scenario": "$scenario",
  "keyRisks": ["Risk one"],
  "disclaimer": "Educational context only."
}
''';
}

String _almostJson(String role) {
  final scenario = switch (role) {
    'bull' => 'bullish',
    'bear' => 'bearish',
    _ => 'mixed',
  };
  return '''
{
  "role": "$role",
  "summary": "$role summary line one
line two",
  "points": ["Point one", "Point two", "Point three",],
  "confidence": 0.6,
  "riskLevel": "medium",
  "scenario": "$scenario",
  "keyRisks": ["Risk one",],
  "disclaimer": "Educational context only, not a "buy" or "sell" recommendation.",
}
''';
}
