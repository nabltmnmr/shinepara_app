import 'package:intl/intl.dart';

class IqdCurrency {
  static const String symbol = 'د.ع';
  static const String locale = 'ar';

  /// Multiplier to convert stored prices into IQD.
  /// Keep `1.0` if your backend already returns IQD.
  static const double toIqdMultiplier = 1.0;

  static final NumberFormat _formatter = NumberFormat('#,##0', locale);

  static String format(
    num amount, {
    bool withSymbol = true,
  }) {
    final value = (amount * toIqdMultiplier).round();
    final text = _formatter.format(value);
    return withSymbol ? '$text $symbol' : text;
  }
}

