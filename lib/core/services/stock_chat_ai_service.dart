import 'app_error.dart';
import 'gemini_service.dart';

class StockChatAiService {
  StockChatAiService({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  final GeminiService _geminiService;

  bool get isConfigured => _geminiService.isConfigured;

  Future<String> ask({
    required String question,
    required List<StockChatTurn> history,
  }) async {
    final sanitizedQuestion = _sanitizeUserText(question);
    final prompt = _prompt(
      question: sanitizedQuestion,
      history: history
          .skip(history.length > 8 ? history.length - 8 : 0)
          .map(
            (turn) => '${turn.isUser ? 'User' : 'Assistant'}: '
                '${_sanitizeUserText(turn.text)}',
          )
          .join('\n'),
    );

    try {
      final response = await _geminiService.generateContent(
        prompt: prompt,
        responseMimeType: null,
        temperature: 0.7,
        maxOutputTokens: null,
      );
      return _cleanResponse(response);
    } on AppError {
      rethrow;
    } catch (error) {
      throw AppError.unavailable(
        'AI chat is temporarily unavailable. Please try again later.',
      );
    }
  }

  String _prompt({
    required String question,
    required String history,
  }) {
    return '''
You are the AI market discussion assistant inside Experts, an educational stock and ETF analysis app.

Rules:
- Keep answers educational and concise.
- Do not provide financial advice.
- Do not tell the user to buy, sell, short, enter, exit, or hold a position.
- Do not provide personalized portfolio advice.
- Do not claim to know live prices, real-time news, or current market conditions unless the user provides that context.
- If the user asks for a ticker view, discuss possible factors, risks, valuation questions, technical context, and what evidence to verify.
- Use plain English and short paragraphs.
- End with a brief educational disclaimer only when the answer discusses a specific asset or strategy.

Recent conversation:
$history

User question: $question
''';
  }

  String _sanitizeUserText(String value) {
    return value
        .trim()
        .replaceAll(
          RegExp(r'\bmy name is [^,.]+', caseSensitive: false),
          'my name is \$USERNAME',
        )
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _cleanResponse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'I could not generate a useful response. Please try rephrasing your question.';
    }
    return trimmed;
  }

  void dispose() {
    _geminiService.dispose();
  }
}

class StockChatTurn {
  const StockChatTurn({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}
