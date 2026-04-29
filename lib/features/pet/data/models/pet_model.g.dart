// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetModelAdapter extends TypeAdapter<PetModel> {
  @override
  final int typeId = 0;

  @override
  PetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetModel()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..stageIndex = fields[2] as int
      ..stateIndex = fields[3] as int
      ..mutationIndex = fields[4] as int
      ..biomeId = fields[5] as String
      ..hunger = fields[6] as double
      ..mood = fields[7] as double
      ..play = fields[8] as double
      ..sleep = fields[9] as double
      ..health = fields[10] as double
      ..lastInteraction = fields[11] as DateTime
      ..createdAt = fields[12] as DateTime
      ..daysAlive = fields[13] as int;
  }

  @override
  void write(BinaryWriter writer, PetModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.stageIndex)
      ..writeByte(3)
      ..write(obj.stateIndex)
      ..writeByte(4)
      ..write(obj.mutationIndex)
      ..writeByte(5)
      ..write(obj.biomeId)
      ..writeByte(6)
      ..write(obj.hunger)
      ..writeByte(7)
      ..write(obj.mood)
      ..writeByte(8)
      ..write(obj.play)
      ..writeByte(9)
      ..write(obj.sleep)
      ..writeByte(10)
      ..write(obj.health)
      ..writeByte(11)
      ..write(obj.lastInteraction)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.daysAlive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
