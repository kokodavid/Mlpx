// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_assessment_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAssessmentProgressAdapter
    extends TypeAdapter<CourseAssessmentProgress> {
  @override
  final int typeId = 18;

  @override
  CourseAssessmentProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseAssessmentProgress(
      id: fields[0] as String,
      userId: fields[1] as String,
      sublevelId: fields[2] as String,
      assessmentId: fields[3] as String,
      score: fields[4] as int?,
      attempts: fields[7] as int,
      answers: (fields[8] as Map?)?.cast<String, dynamic>(),
      startedAt: fields[9] as DateTime?,
      completedAt: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CourseAssessmentProgress obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.sublevelId)
      ..writeByte(3)
      ..write(obj.assessmentId)
      ..writeByte(4)
      ..write(obj.score)
      ..writeByte(7)
      ..write(obj.attempts)
      ..writeByte(8)
      ..write(obj.answers)
      ..writeByte(9)
      ..write(obj.startedAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAssessmentProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
