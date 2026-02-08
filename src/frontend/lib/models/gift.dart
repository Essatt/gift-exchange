import 'package:hive/hive.dart';

part 'gift.g.dart';
import 'gift_type.dart';

@HiveType(typeId: 4)
class Gift extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String personId;

  @HiveField(2)
  final GiftType type;

  @HiveField(3)
  final double value;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String eventType;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final DateTime createdAt;

  Gift({
    required this.id,
    required this.personId,
    required this.type,
    required this.value,
    required this.date,
    required this.eventType,
    required this.description,
    required this.createdAt,
  });

  Gift copyWith({
    String? id,
    String? personId,
    GiftType? type,
    double? value,
    DateTime? date,
    String? eventType,
    String? description,
    DateTime? createdAt,
  }) {
    return Gift(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      type: type ?? this.type,
      value: value ?? this.value,
      date: date ?? this.date,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Gift(id: $id, personId: $personId, type: $type, value: $value, eventType: $eventType)';
  }
}
