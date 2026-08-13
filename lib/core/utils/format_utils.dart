import 'package:intl/intl.dart';

class FormatUtils {
  static String currency(double value) {
    final formatter = NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0);
    return formatter.format(value);
  }

  static String date(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }
}
