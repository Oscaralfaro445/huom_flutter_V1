import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../../../../core/services/stat_decay_service.dart';

class SleepUseCase {
  final PetRepository _repository;
  final StatDecayService _decayService;

  SleepUseCase(this._repository, this._decayService);

  Future<Pet> call() async {
    final pet = await _repository.getActivePet();
    if (pet == null) throw Exception('No hay mascota activa');

    final decayedPet = _decayService.applyDecay(pet, DateTime.now());

    // El sueño sube 4pts por minuto real — aquí registramos
    // el inicio del sueño. El cálculo real ocurre al despertar.
    final newStats = decayedPet.stats.copyWith(
      sleep: (decayedPet.stats.sleep + 30).clamp(0, 100),
      mood: decayedPet.stats.mood - 5, // cansancio acumulado
    );

    final updatedPet = decayedPet.copyWith(
      stats: newStats,
      lastInteraction: DateTime.now(),
    );

    await _repository.savePet(updatedPet);
    return updatedPet;
  }
}
