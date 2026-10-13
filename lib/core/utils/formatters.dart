import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double amount) => _formatter.format(amount);

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount);
  }
}

class DateFormatter {
  static final _full = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _short = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dayMonth = DateFormat('dd MMM', 'id_ID');
  static final _weekday = DateFormat('EEEE', 'id_ID');

  static String full(DateTime date) => _full.format(date);
  static String short(DateTime date) => _short.format(date);
  static String dayMonth(DateTime date) => _dayMonth.format(date);
  static String weekday(DateTime date) => _weekday.format(date);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff hari lalu';
    return short(date);
  }

  /// Minggu ke-N bulan apa
  static String weekLabel(DateTime date) {
    final start = _startOfWeek(date);
    final end = start.add(const Duration(days: 6));
    return '${dayMonth(start)} – ${dayMonth(end)}';
  }

  static DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime startOfWeek(DateTime date) => _startOfWeek(date);
  static DateTime endOfWeek(DateTime date) =>
      _startOfWeek(date).add(const Duration(days: 6));
}
