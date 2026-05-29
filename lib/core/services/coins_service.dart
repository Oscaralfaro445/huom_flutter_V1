import 'package:hive_flutter/hive_flutter.dart';
import 'cloud_save_service.dart';

class CoinsService {
  static const String _boxName = 'coins';
  static const String _coinsKey = 'total_coins';

  final CloudSaveService _cloudSave;

  CoinsService(this._cloudSave);

  Future<Box> get _box async => Hive.openBox(_boxName);

  Future<int> getCoins() async {
    final box = await _box;
    return box.get(_coinsKey, defaultValue: 0) as int;
  }

  Future<void> addCoins(int amount) async {
    final box = await _box;
    final current = box.get(_coinsKey, defaultValue: 0) as int;
    final newTotal = current + amount;
    await box.put(_coinsKey, newTotal);
    _cloudSave.saveCoins(newTotal);
  }

  Future<void> spendCoins(int amount) async {
    final box = await _box;
    final current = box.get(_coinsKey, defaultValue: 0) as int;
    final newTotal = (current - amount).clamp(0, 999999);
    await box.put(_coinsKey, newTotal);
    _cloudSave.saveCoins(newTotal);
  }
}
