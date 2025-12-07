// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonModelAdapter extends TypeAdapter<LessonModel> {
  @override
  final int typeId = 5;

  @override
  LessonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonModel(
      id: fields[0] as String,
      moduleId: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      position: fields[4] as int,
      videoUrl: fields[5] as String?,
      audioUrl: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
      durationMinutes: fields[9] as int,
      quizzes: (fields[10] as List).cast<LessonQuizModel>(),
      thumbnailUrl: fields[11] as String?,
      category: fields[12] as String?,
      level: fields[13] as String?,
      description: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.moduleId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.position)
      ..writeByte(5)
      ..write(obj.videoUrl)
      ..writeByte(6)
      ..write(obj.audioUrl)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.durationMinutes)
      ..writeByte(10)
      ..write(obj.quizzes)
      ..writeByte(11)
      ..write(obj.thumbnailUrl)
      ..writeByte(12)
      ..write(obj.category)
      ..writeByte(13)
      ..write(obj.level)
      ..writeByte(14)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
