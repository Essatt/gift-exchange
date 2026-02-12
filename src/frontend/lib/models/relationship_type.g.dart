// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relationship_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RelationshipTypeAdapter extends TypeAdapter<RelationshipType> {
  @override
  final int typeId = 1;

  @override
  RelationshipType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RelationshipType.family;
      case 1:
        return RelationshipType.friend;
      case 2:
        return RelationshipType.colleague;
      case 3:
        return RelationshipType.other;
      case 4:
        return RelationshipType.romanticPartner;
      default:
        return RelationshipType.family;
    }
  }

  @override
  void write(BinaryWriter writer, RelationshipType obj) {
    switch (obj) {
      case RelationshipType.family:
        writer.writeByte(0);
        break;
      case RelationshipType.friend:
        writer.writeByte(1);
        break;
      case RelationshipType.colleague:
        writer.writeByte(2);
        break;
      case RelationshipType.other:
        writer.writeByte(3);
        break;
      case RelationshipType.romanticPartner:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationshipTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
