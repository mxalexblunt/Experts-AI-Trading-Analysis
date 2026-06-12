import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/stock_chat_ai_service.dart';

final stockChatAiServiceProvider = Provider<StockChatAiService>((ref) {
  final service = StockChatAiService();
  ref.onDispose(service.dispose);
  return service;
});
