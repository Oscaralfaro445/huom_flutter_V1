import '../../../../core/services/coins_service.dart';
import '../../../../core/services/stat_decay_service.dart';
import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

enum TreatmentItem {
  antihistamine(
    displayName: 'Antihistamínico',
    description: 'Cura el resfriado',
    cost: 15,
    icon: '💊',
    cures: [ConditionType.cold],
    healthBonus: 0,
    sleepBonus: 0,
  ),
  antibiotic(
    displayName: 'Antibiótico',
    description: 'Cura la gripe',
    cost: 35,
    icon: '🧪',
    cures: [ConditionType.flu],
    healthBonus: 0,
    sleepBonus: 0,
  ),
  strongAntibiotic(
    displayName: 'Antibiótico Fuerte',
    description: 'Cura la fiebre',
    cost: 60,
    icon: '💉',
    cures: [ConditionType.fever],
    healthBonus: 0,
    sleepBonus: 0,
  ),
  bandage(
    displayName: 'Venda',
    description: 'Cura lesiones leves y graves',
    cost: 20,
    icon: '🩹',
    cures: [ConditionType.minorInjury, ConditionType.seriousInjury],
    healthBonus: 0,
    sleepBonus: 0,
  ),
  vitamins(
    displayName: 'Vitaminas',
    description: '+20 de salud',
    cost: 25,
    icon: '🌿',
    cures: [],
    healthBonus: 20,
    sleepBonus: 0,
  ),
  forcedRest(
    displayName: 'Descanso Forzado',
    description: 'Cura el agotamiento, +40 sueño',
    cost: 0,
    icon: '😴',
    cures: [ConditionType.exhaustion],
    healthBonus: 0,
    sleepBonus: 40,
  );

  const TreatmentItem({
    required this.displayName,
    required this.description,
    required this.cost,
    required this.icon,
    required this.cures,
    required this.healthBonus,
    required this.sleepBonus,
  });

  final String displayName;
  final String description;
  final int cost;
  final String icon;
  final List<ConditionType> cures;
  final double healthBonus;
  final double sleepBonus;
}

class TreatPetUseCase {
  final PetRepository _repository;
  final CoinsService _coinsService;
  final StatDecayService _decayService;

  TreatPetUseCase(this._repository, this._coinsService, this._decayService);

  /// Retorna null si no hay mascota activa.
  /// Retorna el pet sin cambios si no puede pagar.
  Future<Pet?> call(TreatmentItem treatment) async {
    final pet = await _repository.getActivePet();
    if (pet == null) return null;

    final coins = await _coinsService.getCoins();
    if (coins < treatment.cost) return pet;

    final decayedPet = _decayService.applyDecay(pet, DateTime.now());

    final newConditions = decayedPet.conditions
        .where((c) => !treatment.cures.contains(c.type))
        .toList();

    final newStats = decayedPet.stats.copyWith(
      health: decayedPet.stats.health + treatment.healthBonus,
      sleep: decayedPet.stats.sleep + treatment.sleepBonus,
    );

    final treatedPet = decayedPet.copyWith(
      conditions: newConditions,
      stats: newStats,
    );

    if (treatment.cost > 0) {
      await _coinsService.spendCoins(treatment.cost);
    }

    await _repository.savePet(treatedPet);
    return treatedPet;
  }
}
