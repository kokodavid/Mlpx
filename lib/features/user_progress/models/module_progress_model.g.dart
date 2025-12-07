// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModuleProgressModelAdapter extends TypeAdapter<ModuleProgressModel> {
  @override
  final int typeId = 12;

  @override
  ModuleProgressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModuleProgressModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      moduleId: fields[2] as String,
      courseProgressId: fields[3] as String,
      status: fields[4] as String,
      startedAt: fields[5] as DateTime?,
      completedAt: fields[6] as DateTime?,
      averageScore: fields[7] as double?,
      totalLessons: fields[8] as int,
      completedLessons: fields[9] as int,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      needsSync: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ModuleProgressModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.moduleId)
      ..writeByte(3)
      ..write(obj.courseProgressId)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.startedAt)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.averageScore)
      ..writeByte(8)
      ..write(obj.totalLessons)
      ..writeByte(9)
      ..write(obj.completedLessons)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleProgressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
