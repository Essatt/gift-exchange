import 'package:intl/intl.dart';

final NumberFormat _currencyFormat =
    NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2);

/// Formats a monetary amount with grouping and correct sign placement
/// (e.g. -$1,234.50). Non-finite values render as $0.00.
String formatCurrency(num value) {
  if (value is double && !value.isFinite) return _currencyFormat.format(0);
  return _currencyFormat.format(value);
}
