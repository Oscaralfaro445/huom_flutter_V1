import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../../../../core/services/stat_decay_service.dart';

class BatheUseCase {
  final PetRepository _repository;
  final StatDecayService _decayService;

  BatheUseCase(this._repository, this._decayService);

  Future<Pet> call() async {
    final pet = await _repository.getActivePet();
    if (pet == null) throw Exception('No hay mascota activa');

    final decayedPet = _decayService.applyDecay(pet, DateTime.now());

    final newStats = decayedPet.stats.copyWith(
      mood: decayedPet.stats.mood + 20,
      health: decayedPet.stats.health + 10,
      sleep: decayedPet.stats.sleep - 5,
    );

    final updatedPet = decayedPet.copyWith(
      stats: newStats,
      lastInteraction: DateTime.now(),
    );

    await _repository.savePet(updatedPet);
    return updatedPet;
  }
}
