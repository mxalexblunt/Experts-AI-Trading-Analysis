import '../core/services/storage_service.dart';
import '../models/asset_model.dart';
import '../models/watchlist_item_model.dart';

class WatchlistRepository {
  WatchlistRepository(this._storage);

  static const String _key = 'experts.watchlist';

  final StorageService _storage;

  Future<List<WatchlistItemModel>> load() async {
    final values = await _storage.readJsonList(_key);
    return values.map(WatchlistItemModel.fromJson).toList(growable: false);
  }

  Future<void> save(List<WatchlistItemModel> items) {
    final normalized = _dedupe(items);
    return _storage.writeJsonList(
      _key,
      normalized.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<List<WatchlistItemModel>> addAsset(AssetModel asset) async {
    final items = await load();
    final next = [
      WatchlistItemModel.fromAsset(asset),
      ...items.where((item) => item.symbol != asset.symbol.toUpperCase()),
    ];
    await save(next);
    return next;
  }

  Future<List<WatchlistItemModel>> removeSymbol(String symbol) async {
    final normalized = symbol.trim().toUpperCase();
    final next = (await load())
        .where((item) => item.symbol != normalized)
        .toList(growable: false);
    await save(next);
    return next;
  }

  Future<bool> contains(String symbol) async {
    final normalized = symbol.trim().toUpperCase();
    return (await load()).any((item) => item.symbol == normalized);
  }

  List<WatchlistItemModel> _dedupe(List<WatchlistItemModel> items) {
    final seen = <String>{};
    final result = <WatchlistItemModel>[];
    for (final item in items) {
      final symbol = item.symbol.toUpperCase();
      if (seen.add(symbol)) {
        result.add(item.copyWith(symbol: symbol));
      }
    }
    return result;
  }
}
