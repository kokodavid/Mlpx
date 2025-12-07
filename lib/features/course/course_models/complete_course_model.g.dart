// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complete_course_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompleteCourseModelAdapter extends TypeAdapter<CompleteCourseModel> {
  @override
  final int typeId = 1;

  @override
  CompleteCourseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompleteCourseModel(
      course: fields[0] as CourseModel,
      modules: (fields[1] as List).cast<ModuleWithLessons>(),
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompleteCourseModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.course)
      ..writeByte(1)
      ..write(obj.modules)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompleteCourseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ModuleWithLessonsAdapter extends TypeAdapter<ModuleWithLessons> {
  @override
  final int typeId = 2;

  @override
  ModuleWithLessons read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModuleWithLessons(
      module: fields[0] as ModuleModel,
      lessons: (fields[1] as List).cast<LessonModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ModuleWithLessons obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.module)
      ..writeByte(1)
      ..write(obj.lessons);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleWithLessonsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
