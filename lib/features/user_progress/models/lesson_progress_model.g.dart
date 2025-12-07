// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonProgressModelAdapter extends TypeAdapter<LessonProgressModel> {
  @override
  final int typeId = 10;

  @override
  LessonProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonProgressModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      lessonId: fields[2] as String,
      courseProgressId: fields[3] as String,
      status: fields[4] as String,
      startedAt: fields[5] as DateTime?,
      completedAt: fields[6] as DateTime?,
      videoProgress: fields[7] as int?,
      quizScore: fields[8] as int?,
      quizAttemptedAt: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      needsSync: fields[12] as bool,
      quizTotalQuestions: fields[13] as int?,
      lessonTitle: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonProgressModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.lessonId)
      ..writeByte(3)
      ..write(obj.courseProgressId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.startedAt)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.videoProgress)
      ..writeByte(8)
      ..write(obj.quizScore)
      ..writeByte(9)
      ..write(obj.quizAttemptedAt)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.needsSync)
      ..writeByte(13)
      ..write(obj.quizTotalQuestions)
      ..writeByte(14)
      ..write(obj.lessonTitle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
