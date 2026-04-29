import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/coins_service.dart';

final coinsProvider =
    AsyncNotifierProvider<CoinsNotifier, int>(CoinsNotifier.new);

class CoinsNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    return sl<CoinsService>().getCoins();
  }

  Future<void> refresh() async {
    state = AsyncData(await sl<CoinsService>().getCoins());
  }
}
