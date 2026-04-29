import '../../features/pet/domain/entities/pet.dart';

class StatDecayService {
  // Decay base por hora (puntos/hora)
  static const double _hungerDecay = 3.0;
  static const double _moodDecay = 1.5;
  static const double _playDecay = 2.0;
  static const double _sleepDecay = 2.5;

  /// Aplica el decay basado en tiempo real transcurrido.
  /// Llamar SOLO al abrir la app, nunca con un Timer activo.
  Pet applyDecay(Pet pet, DateTime now) {
    // Si ya está muerto no hacer nada
    if (pet.state == PetState.dead) return pet;

    final hoursElapsed = now.difference(pet.lastInteraction).inMinutes / 60.0;

    // Menos de 36 segundos, ignorar
    if (hoursElapsed < 0.01) return pet;

    // Multiplicador por etapa
    final stageMult = switch (pet.stage) {
      PetStage.baby => 1.2, // cría decae más rápido
      PetStage.elder => 0.8, // anciano decae más lento
      _ => 1.0,
    };

    final newStats = pet.stats.copyWith(
      hunger: pet.stats.hunger - (_hungerDecay * hoursElapsed * stageMult),
      mood: pet.stats.mood - (_moodDecay * hoursElapsed * stageMult),
      play: pet.stats.play - (_playDecay * hoursElapsed * stageMult),
      sleep: pet.stats.sleep - (_sleepDecay * hoursElapsed * stageMult),
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
    // Muerte por hambre: llega a 0 y llevaba más de 6h sin comer
    if (stats.hunger <= 0 && hoursElapsed >= 6) return PetState.dead;

    // Muerte por enfermedad: salud en 0 por más de 12h
    if (stats.health <= 0 && hoursElapsed >= 12) return PetState.dead;

    // Muerte por vejez: día 30
    if (pet.stage == PetStage.elder && pet.daysAlive >= 30) {
      return PetState.dead;
    }

    // Enfermedad
    if (stats.health < 20) return PetState.sick;

    // Estrés
    if (stats.hunger < 25 || stats.sleep < 15) return PetState.stressed;

    return PetState.happy;
  }
}
