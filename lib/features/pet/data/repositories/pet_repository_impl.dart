import 'package:hive/hive.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/pet_repository.dart';
import '../models/pet_model.dart';
import '../models/pet_mapper.dart';

class PetRepositoryImpl implements PetRepository {
  static const String _boxName = 'pets';

  Future<Box<PetModel>> get _box async => Hive.openBox<PetModel>(_boxName);

  @override
  Future<Pet?> getActivePet() async {
    final box = await _box;
    if (box.isEmpty) return null;
    return box.values.first.toEntity();
  }

  @override
  Future<void> savePet(Pet pet) async {
    final box = await _box;
    await box.put(pet.id, pet.toModel());
  }

  @override
  Future<void> deleteActivePet() async {
    final box = await _box;
    await box.clear();
  }

  @override
  Stream<Pet?> watchActivePet() async* {
    final box = await _box;
    yield box.isEmpty ? null : box.values.first.toEntity();
    await for (final _ in box.watch()) {
      yield box.isEmpty ? null : box.values.first.toEntity();
    }
  }
}
