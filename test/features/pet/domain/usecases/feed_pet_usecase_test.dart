import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:huom/core/services/stat_decay_service.dart';
import 'package:huom/features/pet/domain/entities/pet.dart';
import 'package:huom/features/pet/domain/repositories/pet_repository.dart';
import 'package:huom/features/pet/domain/usecases/feed_pet_usecase.dart';

class _MockPetRepository extends Mock implements PetRepository {}

class _MockStatDecayService extends Mock implements StatDecayService {}

void main() {
  late _MockPetRepository repo;
  late _MockStatDecayService decay;
  late FeedPetUseCase useCase;

  Pet anyPet() => Pet(
        id: 'fallback',
        name: 'fallback',
        stats: const PetStats(),
        lastInteraction: DateTime(2026),
        createdAt: DateTime(2026),
      );

  setUpAll(() {
    registerFallbackValue(anyPet());
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = _MockPetRepository();
    decay = _MockStatDecayService();
    useCase = FeedPetUseCase(repo, decay);
  });

  group('FeedPetUseCase', () {
    test('dado no hay mascota activa, lanza Exception', () {
      // Arrange
      when(() => repo.getActivePet()).thenAnswer((_) async => null);

      // Act / Assert
      expect(() => useCase.call(FoodItem.basicFood), throwsException);
    });

    test('dado mascota viva con basicFood, suma hungerBonus tras decay y guarda',
        () async {
      // Arrange
      final now = DateTime(2026);
      final initial = Pet(
        id: 'p1',
        name: 'Pixel',
        stats: const PetStats(hunger: 50, mood: 60),
        lastInteraction: now,
        createdAt: now,
      );
      when(() => repo.getActivePet()).thenAnswer((_) async => initial);
      when(() => decay.applyDecay(any(), any())).thenReturn(initial);
      when(() => repo.savePet(any())).thenAnswer((_) async {});

      // Act
      final result = await useCase.call(FoodItem.basicFood);

      // Assert: basicFood = +25 hunger, +0 mood
      expect(result.stats.hunger, 75);
      expect(result.stats.mood, 60);
      verify(() => repo.savePet(any())).called(1);
    });

    test('dado specialFood, sube tanto hunger como mood', () async {
      // Arrange
      final now = DateTime(2026);
      final initial = Pet(
        id: 'p1',
        name: 'Pixel',
        stats: const PetStats(hunger: 50, mood: 60),
        lastInteraction: now,
        createdAt: now,
      );
      when(() => repo.getActivePet()).thenAnswer((_) async => initial);
      when(() => decay.applyDecay(any(), any())).thenReturn(initial);
      when(() => repo.savePet(any())).thenAnswer((_) async {});

      // Act
      final result = await useCase.call(FoodItem.specialFood);

      // Assert: specialFood = +35 hunger, +10 mood
      expect(result.stats.hunger, 85);
      expect(result.stats.mood, 70);
    });

    test('dado snack, suma 10 a hunger sin tocar mood', () async {
      // Arrange
      final now = DateTime(2026);
      final initial = Pet(
        id: 'p1',
        name: 'Pixel',
        stats: const PetStats(hunger: 40, mood: 50),
        lastInteraction: now,
        createdAt: now,
      );
      when(() => repo.getActivePet()).thenAnswer((_) async => initial);
      when(() => decay.applyDecay(any(), any())).thenReturn(initial);
      when(() => repo.savePet(any())).thenAnswer((_) async {});

      // Act
      final result = await useCase.call(FoodItem.snack);

      // Assert: snack = +10 hunger, +0 mood
      expect(result.stats.hunger, 50);
      expect(result.stats.mood, 50);
    });

    test('caso borde: hunger se cap a 100 al alimentar cerca del máximo',
        () async {
      // Arrange
      final now = DateTime(2026);
      final initial = Pet(
        id: 'p1',
        name: 'Pixel',
        stats: const PetStats(hunger: 95),
        lastInteraction: now,
        createdAt: now,
      );
      when(() => repo.getActivePet()).thenAnswer((_) async => initial);
      when(() => decay.applyDecay(any(), any())).thenReturn(initial);
      when(() => repo.savePet(any())).thenAnswer((_) async {});

      // Act: basicFood = +25 → debería capar a 100
      final result = await useCase.call(FoodItem.basicFood);

      // Assert
      expect(result.stats.hunger, 100);
    });

    test('decay se aplica antes que el bonus de comida (orden correcto)',
        () async {
      // Arrange
      final now = DateTime(2026);
      final initial = Pet(
        id: 'p1',
        name: 'Pixel',
        stats: const PetStats(hunger: 50),
        lastInteraction: now,
        createdAt: now,
      );
      // decay devuelve hunger=40 (perdió 10 puntos)
      final afterDecay = initial.copyWith(
        stats: initial.stats.copyWith(hunger: 40),
      );
      when(() => repo.getActivePet()).thenAnswer((_) async => initial);
      when(() => decay.applyDecay(any(), any())).thenReturn(afterDecay);
      when(() => repo.savePet(any())).thenAnswer((_) async {});

      // Act: basicFood +25 sobre 40 (post-decay) = 65
      final result = await useCase.call(FoodItem.basicFood);

      // Assert
      expect(result.stats.hunger, 65);
      verify(() => decay.applyDecay(initial, any())).called(1);
    });
  });

  group('FoodItem', () {
    test('cada item tiene los costos esperados', () {
      // Assert (tabla de referencia para el equipo de gameplay)
      expect(FoodItem.basicFood.cost, 10);
      expect(FoodItem.premiumFood.cost, 30);
      expect(FoodItem.snack.cost, 5);
      expect(FoodItem.specialFood.cost, 40);
    });

    test('premiumFood otorga el mayor hungerBonus de comidas', () {
      // Arrange/Assert
      expect(
        FoodItem.premiumFood.hungerBonus,
        greaterThan(FoodItem.specialFood.hungerBonus),
      );
      expect(
        FoodItem.premiumFood.hungerBonus,
        greaterThan(FoodItem.basicFood.hungerBonus),
      );
    });
  });
}
