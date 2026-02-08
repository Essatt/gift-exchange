import 'package:hive/hive.dart';

part 'relationship_type.g.dart';

@HiveType(typeId: 1)
enum RelationshipType {
  @HiveField(0)
  family,
  @HiveField(1)
  friend,
  @HiveField(2)
  colleague,
  @HiveField(3)
  other,
}
