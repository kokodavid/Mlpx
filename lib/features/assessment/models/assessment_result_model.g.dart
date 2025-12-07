// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssessmentResultModelAdapter extends TypeAdapter<AssessmentResultModel> {
  @override
  final int typeId = 14;

  @override
  AssessmentResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssessmentResultModel(
      id: fields[0] as String,
      completedAt: fields[1] as DateTime,
      stageScores: (fields[2] as Map).cast<String, int>(),
      totalQuestionsPerStage: (fields[3] as Map).cast<String, int>(),
      overallScore: fields[4] as double,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AssessmentResultModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.completedAt)
      ..writeByte(2)
      ..write(obj.stageScores)
      ..writeByte(3)
      ..write(obj.totalQuestionsPerStage)
      ..writeByte(4)
      ..write(obj.overallScore)
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
      other is AssessmentResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
