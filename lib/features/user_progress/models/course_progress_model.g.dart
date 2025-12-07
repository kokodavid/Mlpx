// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseProgressModelAdapter extends TypeAdapter<CourseProgressModel> {
  @override
  final int typeId = 11;

  @override
  CourseProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseProgressModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      courseId: fields[2] as String,
      startedAt: fields[3] as DateTime?,
      completedAt: fields[4] as DateTime?,
      currentModuleId: fields[5] as String?,
      currentLessonId: fields[6] as String?,
      isCompleted: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      needsSync: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CourseProgressModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.courseId)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.completedAt)
      ..writeByte(5)
      ..write(obj.currentModuleId)
      ..writeByte(6)
      ..write(obj.currentLessonId)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
