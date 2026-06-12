import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset_model.dart';
import '../models/watchlist_item_model.dart';
import '../repositories/watchlist_repository.dart';
import 'settings_provider.dart';

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository(ref.watch(storageServiceProvider));
});

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<WatchlistItemModel>>((ref) {
  return WatchlistNotifier(ref.watch(watchlistRepositoryProvider));
});

class WatchlistNotifier extends StateNotifier<List<WatchlistItemModel>> {
  WatchlistNotifier(this._repository) : super(const []) {
    load();
  }

  final WatchlistRepository _repository;

  Future<void> load() async {
    state = await _repository.load();
  }

  bool contains(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    return state.any((item) => item.symbol == normalized);
  }

  Future<void> addAsset(AssetModel asset) async {
    state = await _repository.addAsset(asset);
  }

  Future<void> removeSymbol(String symbol) async {
    state = await _repository.removeSymbol(symbol);
  }

  Future<void> toggleAsset(AssetModel asset) async {
    if (contains(asset.symbol)) {
      await removeSymbol(asset.symbol);
    } else {
      await addAsset(asset);
    }
  }
}
