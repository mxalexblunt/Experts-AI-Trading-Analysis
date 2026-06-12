import 'dart:convert';

import '../app_disclaimers.dart';
import '../../models/models.dart';
import 'app_error.dart';
import 'app_log.dart';
import 'gemini_service.dart';

class MarketAnalysisAiService {
  MarketAnalysisAiService({
    GeminiService? geminiService,
    this.allowFallbackReport = true,
  }) : _geminiService = geminiService ?? GeminiService();

  static const bool _useE2eFakeAi = bool.fromEnvironment(
    'EXPERTS_E2E_FAKE_AI',
  );

  final GeminiService _geminiService;
  final bool allowFallbackReport;

  bool get isConfigured => _useE2eFakeAi || _geminiService.isConfigured;

  Future<AnalystOutput> generateBullCase(AnalysisRequest request) {
    return _generateAnalystOutput(
      request: request,
      role: AnalystRole.bull,
      prompt: _analystPrompt(
        request: request,
        roleName: 'Bull Analyst',
        focus:
            'Explain why the asset could move higher using cautious, educational language.',
      ),
    );
  }

  Future<AnalystOutput> generateBearCase(AnalysisRequest request) {
    return _generateAnalystOutput(
      request: request,
      role: AnalystRole.bear,
      prompt: _analystPrompt(
        request: request,
        roleName: 'Bear Analyst',
        focus:
            'Explain why the asset could weaken using cautious, educational language.',
      ),
    );
  }

  Future<AnalystOutput> generateCentristCase(AnalysisRequest request) {
    return _generateAnalystOutput(
      request: request,
      role: AnalystRole.centrist,
      prompt: _analystPrompt(
        request: request,
        roleName: 'Centrist Analyst',
        focus:
            'Weigh the bull and bear evidence without choosing a side too early. Explain the balanced base case, what could change the interpretation, and the main risks.',
      ),
    );
  }

  Future<AnalystOutput> generateLeadConclusion({
    required AnalysisRequest request,
    required AnalystOutput bullCase,
    required AnalystOutput bearCase,
    required AnalystOutput centristCase,
  }) async {
    final prompt = '''
You are the Lead Analyst for Experts, an educational market-analysis app.
Act like the team lead reviewing three expert memos. Arbitrate the bull, bear, and centrist views into one final educational conclusion.

Rules:
- Do not provide financial advice.
- Do not give direct buy, sell, short, enter, or exit instructions.
- Be cautious and explicit about uncertainty.
- Call out where experts agree, where they conflict, and which risks matter most.
- The disclaimer must say Experts is not affiliated with Finnhub, Twelve Data, or Google Gemini and uses third-party APIs for information and educational analysis.
- Return valid JSON only.

Expected JSON:
{
  "role": "lead",
  "summary": "string",
  "points": ["string", "string", "string"],
  "confidence": 0.0,
  "riskLevel": "low | medium | high",
  "scenario": "bullish | neutral | bearish | mixed",
  "keyRisks": ["string"],
  "disclaimer": "string"
}

Asset context:
${_requestContext(request)}

Bull case:
${jsonEncode(bullCase.toJson())}

Bear case:
${jsonEncode(bearCase.toJson())}

Centrist case:
${jsonEncode(centristCase.toJson())}
''';

    return _generateAnalystOutput(
      request: request,
      role: AnalystRole.lead,
      prompt: prompt,
    );
  }

  Future<MarketAnalysisReport> generateFinalReport(
    AnalysisRequest request,
  ) async {
    AppLog.ai(
      'Report start symbol=${request.asset.symbol} timeframe=${request.timeframe} '
      'chartPoints=${request.chartPoints.length} newsItems=${request.newsItems.length} '
      'hasImage=${request.hasChartImage} hasNote=${request.userNote?.trim().isNotEmpty == true} '
      'configured=$isConfigured allowFallback=$allowFallbackReport fakeAi=$_useE2eFakeAi',
    );
    if (_useE2eFakeAi) {
      AppLog.ai('Report using E2E fake AI fallback symbol=${request.asset.symbol}');
      return _fallbackReport(
        request,
        fallbackReason: 'test AI mode is enabled',
      );
    }

    try {
      AppLog.ai(
        'Expert generation start symbol=${request.asset.symbol} '
        'roles=bull,bear,centrist hasImage=${request.hasChartImage}',
      );
      final expertOutputs = await Future.wait<AnalystOutput>([
        generateBullCase(request),
        generateBearCase(request),
        generateCentristCase(request),
      ]);
      final bullCase = expertOutputs[0];
      final bearCase = expertOutputs[1];
      final centristCase = expertOutputs[2];
      AppLog.ai(
        'Expert generation complete symbol=${request.asset.symbol} '
        'fallbackRoles=${_fallbackRoles([bullCase, bearCase, centristCase])}',
      );
      AppLog.ai('Lead generation start symbol=${request.asset.symbol}');
      final leadConclusion = await generateLeadConclusion(
        request: request,
        bullCase: bullCase,
        bearCase: bearCase,
        centristCase: centristCase,
      );
      final isFallback = [
        bullCase,
        bearCase,
        centristCase,
        leadConclusion,
      ].any((output) => output.isFallback);
      AppLog.ai(
        'Report complete symbol=${request.asset.symbol} '
        'scenario=${leadConclusion.scenario.name} risk=${leadConclusion.riskLevel.name} '
        'isFallback=$isFallback fallbackRoles=${_fallbackRoles([
          bullCase,
          bearCase,
          centristCase,
          leadConclusion,
        ])}',
      );

      return MarketAnalysisReport(
        id: _reportId(request.asset.symbol),
        asset: request.asset,
        request: request,
        bullCase: bullCase,
        bearCase: bearCase,
        centristCase: centristCase,
        leadConclusion: leadConclusion,
        finalSummary: leadConclusion.summary,
        scenario: leadConclusion.scenario,
        keyRisks: leadConclusion.keyRisks,
        disclaimer: _reportDisclaimer(leadConclusion.disclaimer),
        createdAt: DateTime.now(),
        isFallback: isFallback,
      );
    } on AppError catch (error) {
      if (!allowFallbackReport || error.type == AppErrorType.consentRequired) {
        AppLog.ai(
          'Report failed without fallback symbol=${request.asset.symbol} '
          'type=${error.type.name} status=${error.statusCode} message="${error.message}"',
          error: error.cause,
        );
        rethrow;
      }
      AppLog.ai(
        'Report fallback symbol=${request.asset.symbol} '
        'reason=AppError type=${error.type.name} status=${error.statusCode} '
        'message="${error.message}"',
        error: error.cause,
      );
      return _fallbackReport(
        request,
        fallbackReason: _fallbackReasonForAppError(error),
      );
    } on FormatException catch (error) {
      if (!allowFallbackReport) rethrow;
      AppLog.ai(
        'Report fallback symbol=${request.asset.symbol} reason=FormatException',
        error: error,
      );
      return _fallbackReport(
        request,
        fallbackReason: 'the AI response could not be parsed',
      );
    }
  }

  Future<AnalystOutput> _generateAnalystOutput({
    required AnalysisRequest request,
    required AnalystRole role,
    required String prompt,
  }) async {
    String? raw;
    try {
      raw = await _generateJsonForRequest(request, prompt);
      final json = _decodeObject(raw);
      final output = AnalystOutput.fromJson({
        ...json,
        'role': json['role'] ?? role.name,
      });
      AppLog.ai(
        'Analyst output success role=${role.name} '
        'scenario=${output.scenario.name} risk=${output.riskLevel.name} '
        'confidence=${output.confidence ?? 'null'} points=${output.points.length}',
      );
      return output;
    } on AppError catch (error) {
      if (!allowFallbackReport) rethrow;
      AppLog.ai(
        'Analyst output fallback role=${role.name} '
        'reason=AppError type=${error.type.name} status=${error.statusCode} '
        'message="${error.message}"',
        error: error.cause,
      );
      return _fallbackAnalystOutput(
        request,
        role,
        fallbackReason: _fallbackReasonForAppError(error),
      );
    } on FormatException catch (error) {
      if (!allowFallbackReport) rethrow;
      AppLog.ai(
        'Analyst output fallback role=${role.name} reason=FormatException '
        'rawLength=${raw?.length ?? 0} rawPreview="${raw == null ? 'none' : AppLog.preview(raw, maxLength: 500)}"',
        error: error,
      );
      return _fallbackAnalystOutput(
        request,
        role,
        fallbackReason: 'the AI response could not be parsed',
      );
    }
  }

  Future<String> _generateJsonForRequest(
    AnalysisRequest request,
    String prompt,
  ) {
    final base64Image = request.chartImageBase64;
    if (base64Image == null || base64Image.isEmpty) {
      return _geminiService.generateJson(prompt);
    }

    return _geminiService.analyzeImage(
      imageBytes: base64Decode(base64Image),
      mimeType: request.chartImageMimeType ?? 'image/jpeg',
      prompt: '''
$prompt

The uploaded image is user-provided optional visual context. Use it only if it clearly shows market-analysis context such as a stock or ETF chart, candlesticks, a line chart, a TradingView or brokerage chart screen, a ticker watchlist, a financial dashboard, market news, or another trading/stock/ETF-related visual.

If the image shows a pet, person, food, landscape, meme, unrelated screenshot, document, or anything not clearly connected to charts, trading, stocks, ETFs, or market analysis, ignore the image completely. Do not describe it, do not mention that it was ignored, and base the JSON response only on the asset, chart data, news, and user note.

If the image is relevant but unclear, use it only with low confidence and say confidence is limited.
''',
    );
  }

  String _analystPrompt({
    required AnalysisRequest request,
    required String roleName,
    required String focus,
  }) {
    return '''
You are the $roleName for Experts, an educational market-analysis app.
$focus

Rules:
- Do not provide financial advice.
- Do not give direct buy, sell, short, enter, or exit instructions.
- Do not provide price targets or guarantees.
- Admit uncertainty when market data, chart data, or news is incomplete.
- The disclaimer must say Experts is not affiliated with Finnhub, Twelve Data, or Google Gemini and uses third-party APIs for information and educational analysis.
- Return valid JSON only.

Expected JSON:
{
  "role": "${roleName.split(' ').first.toLowerCase()}",
  "summary": "string",
  "points": ["string", "string", "string"],
  "confidence": 0.0,
  "riskLevel": "low | medium | high",
  "scenario": "bullish | neutral | bearish | mixed",
  "keyRisks": ["string"],
  "disclaimer": "string"
}

Asset context:
${_requestContext(request)}
''';
  }

  String _requestContext(AnalysisRequest request) {
    final asset = request.asset;
    final latestPoints = request.chartPoints.length > 12
        ? request.chartPoints.sublist(request.chartPoints.length - 12)
        : request.chartPoints;
    final news = request.newsItems.take(6).map((item) {
      return {
        'headline': item.headline,
        'source': item.source,
        'summary': item.summary,
        'publishedAt': item.publishedAt?.toIso8601String(),
      };
    }).toList(growable: false);

    return jsonEncode({
      'symbol': asset.symbol,
      'name': asset.name,
      'type': asset.type.name,
      'currency': asset.currency,
      'currentPrice': asset.currentPrice,
      'change': asset.change,
      'changePercent': asset.changePercent,
      'timeframe': request.timeframe,
      'userNote': _sanitizeUserText(request.userNote),
      'chartObservations': request.chartObservations,
      'hasUploadedChartImage': request.hasChartImage,
      'recentChartPoints': latestPoints.map((point) => point.toJson()).toList(),
      'news': news,
    });
  }

  Map<String, dynamic> _decodeObject(String raw) {
    final trimmed = _stripCodeFence(raw.trim());
    final diagnostics = <String>[];
    final fullObject = _readJsonObject(
      trimmed,
      label: 'full',
      diagnostics: diagnostics,
    );
    if (fullObject != null) return fullObject;

    final extracted = _firstBalancedJsonObject(trimmed);
    if (extracted != null && extracted != trimmed) {
      final extractedObject = _readJsonObject(
        extracted,
        label: 'extracted',
        diagnostics: diagnostics,
      );
      if (extractedObject != null) return extractedObject;
    }

    final repairSource = extracted ?? trimmed;
    final repaired = _repairJsonObject(repairSource);
    if (repaired != repairSource) {
      final repairedObject = _readJsonObject(
        repaired,
        label: 'repaired',
        diagnostics: diagnostics,
      );
      if (repairedObject != null) return repairedObject;
    }

    throw FormatException(
      'Expected a JSON object. attempts=${diagnostics.join(' | ')} '
      'preview="${AppLog.preview(trimmed)}"',
    );
  }

  Map<String, dynamic>? _readJsonObject(
    String value, {
    required String label,
    required List<String> diagnostics,
  }) {
    if (value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      diagnostics.add('$label decoded ${decoded.runtimeType}');
    } on FormatException catch (error) {
      diagnostics.add('$label ${_jsonErrorLabel(error, value)}');
      return null;
    }
    return null;
  }

  String _jsonErrorLabel(FormatException error, String value) {
    final offset = error.offset == null ? '' : ' offset=${error.offset}';
    final context = error.offset == null
        ? ''
        : ' near="${AppLog.preview(_contextAround(value, error.offset!))}"';
    return '${error.message}$offset$context';
  }

  String _contextAround(String value, int offset) {
    final start = offset - 80 < 0 ? 0 : offset - 80;
    final end = offset + 80 > value.length ? value.length : offset + 80;
    return value.substring(start, end);
  }

  String _repairJsonObject(String value) {
    final withoutTrailingCommas = value.replaceAllMapped(
      RegExp(r',(\s*[}\]])'),
      (match) => match.group(1)!,
    );
    return _escapeInvalidStringCharacters(withoutTrailingCommas);
  }

  String _escapeInvalidStringCharacters(String value) {
    final buffer = StringBuffer();
    var inString = false;

    for (var index = 0; index < value.length; index++) {
      final char = value.codeUnitAt(index);
      if (!inString) {
        if (char == 0x22) inString = true;
        buffer.writeCharCode(char);
        continue;
      }

      if (char == 0x22) {
        if (!_isLikelyClosingJsonQuote(value, index)) {
          buffer.write(r'\"');
          continue;
        }
        inString = false;
        buffer.writeCharCode(char);
        continue;
      }

      if (char == 0x5C) {
        if (index + 1 < value.length &&
            _isSupportedJsonEscape(value.codeUnitAt(index + 1))) {
          buffer
            ..writeCharCode(char)
            ..writeCharCode(value.codeUnitAt(index + 1));
          index++;
        } else {
          buffer.write(r'\\');
        }
        continue;
      }

      if (char == 0x0A) {
        buffer.write(r'\n');
      } else if (char == 0x0D) {
        buffer.write(r'\r');
      } else if (char == 0x09) {
        buffer.write(r'\t');
      } else if (char < 0x20) {
        buffer.write(
          r'\u' + char.toRadixString(16).padLeft(4, '0'),
        );
      } else {
        buffer.writeCharCode(char);
      }
    }

    return buffer.toString();
  }

  bool _isLikelyClosingJsonQuote(String value, int quoteIndex) {
    final next = _nextNonWhitespaceCodeUnit(value, quoteIndex + 1);
    return next == null ||
        next == 0x2C ||
        next == 0x3A ||
        next == 0x5D ||
        next == 0x7D;
  }

  int? _nextNonWhitespaceCodeUnit(String value, int start) {
    for (var index = start; index < value.length; index++) {
      final char = value.codeUnitAt(index);
      if (char != 0x20 && char != 0x0A && char != 0x0D && char != 0x09) {
        return char;
      }
    }
    return null;
  }

  bool _isSupportedJsonEscape(int char) {
    return char == 0x22 ||
        char == 0x2F ||
        char == 0x5C ||
        char == 0x62 ||
        char == 0x66 ||
        char == 0x6E ||
        char == 0x72 ||
        char == 0x74 ||
        char == 0x75;
  }

  String? _firstBalancedJsonObject(String value) {
    final start = value.indexOf('{');
    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var index = start; index < value.length; index++) {
      final char = value.codeUnitAt(index);

      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == 0x5C) {
          escaped = true;
        } else if (char == 0x22) {
          inString = false;
        }
        continue;
      }

      if (char == 0x22) {
        inString = true;
        continue;
      }

      if (char == 0x7B) {
        depth++;
      } else if (char == 0x7D) {
        depth--;
        if (depth == 0) {
          return value.substring(start, index + 1);
        }
      }
    }

    return null;
  }

  String _stripCodeFence(String value) {
    if (!value.startsWith('```')) return value;
    return value
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  String? _sanitizeUserText(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text.replaceAll(RegExp(r'\bmy name is [^,.]+', caseSensitive: false),
        'my name is \$USERNAME');
  }

  String _reportDisclaimer(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return defaultReportDisclaimer;
    if (text.contains('not affiliated') &&
        text.contains('Finnhub') &&
        text.contains('Twelve Data')) {
      return text;
    }
    return '$text ${AppDisclaimers.thirdPartyApiNotice}';
  }

  MarketAnalysisReport _fallbackReport(
    AnalysisRequest request, {
    String fallbackReason = 'AI report generation did not complete',
  }) {
    final bullCase = _fallbackAnalystOutput(
      request,
      AnalystRole.bull,
      fallbackReason: fallbackReason,
    );
    final bearCase = _fallbackAnalystOutput(
      request,
      AnalystRole.bear,
      fallbackReason: fallbackReason,
    );
    final centristCase = _fallbackAnalystOutput(
      request,
      AnalystRole.centrist,
      fallbackReason: fallbackReason,
    );
    final leadConclusion = _fallbackAnalystOutput(
      request,
      AnalystRole.lead,
      fallbackReason: fallbackReason,
    );

    return MarketAnalysisReport(
      id: _reportId(request.asset.symbol),
      asset: request.asset,
      request: request,
      bullCase: bullCase,
      bearCase: bearCase,
      centristCase: centristCase,
      leadConclusion: leadConclusion,
      finalSummary: leadConclusion.summary,
      scenario: MarketScenario.mixed,
      keyRisks: leadConclusion.keyRisks,
      disclaimer: defaultReportDisclaimer,
      createdAt: DateTime.now(),
      isFallback: true,
    );
  }

  AnalystOutput _fallbackAnalystOutput(
    AnalysisRequest request,
    AnalystRole role,
    {
    String fallbackReason = 'AI analysis could not be completed',
  }) {
    final symbol = request.asset.symbol;
    return switch (role) {
      AnalystRole.bull => AnalystOutput(
          role: role,
          summary:
              '$symbol may have constructive factors, but this expert view is limited because $fallbackReason.',
          points: const [
            'Review price trend, relative strength, and recent news before forming a view.',
            'Positive momentum can fade quickly when broader market conditions change.',
            'Use this as educational context only.',
          ],
          confidence: 0.2,
          riskLevel: RiskLevel.unknown,
          scenario: MarketScenario.mixed,
          disclaimer: defaultReportDisclaimer,
          isFallback: true,
        ),
      AnalystRole.bear => AnalystOutput(
          role: role,
          summary:
              '$symbol may have downside factors, but this expert view is limited because $fallbackReason.',
          points: const [
            'Watch for weak momentum, negative headlines, and broad market pressure.',
            'Incomplete data limits confidence in any downside interpretation.',
            'Avoid treating this fallback as a trading signal.',
          ],
          confidence: 0.2,
          riskLevel: RiskLevel.unknown,
          scenario: MarketScenario.mixed,
          disclaimer: defaultReportDisclaimer,
          isFallback: true,
        ),
      AnalystRole.centrist => AnalystOutput(
          role: role,
          summary:
              'The balanced view is limited because $fallbackReason.',
          points: const [
            'Consider both constructive and cautious interpretations.',
            'Volatility, news uncertainty, and upcoming events may affect the asset.',
            'Thin or incomplete data can make chart interpretation less reliable.',
          ],
          confidence: 0.2,
          riskLevel: RiskLevel.unknown,
          scenario: MarketScenario.mixed,
          keyRisks: const [
            'News uncertainty',
            'Market-wide volatility',
          ],
          disclaimer: defaultReportDisclaimer,
          isFallback: true,
        ),
      AnalystRole.lead => AnalystOutput(
          role: role,
          summary: 'Lead analyst review is limited because $fallbackReason.',
          points: const [
            'The bull, bear, and centrist cases should be reviewed together.',
            'Wait for complete market data before drawing strong conclusions.',
            'This fallback is educational context only.',
          ],
          confidence: 0.2,
          riskLevel: RiskLevel.unknown,
          scenario: MarketScenario.mixed,
          keyRisks: [
            fallbackReason,
            'Some expert output may be incomplete',
          ],
          disclaimer: defaultReportDisclaimer,
          isFallback: true,
        ),
    };
  }

  String _reportId(String symbol) {
    return '${symbol.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _fallbackRoles(List<AnalystOutput> outputs) {
    final roles = outputs
        .where((output) => output.isFallback)
        .map((output) => output.role.name)
        .toList(growable: false);
    return roles.isEmpty ? 'none' : roles.join(',');
  }

  String _fallbackReasonForAppError(AppError error) {
    return switch (error.type) {
      AppErrorType.unavailable => 'the AI service is unavailable',
      AppErrorType.network => 'the AI network request failed',
      AppErrorType.unauthorized => 'Gemini authentication failed',
      AppErrorType.rateLimited => 'Gemini rate limit was reached',
      AppErrorType.invalidData => 'Gemini returned invalid data',
      AppErrorType.parsing => 'the Gemini response could not be decoded',
      AppErrorType.consentRequired => 'AI consent is required',
      AppErrorType.unknown => 'the AI request failed',
    };
  }
}
