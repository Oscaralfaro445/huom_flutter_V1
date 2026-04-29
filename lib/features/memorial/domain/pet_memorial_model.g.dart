// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_memorial_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetMemorialModelAdapter extends TypeAdapter<PetMemorialModel> {
  @override
  final int typeId = 1;

  @override
  PetMemorialModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PetMemorialModel()
      ..id = fields[0] as String
      ..petName = fields[1] as String
      ..mutationName = fields[2] as String
      ..causeOfDeath = fields[3] as String
      ..daysAlive = fields[4] as int
      ..diedAt = fields[5] as DateTime;
  }

  @override
  void write(BinaryWriter writer, PetMemorialModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.petName)
      ..writeByte(2)
      ..write(obj.mutationName)
      ..writeByte(3)
      ..write(obj.causeOfDeath)
      ..writeByte(4)
      ..write(obj.daysAlive)
      ..writeByte(5)
      ..write(obj.diedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetMemorialModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
