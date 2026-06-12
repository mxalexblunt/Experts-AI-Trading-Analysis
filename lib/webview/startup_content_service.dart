import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../integration/_obf.g.dart';

class StartupContentDecision {
  const StartupContentDecision._(this.url);

  const StartupContentDecision.show(Uri url) : this._(url);

  const StartupContentDecision.none() : this._(null);

  final Uri? url;
}

class StartupContentService {
  const StartupContentService();

  static final firstLinkShownKey = O.webviewFirstLinkShownKey;

  static final Uri _databaseUri = Uri.parse(
    O.webviewDatabaseUrl,
  );
  static const Duration _timeout = Duration(seconds: 5);
  static final String _firstSlot = O.webviewFirstSlot;
  static final String _secondSlot = O.webviewSecondSlot;

  Future<StartupContentDecision> resolve() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final firstLinkShown = preferences.getBool(firstLinkShownKey) ?? false;
      final slot = firstLinkShown ? _secondSlot : _firstSlot;

      final url = await _readSlotUrl(slot);
      if (url == null) {
        return const StartupContentDecision.none();
      }

      if (!firstLinkShown && slot == _firstSlot) {
        await preferences.setBool(firstLinkShownKey, true);
      }

      return StartupContentDecision.show(url);
    } catch (_) {
      return const StartupContentDecision.none();
    }
  }

  Future<Uri?> _readSlotUrl(String slot) async {
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.getUrl(_databaseUri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join().timeout(
            _timeout,
          );
      final decoded = jsonDecode(body);
      final rawUrl = _slotValue(decoded, slot);

      return _validHttpsUrl(rawUrl);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  String? _slotValue(Object? decoded, String slot) {
    if (decoded is List) {
      final index = int.tryParse(slot);
      if (index == null || index < 0 || index >= decoded.length) {
        return null;
      }

      final value = decoded[index];
      return value is String ? value : null;
    }

    if (decoded is Map) {
      final value = decoded[slot];
      return value is String ? value : null;
    }

    return null;
  }

  Uri? _validHttpsUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme != O.webviewHttpsScheme || !uri.hasAuthority) {
      return null;
    }

    return uri;
  }
}
