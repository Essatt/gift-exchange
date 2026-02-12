enum TimeframeType { allTime, year, month }

class TimeFilter {
  final TimeframeType type;
  final int? year;
  final int? month;

  const TimeFilter._({required this.type, this.year, this.month});

  static const allTime = TimeFilter._(type: TimeframeType.allTime);

  factory TimeFilter.forYear(int year) {
    return TimeFilter._(type: TimeframeType.year, year: year);
  }

  factory TimeFilter.forMonth({required int year, required int month}) {
    assert(month >= 1 && month <= 12, 'month must be 1-12');
    return TimeFilter._(type: TimeframeType.month, year: year, month: month);
  }

  bool matches(DateTime date) {
    switch (type) {
      case TimeframeType.allTime:
        return true;
      case TimeframeType.year:
        return date.year == year;
      case TimeframeType.month:
        return date.year == year && date.month == month;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeFilter &&
          type == other.type &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(type, year, month);

  @override
  String toString() => 'TimeFilter($type, year: $year, month: $month)';
}
