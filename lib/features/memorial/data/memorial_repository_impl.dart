import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../domain/memorial_repository.dart';
import '../domain/pet_memorial.dart';
import '../domain/pet_memorial_model.dart';

class MemorialRepositoryImpl implements MemorialRepository {
  static const String _boxName = 'memorials';

  Future<Box<PetMemorialModel>> get _box async =>
      Hive.openBox<PetMemorialModel>(_boxName);

  @override
  Future<void> saveMemorial(PetMemorial memorial) async {
    final box = await _box;
    final model = PetMemorialModel()
      ..id = const Uuid().v4()
      ..petName = memorial.petName
      ..mutationName = memorial.mutationName
      ..causeOfDeath = memorial.causeOfDeath
      ..daysAlive = memorial.daysAlive
      ..diedAt = memorial.diedAt;
    await box.put(model.id, model);
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
