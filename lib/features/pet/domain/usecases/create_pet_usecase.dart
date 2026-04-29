import 'package:uuid/uuid.dart';
import '../entities/pet.dart';
import '../repositories/pet_repository.dart';

class CreatePetUseCase {
  final PetRepository _repository;

  CreatePetUseCase(this._repository);

  Future<Pet> call(String name) async {
    final now = DateTime.now();
    final pet = Pet(
      id: const Uuid().v4(),
      name: name,
      stage: PetStage.egg,
      state: PetState.happy,
      stats: const PetStats(),
      lastInteraction: now,
      createdAt: now,
    );

    await _repository.savePet(pet);
    return pet;
  }
}
