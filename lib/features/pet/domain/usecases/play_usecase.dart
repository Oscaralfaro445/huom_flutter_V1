import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../../../../core/services/stat_decay_service.dart';

class PlayUseCase {
  final PetRepository _repository;
  final StatDecayService _decayService;

  PlayUseCase(this._repository, this._decayService);

  Future<Pet> call() async {
    final pet = await _repository.getActivePet();
    if (pet == null) throw Exception('No hay mascota activa');

    final decayedPet = _decayService.applyDecay(pet, DateTime.now());

    final newStats = decayedPet.stats.copyWith(
      play: decayedPet.stats.play + 20,
      mood: decayedPet.stats.mood + 15,
      hunger: decayedPet.stats.hunger - 5, // jugar da hambre
      sleep: decayedPet.stats.sleep - 8, // jugar cansa
    );

    final updatedPet = decayedPet.copyWith(
      stats: newStats,
      lastInteraction: DateTime.now(),
    );

    await _repository.savePet(updatedPet);
    return updatedPet;
  }
}
