import 'package:hive/hive.dart';

part 'gift_type.g.dart';

@HiveType(typeId: 2)
enum GiftType {
  @HiveField(0)
  given,
  @HiveField(1)
  received,
}
