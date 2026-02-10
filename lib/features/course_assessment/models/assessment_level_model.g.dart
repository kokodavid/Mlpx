// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_level_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssessmentLevelAdapter extends TypeAdapter<AssessmentLevel> {
  @override
  final int typeId = 16;

  @override
  AssessmentLevel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssessmentLevel(
      id: fields[0] as String,
      assessmentId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      displayOrder: fields[4] as int,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AssessmentLevel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assessmentId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.displayOrder)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
