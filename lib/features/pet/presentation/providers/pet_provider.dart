import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
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

final petActionsProvider =
    AsyncNotifierProvider<PetActionsNotifier, Pet?>(PetActionsNotifier.new);

class PetActionsNotifier extends AsyncNotifier<Pet?> {
  @override
  Future<Pet?> build() async {
    final repository = sl<PetRepository>();
    final decayService = sl<StatDecayService>();
    final pet = await repository.getActivePet();

    if (pet == null) return null;

    // Aplicar decay al abrir la app
    final decayedPet = decayService.applyDecay(pet, DateTime.now());
    await repository.savePet(decayedPet);

    // Detectar muerte automática
    if (decayedPet.state == PetState.dead) {
      await _handleDeath(decayedPet);
      return null;
    }

    return decayedPet;
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

    // Releer desde repositorio para tener el estado más actualizado
    final fresh = await sl<PetRepository>().getActivePet();
    if (fresh == null) return;

    if (fresh.state == PetState.dead) {
      await _handleDeath(fresh);
      state = const AsyncData(null);
    }
  }
}
