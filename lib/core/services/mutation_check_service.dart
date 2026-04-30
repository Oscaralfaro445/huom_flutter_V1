import '../../features/pet/domain/entities/pet.dart';
import 'mutation_history_tracker.dart';

/// Evalúa los promedios de stats acumulados durante la etapa Cría
/// y devuelve la mutación que la mascota debe obtener al evolucionar.
///
/// Las condiciones se comprueban en orden de prioridad: primera que
/// coincide gana. Los umbrales están diseñados para ser mutuamente
/// excluyentes en la práctica habitual de juego.
class MutationCheckService {
  PetMutation checkMutation(StatAverages averages) {
    // Neglected health — consistently sick
    if (averages.health < 30) return PetMutation.shadowBone;

    // Tough survivor — low food & sleep but still alive
    if (averages.hunger < 40 && averages.sleep < 40) return PetMutation.cactusRex;

    // Athletic — always playing
    if (averages.play > 70) return PetMutation.thunderLeaf;

    // Social butterfly — consistently happy
    if (averages.mood > 75) return PetMutation.blossom;

    // Healthy & content — well-maintained health and mood
    if (averages.health > 75 && averages.mood > 60) return PetMutation.aquaSlime;

    // Mediocre / erratic care (overall score in the middle range)
    if (averages.overall < 65) return PetMutation.glitchPet;

    // Default: balanced good care
    return PetMutation.slimeBit;
  }
}
