// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GiftTypeAdapter extends TypeAdapter<GiftType> {
  @override
  final int typeId = 2;

  @override
  GiftType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GiftType.given;
      case 1:
        return GiftType.received;
      default:
        return GiftType.given;
    }
  }

  @override
  void write(BinaryWriter writer, GiftType obj) {
    switch (obj) {
      case GiftType.given:
        writer.writeByte(0);
        break;
      case GiftType.received:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GiftTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
