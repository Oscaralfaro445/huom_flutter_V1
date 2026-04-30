import 'package:hive/hive.dart';
import '../../features/pet/domain/entities/pet.dart';

/// Promedios de stats acumulados durante la etapa Cría.
class StatAverages {
  final double hunger;
  final double mood;
  final double play;
  final double sleep;
  final double health;

  const StatAverages({
    required this.hunger,
    required this.mood,
    required this.play,
    required this.sleep,
    required this.health,
  });

  double get overall => (hunger + mood + play + sleep + health) / 5;
}

/// Registra un snapshot diario de stats durante la etapa baby y
/// expone los promedios para que MutationCheckService evalúe la mutación.
class MutationHistoryTracker {
  static const String _boxName = 'mutation_history';

  Future<Box<dynamic>> get _box async => Hive.openBox<dynamic>(_boxName);

  /// Graba el snapshot del día actual (una vez por día de juego).
  /// Solo actúa durante PetStage.baby.
  Future<void> recordSnapshot(Pet pet) async {
    if (pet.stage != PetStage.baby) return;

    final box = await _box;
    final snapshotKey = '${pet.id}_day_${pet.daysAlive}';

    if (box.containsKey(snapshotKey)) return;

    await box.put(snapshotKey, {
      'hunger': pet.stats.hunger,
      'mood': pet.stats.mood,
      'play': pet.stats.play,
      'sleep': pet.stats.sleep,
      'health': pet.stats.health,
      'day': pet.daysAlive,
    });
  }

  /// Calcula el promedio de cada stat sobre todos los snapshots registrados.
  Future<StatAverages> getAverages(String petId) async {
    final box = await _box;
    final keys = box.keys
        .where((k) => k.toString().startsWith('${petId}_day_'))
        .toList();

    if (keys.isEmpty) {
      return const StatAverages(
        hunger: 70,
        mood: 70,
        play: 70,
        sleep: 70,
        health: 100,
      );
    }

    double totalHunger = 0, totalMood = 0, totalPlay = 0;
    double totalSleep = 0, totalHealth = 0;

    for (final key in keys) {
      final data = box.get(key) as Map;
      totalHunger += (data['hunger'] as num).toDouble();
      totalMood += (data['mood'] as num).toDouble();
      totalPlay += (data['play'] as num).toDouble();
      totalSleep += (data['sleep'] as num).toDouble();
      totalHealth += (data['health'] as num).toDouble();
    }

    final count = keys.length.toDouble();
    return StatAverages(
      hunger: totalHunger / count,
      mood: totalMood / count,
      play: totalPlay / count,
      sleep: totalSleep / count,
      health: totalHealth / count,
    );
  }

  /// Limpia el historial tras la evolución para no contaminar la siguiente vida.
  Future<void> clearHistory(String petId) async {
    final box = await _box;
    final keys = box.keys
        .where((k) => k.toString().startsWith('${petId}_'))
        .toList();
    await box.deleteAll(keys);
  }
}
