import 'package:flutter_test/flutter_test.dart';
import 'package:huom/core/services/mutation_check_service.dart';
import 'package:huom/core/services/mutation_history_tracker.dart';
import 'package:huom/features/pet/domain/entities/pet.dart';

void main() {
  late MutationCheckService service;

  setUp(() {
    service = MutationCheckService();
  });

  StatAverages avg({
    double hunger = 65,
    double mood = 65,
    double play = 65,
    double sleep = 65,
    double health = 70,
  }) =>
      StatAverages(
        hunger: hunger,
        mood: mood,
        play: play,
        sleep: sleep,
        health: health,
      );

  group('MutationCheckService.checkMutation', () {
    test('shadowBone — health promedio < 30', () {
      final result = service.checkMutation(avg(health: 25));
      expect(result, PetMutation.shadowBone);
    });

    test('shadowBone tiene prioridad sobre cactusRex cuando health < 30', () {
      // health crítica Y también hambre/sueño bajos
      final result = service.checkMutation(
        avg(hunger: 35, sleep: 35, health: 25),
      );
      expect(result, PetMutation.shadowBone);
    });

    test('cactusRex — hunger < 40 AND sleep < 40 (health ok)', () {
      final result = service.checkMutation(
        avg(hunger: 35, sleep: 35, health: 60),
      );
      expect(result, PetMutation.cactusRex);
    });

    test('cactusRex no activa si solo hunger es bajo', () {
      final result = service.checkMutation(
        avg(hunger: 35, sleep: 65, health: 60),
      );
      expect(result, isNot(PetMutation.cactusRex));
    });

    test('thunderLeaf — play promedio > 70', () {
      final result = service.checkMutation(avg(play: 75));
      expect(result, PetMutation.thunderLeaf);
    });

    test('blossom — mood promedio > 75', () {
      // play=60 para no disparar thunderLeaf
      final result = service.checkMutation(avg(mood: 80, play: 60));
      expect(result, PetMutation.blossom);
    });

    test('aquaSlime — health > 75 AND mood > 60', () {
      // play=60, mood=65 (< 75 → no blossom), health=80
      final result = service.checkMutation(
        avg(mood: 65, play: 60, health: 80),
      );
      expect(result, PetMutation.aquaSlime);
    });

    test('aquaSlime no activa si mood <= 60', () {
      final result = service.checkMutation(
        avg(mood: 58, play: 60, health: 80),
      );
      expect(result, isNot(PetMutation.aquaSlime));
    });

    test('glitchPet — cuidado mediocre (overall < 65)', () {
      // Todos en 50 → overall = 50 < 65
      final result = service.checkMutation(
        avg(hunger: 50, mood: 50, play: 50, sleep: 50, health: 50),
      );
      expect(result, PetMutation.glitchPet);
    });

    test('slimeBit — cuidado balanceado (overall >= 65, sin otras condiciones)', () {
      // Todos en 70 → overall = 70, ninguna condición especial activa
      final result = service.checkMutation(
        avg(hunger: 70, mood: 70, play: 70, sleep: 70, health: 70),
      );
      expect(result, PetMutation.slimeBit);
    });

    test('prioridad: thunderLeaf gana sobre blossom si ambas condiciones aplican', () {
      // play > 70 Y mood > 75
      final result = service.checkMutation(
        avg(mood: 80, play: 75, health: 60),
      );
      expect(result, PetMutation.thunderLeaf);
    });
  });

  group('StatAverages.overall', () {
    test('calcula el promedio correcto de los 5 stats', () {
      const averages = StatAverages(
        hunger: 80,
        mood: 60,
        play: 40,
        sleep: 50,
        health: 70,
      );
      expect(averages.overall, closeTo(60.0, 0.001));
    });
  });
}
