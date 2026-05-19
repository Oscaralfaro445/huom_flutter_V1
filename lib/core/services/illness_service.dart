import 'dart:math';
import '../../features/pet/domain/entities/pet.dart';

class IllnessService {
  static final Random _rng = Random();

  // Probabilidad base de enfermar: ~1% por hora sin factores de riesgo
  static const double _baseChancePerHour = 0.01;

  /// Evalúa si la mascota desarrolla nuevas condiciones en base al tiempo
  /// transcurrido y sus factores de riesgo actuales.
  List<PetCondition> checkForNewConditions(Pet pet, double hoursElapsed) {
    if (pet.state == PetState.dead) return pet.conditions;
    if (hoursElapsed < 0.1) return pet.conditions;

    final newConditions = List<PetCondition>.from(pet.conditions);

    // Agotamiento: se activa si el sueño es críticamente bajo por > 1 hora
    if (!_has(newConditions, ConditionType.exhaustion) &&
        pet.stats.sleep < 10 &&
        hoursElapsed > 1.0) {
      newConditions.add(
        PetCondition(type: ConditionType.exhaustion, contractedAt: DateTime.now()),
      );
    }

    // Enfermedades respiratorias (probabilísticas, progresivas)
    final riskMult = _riskMultiplier(pet, newConditions);
    final sessionChance = _baseChancePerHour * hoursElapsed * riskMult;

    if (_rng.nextDouble() < sessionChance) {
      final newIllness = _progressIllness(newConditions);
      if (newIllness != null) newConditions.add(newIllness);
    }

    return newConditions;
  }

  /// Aplica el decay extra derivado de cada condición activa.
  PetStats applyConditionDecay(
    PetStats stats,
    List<PetCondition> conditions,
    double hoursElapsed,
  ) {
    if (conditions.isEmpty) return stats;

    double healthPenalty = 0;
    double moodPenalty = 0;
    double playPenalty = 0;
    double hungerPenalty = 0;
    double exhaustionMult = 1.0;

    for (final c in conditions) {
      switch (c.type) {
        case ConditionType.cold:
          healthPenalty += 1.5 * hoursElapsed;
          moodPenalty += 0.5 * hoursElapsed;
          break;
        case ConditionType.flu:
          healthPenalty += 3.0 * hoursElapsed;
          moodPenalty += 2.0 * hoursElapsed;
          break;
        case ConditionType.fever:
          healthPenalty += 5.0 * hoursElapsed;
          moodPenalty += 4.0 * hoursElapsed;
          hungerPenalty += 2.0 * hoursElapsed;
          break;
        case ConditionType.minorInjury:
          healthPenalty += 1.0 * hoursElapsed;
          playPenalty += 2.0 * hoursElapsed;
          break;
        case ConditionType.seriousInjury:
          healthPenalty += 2.0 * hoursElapsed;
          playPenalty += 4.0 * hoursElapsed;
          moodPenalty += 1.5 * hoursElapsed;
          break;
        case ConditionType.exhaustion:
          // El agotamiento amplifica todos los demás penalizadores
          exhaustionMult = 1.5;
          break;
      }
    }

    return stats.copyWith(
      health: stats.health - (healthPenalty * exhaustionMult),
      mood: stats.mood - (moodPenalty * exhaustionMult),
      play: stats.play - (playPenalty * exhaustionMult),
      hunger: stats.hunger - (hungerPenalty * exhaustionMult),
    );
  }

  /// Aplica una lesión a la lista de condiciones (sin duplicar tipo).
  List<PetCondition> applyInjury(
    List<PetCondition> conditions,
    ConditionType injuryType,
  ) {
    // Lesión grave sobreescribe leve si ya existe
    if (injuryType == ConditionType.seriousInjury) {
      final without = conditions
          .where((c) => c.type != ConditionType.minorInjury)
          .toList();
      if (_has(without, ConditionType.seriousInjury)) return conditions;
      return [...without, PetCondition(type: injuryType, contractedAt: DateTime.now())];
    }

    // Lesión leve no se añade si ya hay grave
    if (injuryType == ConditionType.minorInjury &&
        _has(conditions, ConditionType.seriousInjury)) {
      return conditions;
    }

    if (_has(conditions, injuryType)) return conditions;
    return [
      ...conditions,
      PetCondition(type: injuryType, contractedAt: DateTime.now()),
    ];
  }

  // ─── Helpers privados ────────────────────────────────────────────────────

  bool _has(List<PetCondition> conditions, ConditionType type) =>
      conditions.any((c) => c.type == type);

  double _riskMultiplier(Pet pet, List<PetCondition> current) {
    double m = 1.0;

    // Privación de sueño
    if (pet.stats.sleep < 20) {
      m *= 3.0;
    } else if (pet.stats.sleep < 40) {
      m *= 1.5;
    }

    // Salud baja
    if (pet.stats.health < 30) m *= 2.0;

    // Suciedad
    if (pet.stats.cleanliness < 25) m *= 1.8;

    // Estado estresado
    if (pet.state == PetState.stressed) m *= 1.5;

    // El agotamiento duplica la chance de enfermar
    if (_has(current, ConditionType.exhaustion)) m *= 2.0;

    // Etapa baby es más susceptible
    if (pet.stage == PetStage.baby) m *= 1.3;

    // Mutaciones
    if (pet.mutation == PetMutation.aquaSlime) m *= 0.5;
    if (pet.mutation == PetMutation.shadowBone) m *= 1.5;

    return m;
  }

  /// Progresión lineal: sin enfermedad → cold → flu → fever.
  PetCondition? _progressIllness(List<PetCondition> current) {
    if (_has(current, ConditionType.fever)) return null;
    if (_has(current, ConditionType.flu)) {
      return PetCondition(type: ConditionType.fever, contractedAt: DateTime.now());
    }
    if (_has(current, ConditionType.cold)) {
      return PetCondition(type: ConditionType.flu, contractedAt: DateTime.now());
    }
    return PetCondition(type: ConditionType.cold, contractedAt: DateTime.now());
  }
}
