// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'on_boarding_quiz_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OnboardingQuizModelAdapter extends TypeAdapter<OnboardingQuizModel> {
  @override
  final int typeId = 7;

  @override
  OnboardingQuizModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OnboardingQuizModel(
      id: fields[0] as String,
      stage: fields[1] as String,
      questionType: fields[2] as String,
      questionContent: fields[3] as String,
      soundFileUrl: fields[4] as String?,
      correctAnswer: fields[5] as String,
      options: (fields[6] as List).cast<String>(),
      difficultyLevel: fields[7] as int?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OnboardingQuizModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.stage)
      ..writeByte(2)
      ..write(obj.questionType)
      ..writeByte(3)
      ..write(obj.questionContent)
      ..writeByte(4)
      ..write(obj.soundFileUrl)
      ..writeByte(5)
      ..write(obj.correctAnswer)
      ..writeByte(6)
      ..write(obj.options)
      ..writeByte(7)
      ..write(obj.difficultyLevel)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingQuizModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
