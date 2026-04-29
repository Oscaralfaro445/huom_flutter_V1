import 'package:uuid/uuid.dart';
import '../entities/pet.dart';
import '../repositories/pet_repository.dart';
import '../../../memorial/domain/memorial_repository.dart';
import '../../../memorial/domain/pet_memorial.dart';

class DieUseCase {
  final PetRepository _petRepository;
  final MemorialRepository _memorialRepository;

  DieUseCase(this._petRepository, this._memorialRepository);

  Future<PetMemorial> call(Pet pet, String causeOfDeath) async {
    // Guardar en el memorial
    final memorial = PetMemorial(
      id: const Uuid().v4(),
      petName: pet.name,
      mutationName: _getMutationName(pet.mutation),
      causeOfDeath: causeOfDeath,
      daysAlive: pet.daysAlive,
      diedAt: DateTime.now(),
    );

    await _memorialRepository.saveMemorial(memorial);

    // Eliminar mascota activa
    await _petRepository.deleteActivePet();

    return memorial;
  }

  String _getMutationName(PetMutation mutation) {
    return switch (mutation) {
      PetMutation.slimeBit => 'Slime Bit',
      PetMutation.cactusRex => 'Cactus Rex',
      PetMutation.aquaSlime => 'Aqua Slime',
      PetMutation.thunderLeaf => 'Thunder Leaf',
      PetMutation.blossom => 'Blossom',
      PetMutation.shadowBone => 'Shadow Bone',
      PetMutation.glitchPet => 'Glitch Pet',
    };
  }
}
