import 'pet_memorial.dart';

abstract class MemorialRepository {
  Future<void> saveMemorial(PetMemorial memorial);
  Future<List<PetMemorial>> getAllMemorials();
}
