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

  @HiveField(5, defaultValue: '')
  final String customRelationship;

  Person({
    required this.id,
    required this.name,
    required this.relationship,
    required this.createdAt,
    required this.updatedAt,
    this.customRelationship = '',
  });

  String get relationshipLabel {
    if (relationship == RelationshipType.other &&
        customRelationship.isNotEmpty) {
      return customRelationship;
    }
    return switch (relationship) {
      RelationshipType.family => 'Family',
      RelationshipType.friend => 'Friend',
      RelationshipType.colleague => 'Colleague',
      RelationshipType.romanticPartner => 'Romantic Partner',
      RelationshipType.other => 'Other',
    };
  }

  Person copyWith({
    String? id,
    String? name,
    RelationshipType? relationship,
    String? customRelationship,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      customRelationship: customRelationship ?? this.customRelationship,
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
