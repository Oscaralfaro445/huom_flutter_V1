import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/mutation_check_service.dart';
import '../../../../core/services/mutation_history_tracker.dart';
import '../../../../core/services/stat_decay_service.dart';
import '../../../memorial/domain/pet_memorial.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../../domain/usecases/feed_pet_usecase.dart';
import '../../domain/usecases/sleep_usecase.dart';
import '../../domain/usecases/play_usecase.dart';
import '../../domain/usecases/bathe_usecase.dart';
import '../../domain/usecases/create_pet_usecase.dart';
import '../../domain/usecases/die_usecase.dart';

// Provider principal que escucha la mascota en tiempo real
final petStreamProvider = StreamProvider<Pet?>((ref) {
  return sl<PetRepository>().watchActivePet();
});

// Provider del memorial de muerte (se llena cuando la mascota muere)
final deathMemorialProvider = StateProvider<PetMemorial?>((ref) => null);

// Emite la mutación recién obtenida cuando baby→adult.
// GameScreen lo escucha para mostrar MutationScreen.
// Se resetea a null después de consumirlo.
final evolutionEventProvider = StateProvider<PetMutation?>((ref) => null);

final petActionsProvider =
    AsyncNotifierProvider<PetActionsNotifier, Pet?>(PetActionsNotifier.new);

class PetActionsNotifier extends AsyncNotifier<Pet?> {
  @override
  Future<Pet?> build() async {
    final repository = sl<PetRepository>();
    final decayService = sl<StatDecayService>();
    final tracker = sl<MutationHistoryTracker>();

    final pet = await repository.getActivePet();
    if (pet == null) return null;

    // Aplicar decay al abrir la app
    final decayedPet = decayService.applyDecay(pet, DateTime.now());

    // Registrar snapshot diario durante etapa Cría (una vez por día de juego)
    await tracker.recordSnapshot(decayedPet);

    // Verificar y aplicar evolución de etapa
    final evolvedPet = await _checkEvolution(decayedPet);

    await repository.savePet(evolvedPet);

    // Detectar muerte automática
    if (evolvedPet.state == PetState.dead) {
      await _handleDeath(evolvedPet);
      return null;
    }

    return evolvedPet;
  }

  /// Transiciones de etapa basadas en días vivos:
  ///   egg  → baby   (día >= 1)
  ///   baby → adult  (día >= 7, con selección de mutación)
  ///   adult → elder (día >= 20)
  Future<Pet> _checkEvolution(Pet pet) async {
    if (pet.stage == PetStage.egg && pet.daysAlive >= 1) {
      return pet.copyWith(stage: PetStage.baby);
    }

    if (pet.stage == PetStage.baby && pet.daysAlive >= 7) {
      final tracker = sl<MutationHistoryTracker>();
      final checkService = sl<MutationCheckService>();

      final averages = await tracker.getAverages(pet.id);
      final mutation = checkService.checkMutation(averages);

      // Limpiar historial para que no afecte a una vida futura
      await tracker.clearHistory(pet.id);

      // Señalizar la evolución para que GameScreen abra MutationScreen.
      // Usamos Future.microtask para no modificar otro provider durante build().
      Future.microtask(
        () => ref.read(evolutionEventProvider.notifier).state = mutation,
      );

      return pet.copyWith(stage: PetStage.adult, mutation: mutation);
    }

    if (pet.stage == PetStage.adult && pet.daysAlive >= 20) {
      return pet.copyWith(stage: PetStage.elder);
    }

    return pet;
  }

  Future<void> _handleDeath(Pet pet) async {
    String cause = 'Causa desconocida';
    if (pet.stats.hunger <= 0) cause = 'Hambre';
    if (pet.stats.health <= 0) cause = 'Enfermedad';
    if (pet.stage == PetStage.elder && pet.daysAlive >= 30) {
      cause = 'Vejez';
    }

    final memorial = await sl<DieUseCase>().call(pet, cause);

    // Guardar el memorial para mostrar en DeathScreen
    ref.read(deathMemorialProvider.notifier).state = memorial;
  }

  Future<void> createPet(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => sl<CreatePetUseCase>().call(name),
    );
  }

  Future<void> feedPet(FoodItem food) async {
    state = await AsyncValue.guard(
      () => sl<FeedPetUseCase>().call(food),
    );
    await _checkDeath();
  }

  Future<void> playWithPet() async {
    state = await AsyncValue.guard(
      () => sl<PlayUseCase>().call(),
    );
    await _checkDeath();
  }

  Future<void> sleepPet() async {
    state = await AsyncValue.guard(
      () => sl<SleepUseCase>().call(),
    );
    await _checkDeath();
  }

  Future<void> bathePet() async {
    state = await AsyncValue.guard(
      () => sl<BatheUseCase>().call(),
    );
    await _checkDeath();
  }

  Future<void> resetForNewPet() async {
    ref.read(deathMemorialProvider.notifier).state = null;
    state = const AsyncData(null);
  }

  Future<void> _checkDeath() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final fresh = await sl<PetRepository>().getActivePet();
    if (fresh == null) return;

    if (fresh.state == PetState.dead) {
      await _handleDeath(fresh);
      state = const AsyncData(null);
    }
  }
}
