import 'package:intl/intl.dart';

class DateHelper {
  /// Mendapatkan total hari dalam bulan tertentu
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Sisa hari dalam bulan berjalan: [Total Hari Bulan Ini - Hari Ini + 1]
  static int getRemainingDaysInMonth([DateTime? date]) {
    final current = date ?? DateTime.now();
    final totalDays = getDaysInMonth(current);
    final remaining = totalDays - current.day + 1;
    return remaining > 0 ? remaining : 1;
  }

  /// Nama bulan bahasa Indonesia
  static String getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  /// Format 'Oktober 2026'
  static String getMonthYearString([DateTime? date]) {
    final current = date ?? DateTime.now();
    return '${getMonthName(current.month)} ${current.year}';
  }

  /// Nama hari bahasa Indonesia
  static String getDayOfWeekName(int weekday) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return '';
  }

  /// Format 'Kamis, 15 Oktober 2026'
  static String getFullDateString([DateTime? date]) {
    final current = date ?? DateTime.now();
    return '${getDayOfWeekName(current.weekday)}, ${current.day} ${getMonthName(current.month)} ${current.year}';
  }

  /// Format relatif tanggal transaksi (Hari ini, Kemarin, atau tgl bln)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final isSameYear = now.year == date.year;
    final isToday = isSameYear && now.month == date.month && now.day == date.day;
    final isYesterday = isSameYear && now.month == date.month && (now.day - 1) == date.day;

    final hourStr = date.hour.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final timeStr = '$hourStr:$minuteStr';

    if (isToday) return 'Hari ini, $timeStr';
    if (isYesterday) return 'Kemarin, $timeStr';
    return '${date.day} ${getMonthName(date.month).substring(0, 3)}, $timeStr';
  }

  /// Format jam saja untuk UI Transaction History (contoh: 08:30 AM / 03:15 PM)
  static String formatTimeOnly(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Check whether date is today
  static bool isToday(DateTime date, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check whether date is in the current week (Monday to Sunday)
  static bool isThisWeek(DateTime date, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return date.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) && date.isBefore(endOfWeek);
  }

  /// Check whether date is in the current month
  static bool isThisMonth(DateTime date, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
}