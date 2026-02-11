import 'package:hive/hive.dart';
import 'relationship_type.dart';

part 'person.g.dart';

@HiveType(typeId: 3)
class Person extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final RelationshipType relationship;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  Person({
    required this.id,
    required this.name,
    required this.relationship,
    required this.createdAt,
    required this.updatedAt,
  });

  Person copyWith({
    String? id,
    String? name,
    RelationshipType? relationship,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Person(id: $id, name: $name, relationship: $relationship)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
