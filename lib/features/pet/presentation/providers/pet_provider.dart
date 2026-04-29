import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/stat_decay_service.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../../domain/usecases/feed_pet_usecase.dart';
import '../../domain/usecases/sleep_usecase.dart';
import '../../domain/usecases/play_usecase.dart';
import '../../domain/usecases/bathe_usecase.dart';
import '../../domain/usecases/create_pet_usecase.dart';

// Provider principal que escucha la mascota en tiempo real
final petStreamProvider = StreamProvider<Pet?>((ref) {
  return sl<PetRepository>().watchActivePet();
});

// Notifier para acciones sobre la mascota
final petActionsProvider =
    AsyncNotifierProvider<PetActionsNotifier, Pet?>(PetActionsNotifier.new);

class PetActionsNotifier extends AsyncNotifier<Pet?> {
  @override
  Future<Pet?> build() async {
    // Aplicar decay al abrir la app
    final repository = sl<PetRepository>();
    final decayService = sl<StatDecayService>();
    final pet = await repository.getActivePet();
    if (pet != null) {
      final decayedPet = decayService.applyDecay(pet, DateTime.now());
      await repository.savePet(decayedPet);
      return decayedPet;
    }
    return null;
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
  }

  Future<void> playWithPet() async {
    state = await AsyncValue.guard(
      () => sl<PlayUseCase>().call(),
    );
  }

  Future<void> sleepPet() async {
    state = await AsyncValue.guard(
      () => sl<SleepUseCase>().call(),
    );
  }

  Future<void> bathePet() async {
    state = await AsyncValue.guard(
      () => sl<BatheUseCase>().call(),
    );
  }
}
