import '../../domain/entities/pet.dart';
import 'pet_model.dart';

extension PetMapper on PetModel {
  Pet toEntity() {
    final conditions = <PetCondition>[];
    for (int i = 0; i < conditionTypeIndexes.length; i++) {
      final typeIdx = conditionTypeIndexes[i];
      if (typeIdx < 0 || typeIdx >= ConditionType.values.length) continue;
      final timestamp = i < conditionTimestamps.length
          ? conditionTimestamps[i]
          : DateTime.now().millisecondsSinceEpoch;
      conditions.add(PetCondition(
        type: ConditionType.values[typeIdx],
        contractedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
      ));
    }

    return Pet(
      id: id,
      name: name,
      stage: PetStage.values[stageIndex],
      state: PetState.values[stateIndex],
      mutation: PetMutation.values[mutationIndex],
      biomeId: biomeId,
      stats: PetStats(
        hunger: hunger,
        mood: mood,
        play: play,
        sleep: sleep,
        health: health,
        cleanliness: cleanliness,
      ),
      lastInteraction: lastInteraction,
      createdAt: createdAt,
      daysAlive: daysAlive,
      conditions: conditions,
    );
  }
}

extension PetEntityMapper on Pet {
  PetModel toModel() {
    return PetModel()
      ..id = id
      ..name = name
      ..stageIndex = stage.index
      ..stateIndex = state.index
      ..mutationIndex = mutation.index
      ..biomeId = biomeId
      ..hunger = stats.hunger
      ..mood = stats.mood
      ..play = stats.play
      ..sleep = stats.sleep
      ..health = stats.health
      ..cleanliness = stats.cleanliness
      ..lastInteraction = lastInteraction
      ..createdAt = createdAt
      ..daysAlive = daysAlive
      ..conditionTypeIndexes =
          conditions.map((c) => c.type.index).toList()
      ..conditionTimestamps =
          conditions
              .map((c) => c.contractedAt.millisecondsSinceEpoch)
              .toList();
  }
}
