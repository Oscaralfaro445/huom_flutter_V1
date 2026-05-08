import 'package:uuid/uuid.dart';
import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class CreatePetUseCase {
  final PetRepository _repository;

  CreatePetUseCase(this._repository);

  /// Crea una nueva mascota.
  ///
  /// Si [mutation] se proporciona, la mascota arranca como [PetStage.baby]
  /// con esa mutación visible desde el primer momento. Si no, arranca como
  /// huevo neutral (slimeBit por defecto) y obtendrá su mutación al evolucionar.
  Future<Pet> call(String name, {PetMutation? mutation}) async {
    final now = DateTime.now();
    final pet = Pet(
      id: const Uuid().v4(),
      name: name,
      stage: mutation != null ? PetStage.baby : PetStage.egg,
      state: PetState.happy,
      stats: const PetStats(),
      mutation: mutation ?? PetMutation.slimeBit,
      lastInteraction: now,
      createdAt: now,
    );

    await _repository.savePet(pet);
    return pet;
  }
}
