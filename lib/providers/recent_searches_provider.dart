import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset_model.dart';
import '../repositories/recent_search_repository.dart';
import 'settings_provider.dart';

final recentSearchRepositoryProvider = Provider<RecentSearchRepository>((ref) {
  return RecentSearchRepository(ref.watch(storageServiceProvider));
});

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<AssetModel>>((ref) {
  return RecentSearchesNotifier(ref.watch(recentSearchRepositoryProvider));
});

class RecentSearchesNotifier extends StateNotifier<List<AssetModel>> {
  RecentSearchesNotifier(this._repository) : super(const []) {
    load();
  }

  final RecentSearchRepository _repository;

  Future<void> load() async {
    state = await _repository.load();
  }

  Future<void> add(AssetModel asset) async {
    state = await _repository.add(asset);
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const [];
  }
}
