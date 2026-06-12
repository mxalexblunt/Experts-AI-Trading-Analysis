import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/storage_service.dart';
import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(storageServiceProvider));
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repository) : super(AppSettings.defaults()) {
    load();
  }

  final SettingsRepository _repository;

  Future<void> load() async {
    state = await _repository.load();
  }

  Future<void> save(AppSettings settings) async {
    state = settings;
    await _repository.save(settings);
  }

  Future<void> setAiConsent(bool value) {
    return save(state.copyWith(aiConsentGiven: value));
  }

  Future<void> clearAiConsent() {
    return save(state.copyWith(clearAiConsent: true));
  }

  Future<void> setEducationalDisclaimerAccepted(bool value) {
    return save(state.copyWith(educationalDisclaimerAccepted: value));
  }

  Future<void> setDataSourceAttributionAccepted(bool value) {
    return save(state.copyWith(dataSourceAttributionAccepted: value));
  }
}
