// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_quiz_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonQuizModelAdapter extends TypeAdapter<LessonQuizModel> {
  @override
  final int typeId = 6;

  @override
  LessonQuizModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonQuizModel(
      id: fields[0] as String,
      lessonId: fields[1] as String,
      stage: fields[2] as String,
      questionType: fields[3] as String,
      questionContent: fields[4] as String,
      soundFileUrl: fields[5] as String?,
      correctAnswer: fields[6] as String,
      options: (fields[7] as List).cast<String>(),
      difficultyLevel: fields[8] as int,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LessonQuizModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lessonId)
      ..writeByte(2)
      ..write(obj.stage)
      ..writeByte(3)
      ..write(obj.questionType)
      ..writeByte(4)
      ..write(obj.questionContent)
      ..writeByte(5)
      ..write(obj.soundFileUrl)
      ..writeByte(6)
      ..write(obj.correctAnswer)
      ..writeByte(7)
      ..write(obj.options)
      ..writeByte(8)
      ..write(obj.difficultyLevel)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonQuizModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
