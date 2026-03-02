// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerLogModelAdapter extends TypeAdapter<PrayerLogModel> {
  @override
  final int typeId = 0;

  @override
  PrayerLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerLogModel(
      dateKey: fields[0] as String,
      completed: (fields[1] as List).cast<bool>(),
      durations: (fields[2] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, PrayerLogModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.completed)
      ..writeByte(2)
      ..write(obj.durations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
