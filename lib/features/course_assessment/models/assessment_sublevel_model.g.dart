// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_sublevel_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssessmentSublevelAdapter extends TypeAdapter<AssessmentSublevel> {
  @override
  final int typeId = 17;

  @override
  AssessmentSublevel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssessmentSublevel(
      id: fields[0] as String,
      levelId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      displayOrder: fields[4] as int,
      questions: (fields[5] as List).cast<dynamic>(),
      passingScore: fields[6] as int,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AssessmentSublevel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.levelId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.displayOrder)
      ..writeByte(5)
      ..write(obj.questions)
      ..writeByte(6)
      ..write(obj.passingScore)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssessmentSublevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
