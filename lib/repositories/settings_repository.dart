import '../core/services/storage_service.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._storage);

  static const String _key = 'experts.settings';

  final StorageService _storage;

  Future<AppSettings> load() async {
    final json = await _storage.readJson(_key);
    if (json == null) return AppSettings.defaults();
    return AppSettings.fromJson(json);
  }

  Future<void> save(AppSettings settings) {
    return _storage.writeJson(_key, settings.toJson());
  }

  Future<void> setAiConsent(bool value) async {
    final current = await load();
    await save(current.copyWith(aiConsentGiven: value));
  }

  Future<void> clearAiConsent() async {
    final current = await load();
    await save(current.copyWith(clearAiConsent: true));
  }
}
