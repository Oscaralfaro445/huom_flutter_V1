import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:huom/core/services/illness_service.dart';
import 'package:huom/core/services/stat_decay_service.dart';
import 'package:huom/features/pet/domain/entities/pet.dart';

/// Random determinista para tests: nextDouble() siempre devuelve 1.0,
/// por lo que ningún chequeo probabilístico de enfermedad se activa
/// (todos los thresholds son < 1.0).
class _NeverSickRandom implements Random {
  @override
  double nextDouble() => 1.0;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void main() {
  late StatDecayService service;

  setUp(() => service = StatDecayService(IllnessService(_NeverSickRandom())));

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------
  Pet buildPet({
    required DateTime now,
    required DateTime lastInteraction,
    PetStage stage = PetStage.adult,
    PetMutation mutation = PetMutation.slimeBit,
    PetStats? stats,
    int daysAlive = 5,
    PetState state = PetState.happy,
  }) {
    return Pet(
      id: 'test-id',
      name: 'Pixel',
      stage: stage,
      state: state,
      mutation: mutation,
      stats: stats ?? const PetStats(),
      lastInteraction: lastInteraction,
      createdAt: now.subtract(Duration(days: daysAlive)),
      daysAlive: daysAlive,
    );
  }

  // Stats base con todos los valores al máximo para pruebas de decay aislado
  const fullStats = PetStats(
    hunger: 100,
    mood: 100,
    play: 100,
    sleep: 100,
    health: 100,
    cleanliness: 100,
  );

  // ---------------------------------------------------------------------------
  // Guard clauses
  // ---------------------------------------------------------------------------
  group('guard clauses', () {
    test('mascota muerta → retorna la misma instancia sin modificar', () {
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 5)),
      ).copyWith(state: PetState.dead);

      expect(service.applyDecay(pet, now), same(pet));
    });

    test('menos de 36 segundos → no aplica decay ni actualiza lastInteraction', () {
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(seconds: 30)),
      );

      final result = service.applyDecay(pet, now);

      expect(result.stats.hunger, pet.stats.hunger);
      expect(result.lastInteraction, pet.lastInteraction);
    });

    test('exactamente 36 segundos (0.01h) → SÍ aplica decay', () {
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(seconds: 36)),
        stats: const PetStats(hunger: 100, cleanliness: 100),
      );

      final result = service.applyDecay(pet, now);

      expect(result.stats.hunger, lessThan(100));
    });

    test('tiempo negativo (now anterior a lastInteraction) → no aplica decay', () {
      final now = DateTime(2026, 1, 1, 10);
      final future = now.add(const Duration(hours: 2));
      final pet = buildPet(now: now, lastInteraction: future);

      final result = service.applyDecay(pet, now);

      expect(result.stats.hunger, pet.stats.hunger);
    });
  });

  // ---------------------------------------------------------------------------
  // Multiplicadores de etapa
  // ---------------------------------------------------------------------------
  group('multiplicadores de etapa', () {
    final base = DateTime(2026, 1, 1, 10);

    test('egg usa multiplicador 1.0 (mismo que adult)', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.egg,
        stats: fullStats,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.hunger, closeTo(100 - 3.0, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5, 0.01));
    });

    test('adult – decay base 1 hora con slimeBit (sin modificadores)', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.adult,
        stats: fullStats,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.hunger, closeTo(97.0, 0.01));
      expect(result.stats.mood, closeTo(98.5, 0.01));
      expect(result.stats.play, closeTo(98.0, 0.01));
      expect(result.stats.sleep, closeTo(97.5, 0.01));
    });

    test('baby – todos los stats decaen × 1.2', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.baby,
        stats: fullStats,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.hunger, closeTo(100 - 3.0 * 1.2, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 1.2, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 1.2, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 1.2, 0.01));
    });

    test('elder – todos los stats decaen × 0.8', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.elder,
        stats: fullStats,
        daysAlive: 25,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.hunger, closeTo(100 - 3.0 * 0.8, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 0.8, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 0.8, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 0.8, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // Multiplicadores de mutación (1 hora, adult, stats plenos)
  // ---------------------------------------------------------------------------
  group('multiplicadores de mutación', () {
    final base = DateTime(2026, 1, 1, 10);

    Pet petWith(PetMutation m) => buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 1)),
          stage: PetStage.adult,
          mutation: m,
          stats: fullStats,
        );

    test('slimeBit – todos 1.0x (sin modificadores)', () {
      final result = service.applyDecay(petWith(PetMutation.slimeBit), base);

      expect(result.stats.hunger, closeTo(97.0, 0.01));
      expect(result.stats.mood, closeTo(98.5, 0.01));
      expect(result.stats.play, closeTo(98.0, 0.01));
      expect(result.stats.sleep, closeTo(97.5, 0.01));
    });

    test('glitchPet – todos 1.0x (idéntico a slimeBit)', () {
      final r1 = service.applyDecay(petWith(PetMutation.slimeBit), base);
      final r2 = service.applyDecay(petWith(PetMutation.glitchPet), base);

      expect(r2.stats.hunger, closeTo(r1.stats.hunger, 0.001));
      expect(r2.stats.mood, closeTo(r1.stats.mood, 0.001));
      expect(r2.stats.play, closeTo(r1.stats.play, 0.001));
      expect(r2.stats.sleep, closeTo(r1.stats.sleep, 0.001));
    });

    test('cactusRex – hunger 0.7×, mood 1.2×, play 1.0×, sleep 0.8×', () {
      final result = service.applyDecay(petWith(PetMutation.cactusRex), base);

      expect(result.stats.hunger, closeTo(100 - 3.0 * 0.7, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 1.2, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 1.0, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 0.8, 0.01));
    });

    test('aquaSlime – mood 0.8×, el resto 1.0×', () {
      final result = service.applyDecay(petWith(PetMutation.aquaSlime), base);

      expect(result.stats.hunger, closeTo(97.0, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 0.8, 0.01));
      expect(result.stats.play, closeTo(98.0, 0.01));
      expect(result.stats.sleep, closeTo(97.5, 0.01));
    });

    test('thunderLeaf – hunger 1.1×, mood 0.9×, play 0.7×, sleep 1.2×', () {
      final result =
          service.applyDecay(petWith(PetMutation.thunderLeaf), base);

      expect(result.stats.hunger, closeTo(100 - 3.0 * 1.1, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 0.9, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 0.7, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 1.2, 0.01));
    });

    test('blossom – hunger 1.0×, mood 0.7×, play 0.9×, sleep 0.9×', () {
      final result = service.applyDecay(petWith(PetMutation.blossom), base);

      expect(result.stats.hunger, closeTo(97.0, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 0.7, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 0.9, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 0.9, 0.01));
    });

    test('shadowBone – todos los stats decaen × 1.3', () {
      final result = service.applyDecay(petWith(PetMutation.shadowBone), base);

      expect(result.stats.hunger, closeTo(100 - 3.0 * 1.3, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 1.3, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 1.3, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 1.3, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // Combinaciones etapa × mutación
  // ---------------------------------------------------------------------------
  group('combinaciones etapa × mutación', () {
    final base = DateTime(2026, 1, 1, 10);

    test('baby + shadowBone → hunger decae × (1.2 × 1.3) = 1.56', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.baby,
        mutation: PetMutation.shadowBone,
        stats: fullStats,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.hunger, closeTo(100 - 3.0 * 1.2 * 1.3, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 1.2 * 1.3, 0.01));
    });

    test('elder + cactusRex → hunger decae × (0.8 × 0.7) = 0.56 (muy lento)', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.elder,
        mutation: PetMutation.cactusRex,
        stats: fullStats,
        daysAlive: 25,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.hunger, closeTo(100 - 3.0 * 0.8 * 0.7, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // Decay de cleanliness
  // ---------------------------------------------------------------------------
  group('decay de cleanliness', () {
    final base = DateTime(2026, 1, 1, 10);

    test('adult, 1 hora → cleanliness decae exactamente 1.8 puntos', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.adult,
        stats: fullStats,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.cleanliness, closeTo(100 - 1.8, 0.01));
    });

    test('baby, 1 hora → cleanliness decae × 1.2 = 2.16 puntos', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.baby,
        stats: fullStats,
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.cleanliness, closeTo(100 - 1.8 * 1.2, 0.01));
    });

    test('cleanliness no baja de 0 tras 100 horas', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 100)),
        stats: const PetStats(cleanliness: 5),
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.cleanliness, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Penalización por suciedad (cleanliness resultante < 25)
  // ---------------------------------------------------------------------------
  group('penalización por suciedad', () {
    final base = DateTime(2026, 1, 1, 10);

    test(
        'cleanliness cruza umbral 25 tras 1h → healthPenalty=2.0 y moodPenalty=1.5',
        () {
      // cleanliness=26: tras 1h adult → 26-1.8 = 24.2 < 25 → isDirty
      // healthPenalty = 2.0 × 1h = 2.0  (sin stageMult)
      // moodPenalty   = 1.5 × 1h = 1.5  (sin stageMult)
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.adult,
        stats: const PetStats(
          health: 100,
          mood: 100,
          hunger: 100,
          play: 100,
          sleep: 100,
          cleanliness: 26,
        ),
      );

      final result = service.applyDecay(pet, base);

      // health: solo penalización (sin decay base de health), 100 - 2.0 = 98
      expect(result.stats.health, closeTo(98.0, 0.01));
      // mood: decay base (1.5×1) + penalización (1.5), 100 - 3.0 = 97
      expect(result.stats.mood, closeTo(97.0, 0.01));
    });

    test('cleanliness=100 → no isDirty → health sin penalización (queda en 100)',
        () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.adult,
        stats: fullStats,
      );

      final result = service.applyDecay(pet, base);

      // health no tiene decay base, solo dirty penalty → debe seguir en 100
      expect(result.stats.health, 100);
    });

    test(
        'penalización de health NO usa stageMult: baby y adult reciben el mismo daño',
        () {
      // cleanliness ya es 0 → siempre isDirty
      const statsIniciales = PetStats(
        health: 100,
        cleanliness: 0,
        mood: 100,
        hunger: 100,
        play: 100,
        sleep: 100,
      );

      final petBaby = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.baby,
        stats: statsIniciales,
      );
      final petAdult = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stage: PetStage.adult,
        stats: statsIniciales,
      );

      final rBaby = service.applyDecay(petBaby, base);
      final rAdult = service.applyDecay(petAdult, base);

      // healthPenalty = 2.0 × h (sin stageMult), idéntico en ambas etapas
      expect(rBaby.stats.health, closeTo(rAdult.stats.health, 0.01));
    });

    test('cleanliness ya en 0 y 2 horas → healthPenalty acumulada = 4.0', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 2)),
        stage: PetStage.adult,
        stats: const PetStats(
          health: 100,
          cleanliness: 0,
          hunger: 100,
          mood: 100,
          play: 100,
          sleep: 100,
        ),
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.health, closeTo(100 - 2.0 * 2, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // Evaluación de estado (_evaluateState)
  // ---------------------------------------------------------------------------
  group('evaluación de estado', () {
    final base = DateTime(2026, 1, 1, 10);

    test('todos los stats en rangos saludables → PetState.happy', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 1)),
        stats: const PetStats(
          hunger: 80,
          mood: 80,
          play: 80,
          sleep: 80,
          health: 80,
          cleanliness: 80,
        ),
      );

      expect(service.applyDecay(pet, base).state, PetState.happy);
    });

    group('muerte por hambre', () {
      test('hunger resultante = 0 y hoursElapsed ≥ 6 → dead', () {
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 6)),
          stats: const PetStats(
            hunger: 0,
            mood: 80,
            play: 80,
            sleep: 80,
            cleanliness: 80,
          ),
        );

        expect(service.applyDecay(pet, base).state, PetState.dead);
      });

      test('hunger llega a 0 pero hoursElapsed < 6 → stressed, NO dead', () {
        // hunger=5, 3h: 5-9 = −4 → clamp 0. hoursElapsed=3 < 6 → no muere
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 3)),
          stats: const PetStats(
            hunger: 5,
            mood: 80,
            play: 80,
            sleep: 80,
            health: 100,
            cleanliness: 80,
          ),
        );

        final result = service.applyDecay(pet, base);

        expect(result.state, isNot(PetState.dead));
        expect(result.stats.hunger, 0); // efectivamente llegó a 0
      });
    });

    group('muerte por enfermedad', () {
      test('health cae a 0 con hoursElapsed ≥ 12 → dead', () {
        // cleanliness=0 → isDirty, healthPenalty=2×12=24. health=20 → 20-24=-4→0
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 12)),
          stats: const PetStats(
            health: 20,
            hunger: 80,
            mood: 80,
            play: 80,
            sleep: 80,
            cleanliness: 0,
          ),
        );

        expect(service.applyDecay(pet, base).state, PetState.dead);
      });
    });

    group('estado sick', () {
      test('health resultante < 20 → sick', () {
        // health=15, no dirty: health sin decay base → queda en 15 < 20 → sick
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 1)),
          stats: const PetStats(
            health: 15,
            hunger: 80,
            mood: 80,
            play: 80,
            sleep: 80,
            cleanliness: 100,
          ),
        );

        expect(service.applyDecay(pet, base).state, PetState.sick);
      });

      test('health resultante = 20 exacto → NO sick (límite no inclusivo)', () {
        // health=20, cleanliness=100 → no dirty → healthPenalty=0 → health=20
        // 20 < 20 = false → not sick
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 1)),
          stats: const PetStats(
            health: 20,
            hunger: 80,
            mood: 80,
            play: 80,
            sleep: 80,
            cleanliness: 100,
          ),
        );

        expect(service.applyDecay(pet, base).state, isNot(PetState.sick));
      });
    });

    group('estado stressed', () {
      test('hunger resultante < 25 → stressed', () {
        // hunger=23, 1h: 23-3=20 < 25 → stressed
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 1)),
          stats: const PetStats(
            hunger: 23,
            mood: 80,
            play: 80,
            sleep: 80,
            health: 100,
            cleanliness: 80,
          ),
        );

        expect(service.applyDecay(pet, base).state, PetState.stressed);
      });

      test('hunger resultante = 25 exacto → NO stressed por hunger', () {
        // hunger=28, 1h adult: 28-3=25 → 25 < 25 = false → no stressed por hunger
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 1)),
          stats: const PetStats(
            hunger: 28,
            mood: 80,
            play: 80,
            sleep: 80,
            health: 80,
            cleanliness: 80,
          ),
        );

        final result = service.applyDecay(pet, base);

        expect(result.stats.hunger, closeTo(25.0, 0.01));
        expect(result.state, PetState.happy);
      });

      test('sleep resultante < 15 → stressed', () {
        // sleep=13, 1h: 13-2.5=10.5 < 15 → stressed
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 1)),
          stats: const PetStats(
            hunger: 80,
            mood: 80,
            play: 80,
            sleep: 13,
            health: 80,
            cleanliness: 80,
          ),
        );

        expect(service.applyDecay(pet, base).state, PetState.stressed);
      });

      test('cleanliness resultante < 15 → stressed', () {
        // cleanliness=16, 1h adult: 16-1.8=14.2 < 15 → stressed
        final pet = buildPet(
          now: base,
          lastInteraction: base.subtract(const Duration(hours: 1)),
          stats: const PetStats(
            hunger: 80,
            mood: 80,
            play: 80,
            sleep: 80,
            health: 80,
            cleanliness: 16,
          ),
        );

        final result = service.applyDecay(pet, base);

        expect(result.stats.cleanliness, closeTo(14.2, 0.01));
        expect(result.state, PetState.stressed);
      });
    });

    group('muerte por vejez (elder)', () {
      test('elder + daysAlive = 29 → NO muere por vejez (límite < 30)', () {
        final now = DateTime(2026, 1, 1, 10);
        final pet = Pet(
          id: 'old',
          name: 'Anciano',
          stage: PetStage.elder,
          stats: fullStats,
          lastInteraction: now.subtract(const Duration(hours: 1)),
          createdAt: now.subtract(const Duration(days: 29)),
          daysAlive: 29,
        );

        expect(service.applyDecay(pet, now).state, isNot(PetState.dead));
      });

      test('elder + daysAlive = 30 → muere por vejez aunque stats estén ok', () {
        final now = DateTime(2026, 1, 1, 10);
        final pet = Pet(
          id: 'old',
          name: 'Anciano',
          stage: PetStage.elder,
          stats: fullStats,
          lastInteraction: now.subtract(const Duration(hours: 1)),
          createdAt: now.subtract(const Duration(days: 31)),
          daysAlive: 30,
        );

        expect(service.applyDecay(pet, now).state, PetState.dead);
      });

      test('elder + daysAlive >= 30 tiene prioridad sobre sick (stats bajos)', () {
        final now = DateTime(2026, 1, 1, 10);
        final pet = Pet(
          id: 'old',
          name: 'Anciano',
          stage: PetStage.elder,
          stats: const PetStats(health: 10), // health crítico
          lastInteraction: now.subtract(const Duration(hours: 1)),
          createdAt: now.subtract(const Duration(days: 35)),
          daysAlive: 35,
        );

        // Aunque health<20 debería → sick, la vejez se evalúa primero → dead
        expect(service.applyDecay(pet, now).state, PetState.dead);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Integridad de stats (clamp + timestamps)
  // ---------------------------------------------------------------------------
  group('integridad de stats', () {
    final base = DateTime(2026, 1, 1, 10);

    test('ningún stat baja de 0 tras 100 horas con stats mínimos', () {
      final pet = buildPet(
        now: base,
        lastInteraction: base.subtract(const Duration(hours: 100)),
        stats: const PetStats(
          hunger: 5,
          mood: 5,
          play: 5,
          sleep: 5,
          health: 5,
          cleanliness: 5,
        ),
      );

      final result = service.applyDecay(pet, base);

      expect(result.stats.hunger, greaterThanOrEqualTo(0));
      expect(result.stats.mood, greaterThanOrEqualTo(0));
      expect(result.stats.play, greaterThanOrEqualTo(0));
      expect(result.stats.sleep, greaterThanOrEqualTo(0));
      expect(result.stats.health, greaterThanOrEqualTo(0));
      expect(result.stats.cleanliness, greaterThanOrEqualTo(0));
    });

    test('lastInteraction se actualiza a "now" tras decay efectivo', () {
      final now = DateTime(2026, 1, 1, 10);
      final past = now.subtract(const Duration(hours: 2));
      final pet = buildPet(now: now, lastInteraction: past);

      expect(service.applyDecay(pet, now).lastInteraction, now);
    });

    test('daysAlive se recalcula desde createdAt, no desde el valor previo', () {
      final now = DateTime(2026, 1, 10);
      final pet = Pet(
        id: 'test-id',
        name: 'Pixel',
        stage: PetStage.adult,
        stats: const PetStats(),
        lastInteraction: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 8)),
        daysAlive: 5, // valor desactualizado intencionalmente
      );

      final result = service.applyDecay(pet, now);

      // now - createdAt = 8 días
      expect(result.daysAlive, 8);
    });
  });
}
