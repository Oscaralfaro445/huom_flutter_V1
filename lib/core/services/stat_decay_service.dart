import '../../features/pet/domain/entities/pet.dart';

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
  // Decay base por hora (puntos/hora)
  static const double _hungerDecay = 3.0;
  static const double _moodDecay = 1.5;
  static const double _playDecay = 2.0;
  static const double _sleepDecay = 2.5;

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

    final newStats = pet.stats.copyWith(
      hunger: pet.stats.hunger -
          (_hungerDecay * hoursElapsed * stageMult * mutMult.hunger),
      mood: pet.stats.mood -
          (_moodDecay * hoursElapsed * stageMult * mutMult.mood),
      play: pet.stats.play -
          (_playDecay * hoursElapsed * stageMult * mutMult.play),
      sleep: pet.stats.sleep -
          (_sleepDecay * hoursElapsed * stageMult * mutMult.sleep),
    );

    final newState = _evaluateState(newStats, hoursElapsed, pet);

    return pet.copyWith(
      stats: newStats,
      state: newState,
      lastInteraction: now,
      daysAlive: now.difference(pet.createdAt).inDays,
    );
  }

  PetState _evaluateState(PetStats stats, double hoursElapsed, Pet pet) {
    if (stats.hunger <= 0 && hoursElapsed >= 6) return PetState.dead;
    if (stats.health <= 0 && hoursElapsed >= 12) return PetState.dead;
    if (pet.stage == PetStage.elder && pet.daysAlive >= 30) {
      return PetState.dead;
    }
    if (stats.health < 20) return PetState.sick;
    if (stats.hunger < 25 || stats.sleep < 15) return PetState.stressed;
    return PetState.happy;
  }

  /// Multiplicadores de decay por mutación.
  /// < 1.0 = decay más lento (bono). > 1.0 = decay más rápido (penalización).
  _DecayMultipliers _getMutationMultipliers(PetMutation mutation) {
    return switch (mutation) {
      // Resistente al hambre y sueño, pero se pone de mal humor más rápido
      PetMutation.cactusRex => const _DecayMultipliers(
          hunger: 0.7,
          mood: 1.2,
          play: 1.0,
          sleep: 0.8,
        ),
      // Resistente a la enfermedad; mood muy estable
      PetMutation.aquaSlime => const _DecayMultipliers(
          hunger: 1.0,
          mood: 0.8,
          play: 1.0,
          sleep: 1.0,
        ),
      // Necesita jugar más, pero recupera mood fácil
      PetMutation.thunderLeaf => const _DecayMultipliers(
          hunger: 1.1,
          mood: 0.9,
          play: 0.7,
          sleep: 1.2,
        ),
      // Muy feliz por naturaleza; necesita comer igual
      PetMutation.blossom => const _DecayMultipliers(
          hunger: 1.0,
          mood: 0.7,
          play: 0.9,
          sleep: 0.9,
        ),
      // Todo decae más rápido — mascota difícil
      PetMutation.shadowBone => const _DecayMultipliers(
          hunger: 1.3,
          mood: 1.3,
          play: 1.3,
          sleep: 1.3,
        ),
      // Sin modificadores (aleatoriedad narrativa, no mecánica)
      PetMutation.glitchPet || PetMutation.slimeBit => const _DecayMultipliers(
          hunger: 1.0,
          mood: 1.0,
          play: 1.0,
          sleep: 1.0,
        ),
    };
  }
}
