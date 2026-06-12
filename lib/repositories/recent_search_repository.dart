import '../core/services/storage_service.dart';
import '../models/asset_model.dart';

class RecentSearchRepository {
  RecentSearchRepository(this._storage, {this.limit = 10});

  static const String _key = 'experts.recentSearches';

  final StorageService _storage;
  final int limit;

  Future<List<AssetModel>> load() async {
    final values = await _storage.readJsonList(_key);
    return values.map(AssetModel.fromJson).toList(growable: false);
  }

  Future<List<AssetModel>> add(AssetModel asset) async {
    final normalized = asset.copyWith(symbol: asset.symbol.toUpperCase());
    final existing = await load();
    final next = [
      normalized,
      ...existing.where((item) => item.symbol != normalized.symbol),
    ].take(limit).toList(growable: false);
    await save(next);
    return next;
  }

  Future<void> save(List<AssetModel> assets) {
    return _storage.writeJsonList(
      _key,
      assets.map((asset) => asset.toJson()).toList(growable: false),
    );
  }

  Future<void> clear() {
    return _storage.remove(_key);
  }
}
