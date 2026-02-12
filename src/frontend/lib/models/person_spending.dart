class PersonSpending {
  final String personId;
  final String name;
  final double totalGiven;
  final double totalReceived;

  double get netBalance => totalReceived - totalGiven;

  const PersonSpending({
    required this.personId,
    required this.name,
    required this.totalGiven,
    required this.totalReceived,
  }) : assert(totalGiven >= 0, 'totalGiven must be non-negative'),
       assert(totalReceived >= 0, 'totalReceived must be non-negative');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonSpending &&
          personId == other.personId &&
          name == other.name &&
          totalGiven == other.totalGiven &&
          totalReceived == other.totalReceived;

  @override
  int get hashCode => Object.hash(personId, name, totalGiven, totalReceived);
}
