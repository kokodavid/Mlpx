// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookmarkModelAdapter extends TypeAdapter<BookmarkModel> {
  @override
  final int typeId = 13;

  @override
  BookmarkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookmarkModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      lessonId: fields[2] as String,
      courseId: fields[3] as String,
      moduleId: fields[4] as String,
      lessonTitle: fields[5] as String,
      courseTitle: fields[6] as String,
      moduleTitle: fields[7] as String,
      bookmarkedAt: fields[8] as DateTime,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      needsSync: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BookmarkModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.lessonId)
      ..writeByte(3)
      ..write(obj.courseId)
      ..writeByte(4)
      ..write(obj.moduleId)
      ..writeByte(5)
      ..write(obj.lessonTitle)
      ..writeByte(6)
      ..write(obj.courseTitle)
      ..writeByte(7)
      ..write(obj.moduleTitle)
      ..writeByte(8)
      ..write(obj.bookmarkedAt)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.needsSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
