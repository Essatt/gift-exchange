import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gift_service.dart';
import '../models/person.dart';
import '../models/gift.dart';

// Gift Service Provider
final giftServiceProvider = Provider<GiftService>((ref) {
  return GiftService();
});

// People List Provider
final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final service = ref.watch(giftServiceProvider);
  return service.getAllPeople();
});

// Single Person Provider
final personProvider = Provider.family<Person?, String>((ref, id) {
  final service = ref.watch(giftServiceProvider);
  return service.getPerson(id);
});

// Gifts List Provider
final giftsProvider = FutureProvider<List<Gift>>((ref) async {
  final service = ref.watch(giftServiceProvider);
  return service.getAllGifts();
});

// Gifts by Person Provider
final giftsByPersonProvider = Provider.family<List<Gift>, String>((ref, personId) {
  final service = ref.watch(giftServiceProvider);
  return service.getGiftsByPersonId(personId);
});

// Person Stats Provider
final personStatsProvider = Provider.family<PersonStats, String>((ref, personId) {
  final service = ref.watch(giftServiceProvider);
  return PersonStats(
    totalGiven: service.getTotalGivenForPerson(personId),
    totalReceived: service.getTotalReceivedForPerson(personId),
    netBalance: service.getNetBalanceForPerson(personId),
    lastGiftFrom: service.getLastGiftFromPerson(personId),
    lastGiftTo: service.getLastGiftToPerson(personId),
  );
});

// Monthly Expenditure Provider
final monthlyExpenditureProvider = Provider.family<double, DateTime>((ref, date) {
  final service = ref.watch(giftServiceProvider);
  return service.getTotalGivenInMonth(date.month, date.year);
});

// Yearly Expenditure Provider
final yearlyExpenditureProvider = Provider.family<double, int>((ref, year) {
  final service = ref.watch(giftServiceProvider);
  return service.getTotalGivenInYear(year);
});

// Overall Expenditure Provider
final overallExpenditureProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(giftServiceProvider);
  return service.getTotalGivenOverall();
});

// Person Stats Model
class PersonStats {
  final double totalGiven;
  final double totalReceived;
  final double netBalance;
  final Gift? lastGiftFrom;
  final Gift? lastGiftTo;

  PersonStats({
    required this.totalGiven,
    required this.totalReceived,
    required this.netBalance,
    this.lastGiftFrom,
    this.lastGiftTo,
  });
}
