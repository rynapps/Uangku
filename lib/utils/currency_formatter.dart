import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka integer/double menjadi 'Rp 25.000'
  static String format(num amount) {
    return _formatter.format(amount);
  }

  /// Format angka tanpa prefix 'Rp' -> '25.000'
  static String formatWithoutSymbol(num amount) {
    final formatted = _formatter.format(amount);
    return formatted.replaceAll('Rp', '').trim();
  }

  /// Format ringkas untuk badge/chart: 'Rp 2 Jt' atau 'Rp 500 Rb'
  static String formatCompact(num amount) {
    if (amount >= 1000000000) {
      final m = amount / 1000000000;
      return 'Rp ${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)} M';
    } else if (amount >= 1000000) {
      final jt = amount / 1000000;
      return 'Rp ${jt.toStringAsFixed(jt.truncateToDouble() == jt ? 0 : 1)} Jt';
    } else if (amount >= 1000) {
      final rb = amount / 1000;
      return 'Rp ${rb.toStringAsFixed(rb.truncateToDouble() == rb ? 0 : 1)} Rb';
    }
    return format(amount);
  }

  /// Mengonversi string input ("25.000", "Rp 25.000", "25000") menjadi double
  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
