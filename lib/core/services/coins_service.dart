import 'package:hive_flutter/hive_flutter.dart';

class CoinsService {
  static const String _boxName = 'coins';
  static const String _coinsKey = 'total_coins';

  Future<Box> get _box async => Hive.openBox(_boxName);

  Future<int> getCoins() async {
    final box = await _box;
    return box.get(_coinsKey, defaultValue: 0) as int;
  }

  Future<void> addCoins(int amount) async {
    final box = await _box;
    final current = box.get(_coinsKey, defaultValue: 0) as int;
    await box.put(_coinsKey, current + amount);
  }

  Future<void> spendCoins(int amount) async {
    final box = await _box;
    final current = box.get(_coinsKey, defaultValue: 0) as int;
    final newAmount = (current - amount).clamp(0, 999999);
    await box.put(_coinsKey, newAmount);
  }
}
