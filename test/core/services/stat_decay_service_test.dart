import 'package:flutter_test/flutter_test.dart';
import 'package:huom/core/services/stat_decay_service.dart';
import 'package:huom/features/pet/domain/entities/pet.dart';

void main() {
  late StatDecayService service;

  setUp(() {
    service = StatDecayService();
  });

  // Helper: construye una Pet con timestamps controlados
  Pet buildPet({
    required DateTime now,
    required DateTime lastInteraction,
    PetStage stage = PetStage.adult,
    PetMutation mutation = PetMutation.slimeBit,
    PetStats? stats,
    int daysAlive = 5,
  }) {
    return Pet(
      id: 'test-id',
      name: 'Pixel',
      stage: stage,
      mutation: mutation,
      stats: stats ?? const PetStats(),
      lastInteraction: lastInteraction,
      createdAt: now.subtract(Duration(days: daysAlive)),
      daysAlive: daysAlive,
    );
  }

  group('StatDecayService.applyDecay', () {
    test('dado mascota muerta, cuando aplico decay, no muta nada', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 5)),
      ).copyWith(state: PetState.dead);

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result, same(pet));
    });

    test('dado <36 segundos transcurridos, no aplica decay ni mueve el reloj',
        () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(seconds: 30)),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.stats.hunger, pet.stats.hunger);
      expect(result.lastInteraction, pet.lastInteraction);
    });

    test('dado 1 hora transcurrida con stage adult, decae cantidades base', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 1)),
        stage: PetStage.adult,
        stats: const PetStats(
          hunger: 100,
          mood: 100,
          play: 100,
          sleep: 100,
        ),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert (1h * stage 1.0 * mut 1.0)
      expect(result.stats.hunger, closeTo(100 - 3.0, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5, 0.01));
    });

    test('dado etapa baby, decay aplica multiplicador 1.2', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 1)),
        stage: PetStage.baby,
        stats: const PetStats(hunger: 100),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.stats.hunger, closeTo(100 - 3.0 * 1.2, 0.01));
    });

    test('dado etapa elder, decay aplica multiplicador 0.8', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 1)),
        stage: PetStage.elder,
        stats: const PetStats(hunger: 100),
        daysAlive: 25,
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.stats.hunger, closeTo(100 - 3.0 * 0.8, 0.01));
    });

    test('dado mutación shadowBone, decay 1.3x en todos los stats', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 1)),
        mutation: PetMutation.shadowBone,
        stats: const PetStats(
          hunger: 100,
          mood: 100,
          play: 100,
          sleep: 100,
        ),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.stats.hunger, closeTo(100 - 3.0 * 1.3, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 1.3, 0.01));
      expect(result.stats.play, closeTo(100 - 2.0 * 1.3, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 1.3, 0.01));
    });

    test('dado mutación cactusRex, hunger y sleep decaen menos, mood más', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 1)),
        mutation: PetMutation.cactusRex,
        stats: const PetStats(
          hunger: 100,
          mood: 100,
          play: 100,
          sleep: 100,
        ),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.stats.hunger, closeTo(100 - 3.0 * 0.7, 0.01));
      expect(result.stats.mood, closeTo(100 - 1.5 * 1.2, 0.01));
      expect(result.stats.sleep, closeTo(100 - 2.5 * 0.8, 0.01));
    });

    test('dado hunger=0 y >=6h transcurridas, mascota muere por hambre', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 7)),
        stats: const PetStats(
          hunger: 0,
          mood: 50,
          play: 50,
          sleep: 50,
        ),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.state, PetState.dead);
    });

    test('dado health<20, estado pasa a sick (no muere todavía)', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 1)),
        stats: const PetStats(
          health: 15,
          hunger: 80,
          mood: 80,
          play: 80,
          sleep: 80,
        ),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.state, PetState.sick);
    });

    test('dado hunger<25, estado pasa a stressed', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 1)),
        stats: const PetStats(
          hunger: 23,
          mood: 80,
          play: 80,
          sleep: 80,
          health: 100,
        ),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.state, PetState.stressed);
    });

    test('caso borde: stats no se vuelven negativos (clamp en 0)', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = buildPet(
        now: now,
        lastInteraction: now.subtract(const Duration(hours: 100)),
        stats: const PetStats(hunger: 5),
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.stats.hunger, 0);
    });

    test('elder con daysAlive>=30 muere por vejez aunque stats estén ok', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final pet = Pet(
        id: 'old',
        name: 'Anciano',
        stage: PetStage.elder,
        stats: const PetStats(),
        lastInteraction: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 31)),
        daysAlive: 31,
      );

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.state, PetState.dead);
    });

    test('lastInteraction se actualiza al aplicar decay efectivo', () {
      // Arrange
      final now = DateTime(2026, 1, 1, 10);
      final past = now.subtract(const Duration(hours: 2));
      final pet = buildPet(now: now, lastInteraction: past);

      // Act
      final result = service.applyDecay(pet, now);

      // Assert
      expect(result.lastInteraction, now);
    });
  });
}
