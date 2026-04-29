import 'package:hive/hive.dart';

part 'pet_memorial_model.g.dart';

@HiveType(typeId: 1)
class PetMemorialModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String petName;

  @HiveField(2)
  late String mutationName;

  @HiveField(3)
  late String causeOfDeath;

  @HiveField(4)
  late int daysAlive;

  @HiveField(5)
  late DateTime diedAt;
}
