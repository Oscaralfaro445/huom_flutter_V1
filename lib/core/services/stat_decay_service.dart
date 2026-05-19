import '../../features/pet/domain/entities/pet.dart';
import 'illness_service.dart';

class _DecayMultipliers {
  final double hunger;
  final double mood;
  final double play;
  final double sleep;

  const _DecayMultipliers({
    required this.hunger,
    required this.mood,
    required this.play,
    required this.sleep,
  });
}

class StatDecayService {
  final IllnessService _illnessService;

  StatDecayService(this._illnessService);

  // Decay base por hora (puntos/hora)
  static const double _hungerDecay = 3.0;
  static const double _moodDecay = 1.5;
  static const double _playDecay = 2.0;
  static const double _sleepDecay = 2.5;
  static const double _cleanlinessDecay = 1.8;

  // Penalizaciones cuando la mascota está muy sucia (cleanliness < 25)
  static const double _dirtyHealthPenalty = 2.0;
  static const double _dirtyMoodPenalty = 1.5;

  /// Aplica el decay basado en tiempo real transcurrido.
  /// Llamar SOLO al abrir la app, nunca con un Timer activo.
  Pet applyDecay(Pet pet, DateTime now) {
    if (pet.state == PetState.dead) return pet;

    final hoursElapsed = now.difference(pet.lastInteraction).inMinutes / 60.0;

    // Menos de 36 segundos, ignorar
    if (hoursElapsed < 0.01) return pet;

    final stageMult = switch (pet.stage) {
      PetStage.baby => 1.2,
      PetStage.elder => 0.8,
      _ => 1.0,
    };

    final mutMult = _getMutationMultipliers(pet.mutation);

    final newCleanliness =
        pet.stats.cleanliness - (_cleanlinessDecay * hoursElapsed * stageMult);

    final isDirty = newCleanliness < 25;
    final healthPenalty = isDirty ? _dirtyHealthPenalty * hoursElapsed : 0.0;
    final moodPenalty = isDirty ? _dirtyMoodPenalty * hoursElapsed : 0.0;

    var newStats = pet.stats.copyWith(
      hunger: pet.stats.hunger -
          (_hungerDecay * hoursElapsed * stageMult * mutMult.hunger),
      mood: pet.stats.mood -
          (_moodDecay * hoursElapsed * stageMult * mutMult.mood) -
          moodPenalty,
      play: pet.stats.play -
          (_playDecay * hoursElapsed * stageMult * mutMult.play),
      sleep: pet.stats.sleep -
          (_sleepDecay * hoursElapsed * stageMult * mutMult.sleep),
      health: pet.stats.health - healthPenalty,
      cleanliness: newCleanliness,
    );

    // Aplicar penalizaciones por condiciones activas
    newStats = _illnessService.applyConditionDecay(
      newStats,
      pet.conditions,
      hoursElapsed,
    );

    // Evaluar nuevas condiciones por privación de sueño / riesgo
    final updatedPet = pet.copyWith(stats: newStats);
    final newConditions =
        _illnessService.checkForNewConditions(updatedPet, hoursElapsed);

    final newState = _evaluateState(newStats, hoursElapsed, pet, newConditions);

    return pet.copyWith(
      stats: newStats,
      state: newState,
      lastInteraction: now,
      daysAlive: now.difference(pet.createdAt).inDays,
      conditions: newConditions,
    );
  }

  PetState _evaluateState(
    PetStats stats,
    double hoursElapsed,
    Pet pet,
    List<PetCondition> conditions,
  ) {
    if (stats.hunger <= 0 && hoursElapsed >= 6) return PetState.dead;
    if (stats.health <= 0 && hoursElapsed >= 12) return PetState.dead;
    if (pet.stage == PetStage.elder && pet.daysAlive >= 30) {
      return PetState.dead;
    }
    // Con condiciones activas o health baja → sick
    if (stats.health < 20 || conditions.isNotEmpty) return PetState.sick;
    if (stats.hunger < 25 || stats.sleep < 15 || stats.cleanliness < 15) {
      return PetState.stressed;
    }
    return PetState.happy;
  }

  _DecayMultipliers _getMutationMultipliers(PetMutation mutation) {
    return switch (mutation) {
      PetMutation.cactusRex => const _DecayMultipliers(
          hunger: 0.7,
          mood: 1.2,
          play: 1.0,
          sleep: 0.8,
        ),
      PetMutation.aquaSlime => const _DecayMultipliers(
          hunger: 1.0,
          mood: 0.8,
          play: 1.0,
          sleep: 1.0,
        ),
      PetMutation.thunderLeaf => const _DecayMultipliers(
          hunger: 1.1,
          mood: 0.9,
          play: 0.7,
          sleep: 1.2,
        ),
      PetMutation.blossom => const _DecayMultipliers(
          hunger: 1.0,
          mood: 0.7,
          play: 0.9,
          sleep: 0.9,
        ),
      PetMutation.shadowBone => const _DecayMultipliers(
          hunger: 1.3,
          mood: 1.3,
          play: 1.3,
          sleep: 1.3,
        ),
      PetMutation.glitchPet || PetMutation.slimeBit => const _DecayMultipliers(
          hunger: 1.0,
          mood: 1.0,
          play: 1.0,
          sleep: 1.0,
        ),
    };
  }
}
