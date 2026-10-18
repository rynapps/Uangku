import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class PrimaryAllowanceCard extends StatelessWidget {
  final double baseDailyAllowance;
  final double todayRemainingAllowance;
  final double todaySpent;
  final double secondaryRemaining;
  final double secondaryTotal;
  final int remainingDays;

  const PrimaryAllowanceCard({
    super.key,
    required this.baseDailyAllowance,
    required this.todayRemainingAllowance,
    required this.todaySpent,
    required this.secondaryRemaining,
    required this.secondaryTotal,
    required this.remainingDays,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOverBudgetToday = todayRemainingAllowance < 0;
    final bool isDeficitTotal = secondaryRemaining <= 0;

    // Persentase terpakai bulan ini dari total alokasi sekunder
    final double monthlySpent = secondaryTotal - secondaryRemaining;
    final double monthlyProgress = secondaryTotal > 0
        ? (monthlySpent / secondaryTotal).clamp(0.0, 1.0)
        : 0.0;
    final int percentSpentMonthly = secondaryTotal > 0
        ? ((secondaryTotal - secondaryRemaining) / secondaryTotal * 100)
            .round()
            .clamp(0, 100)
        : 0;

    final displayAmount = isDeficitTotal
        ? 'Rp 0'
        : (isOverBudgetToday
            ? '-${CurrencyFormatter.format(todayRemainingAllowance.abs())}'
            : CurrencyFormatter.format(todayRemainingAllowance));

    final subtitleText = isOverBudgetToday
        ? '⚠️ Over-budget! Terpakai ${CurrencyFormatter.format(todaySpent)} dari ${CurrencyFormatter.format(baseDailyAllowance)}'
        : (todaySpent > 0
            ? 'Terpakai ${CurrencyFormatter.format(todaySpent)} dari ${CurrencyFormatter.format(baseDailyAllowance)}'
            : 'Jatah untuk hari ini ${CurrencyFormatter.format(baseDailyAllowance)}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate premium card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Dot + Label 'JATAH HARIAN'
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOverBudgetToday
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'JATAH HARIAN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Row: Angka Besar (kiri) + Circular Ring (kanan)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kolom Kiri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Angka Utama
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayAmount,
                        style: TextStyle(
                          color: isDeficitTotal || isOverBudgetToday
                              ? const Color(0xFFF87171)
                              : Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Text(
                      subtitleText,
                      style: TextStyle(
                        color: isOverBudgetToday
                            ? const Color(0xFFFCA5A5)
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Kolom Kanan: Circular Progress Ring (cyan)
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: monthlyProgress,
                        strokeWidth: 5.5,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        color: isDeficitTotal
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF06B6D4),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$percentSpentMonthly%',
                      style: TextStyle(
                        color: isDeficitTotal
                            ? const Color(0xFFF87171)
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),

          const SizedBox(height: 12),

          // Footer: Sisa Anggaran Bulan Ini + Chip Hari Tersisa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    maxLines: 1,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11.5),
                      children: [
                        TextSpan(
                          text: 'Sisa anggaran bulan ini  ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        TextSpan(
                          text: CurrencyFormatter.format(secondaryRemaining),
                          style: TextStyle(
                            color: isDeficitTotal
                                ? const Color(0xFFF87171)
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' / ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        TextSpan(
                          text: CurrencyFormatter.format(secondaryTotal),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Chip Sisa Hari
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$remainingDays hari tersisa',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}