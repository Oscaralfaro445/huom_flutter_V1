import 'package:hive/hive.dart';

part 'pet_model.g.dart';

@HiveType(typeId: 0)
class PetModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int stageIndex;

  @HiveField(3)
  late int stateIndex;

  @HiveField(4)
  late int mutationIndex;

  @HiveField(5)
  late String biomeId;

  @HiveField(6)
  late double hunger;

  @HiveField(7)
  late double mood;

  @HiveField(8)
  late double play;

  @HiveField(9)
  late double sleep;

  @HiveField(10)
  late double health;

  @HiveField(11)
  late DateTime lastInteraction;

  @HiveField(12)
  late DateTime createdAt;

  @HiveField(13)
  late int daysAlive;
}
