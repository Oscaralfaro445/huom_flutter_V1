import '../../domain/entities/pet.dart';
import 'pet_model.dart';

extension PetMapper on PetModel {
  Pet toEntity() {
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
      ),
      lastInteraction: lastInteraction,
      createdAt: createdAt,
      daysAlive: daysAlive,
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
      ..lastInteraction = lastInteraction
      ..createdAt = createdAt
      ..daysAlive = daysAlive;
  }
}
