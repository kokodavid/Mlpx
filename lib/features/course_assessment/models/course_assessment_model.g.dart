// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_assessment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAssessmentAdapter extends TypeAdapter<CourseAssessment> {
  @override
  final int typeId = 15;

  @override
  CourseAssessment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseAssessment(
      id: fields[0] as String,
      courseId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      isActive: fields[4] as bool,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CourseAssessment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.courseId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.isActive)
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
      other is CourseAssessmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
