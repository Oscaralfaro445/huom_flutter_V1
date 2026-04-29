import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../../../../core/services/stat_decay_service.dart';

enum FoodItem {
  basicFood(hungerBonus: 25, moodBonus: 0, cost: 10),
  premiumFood(hungerBonus: 40, moodBonus: 5, cost: 30),
  snack(hungerBonus: 10, moodBonus: 0, cost: 5),
  specialFood(hungerBonus: 35, moodBonus: 10, cost: 40);

  final double hungerBonus;
  final double moodBonus;
  final int cost;

  const FoodItem({
    required this.hungerBonus,
    required this.moodBonus,
    required this.cost,
  });
}

class FeedPetUseCase {
  final PetRepository _repository;
  final StatDecayService _decayService;

  FeedPetUseCase(this._repository, this._decayService);

  Future<Pet> call(FoodItem food) async {
    final pet = await _repository.getActivePet();
    if (pet == null) throw Exception('No hay mascota activa');

    // Primero aplicar decay pendiente
    final decayedPet = _decayService.applyDecay(pet, DateTime.now());

    // Aplicar efecto del alimento
    final newStats = decayedPet.stats.copyWith(
      hunger: decayedPet.stats.hunger + food.hungerBonus,
      mood: decayedPet.stats.mood + food.moodBonus,
    );

    final updatedPet = decayedPet.copyWith(
      stats: newStats,
      lastInteraction: DateTime.now(),
    );

    await _repository.savePet(updatedPet);
    return updatedPet;
  }
}
