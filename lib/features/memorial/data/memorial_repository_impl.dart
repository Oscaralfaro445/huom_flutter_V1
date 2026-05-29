import 'package:hive/hive.dart';
import '../../../../core/services/cloud_save_service.dart';
import '../domain/memorial_repository.dart';
import '../domain/pet_memorial.dart';
import '../domain/pet_memorial_model.dart';

class MemorialRepositoryImpl implements MemorialRepository {
  static const String _boxName = 'memorials';

  final CloudSaveService _cloudSave;

  MemorialRepositoryImpl(this._cloudSave);

  Future<Box<PetMemorialModel>> get _box async =>
      Hive.openBox<PetMemorialModel>(_boxName);

  @override
  Future<void> saveMemorial(PetMemorial memorial) async {
    final box = await _box;
    final model = PetMemorialModel()
      ..id = memorial.id
      ..petName = memorial.petName
      ..mutationName = memorial.mutationName
      ..causeOfDeath = memorial.causeOfDeath
      ..daysAlive = memorial.daysAlive
      ..diedAt = memorial.diedAt;
    await box.put(model.id, model);
    _cloudSave.saveMemorial(memorial);
  }

  @override
  Future<List<PetMemorial>> getAllMemorials() async {
    final box = await _box;
    return box.values
        .map((m) => PetMemorial(
              id: m.id,
              petName: m.petName,
              mutationName: m.mutationName,
              causeOfDeath: m.causeOfDeath,
              daysAlive: m.daysAlive,
              diedAt: m.diedAt,
            ))
        .toList()
      ..sort((a, b) => b.diedAt.compareTo(a.diedAt));
  }
}
