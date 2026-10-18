import 'package:flutter_test/flutter_test.dart';
import 'package:uangku/models/budget_model.dart';
import 'package:uangku/models/expense_item.dart';
import 'package:uangku/utils/currency_formatter.dart';
import 'package:uangku/utils/date_helper.dart';

void main() {
  group('Konsep & Logika Keuangan Test', () {
    test('Formula Sisa Tabungan = Total Gaji - (Primer + Sekunder + Tersier)', () {
      const budget = BudgetModel(
        totalSalary: 10000000,
        primaryAllocation: 5000000,
        secondaryAllocation: 3000000,
        tertiaryAllocation: 500000,
      );

      // 10.000.000 - (5.000.000 + 3.000.000 + 500.000) = 1.500.000
      expect(budget.savingsAllocation, 1500000.0);
      expect(budget.primaryPercent, 50.0);
      expect(budget.secondaryPercent, 30.0);
      expect(budget.tertiaryPercent, 5.0);
      expect(budget.savingsPercent, 15.0);
    });

    test('Formula Sisa Hari Bulan Ini: [Total Hari Bulan Ini - Hari Ini + 1]', () {
      // Misalkan tanggal 3 Oktober 2026 (Oktober memiliki 31 hari)
      final testDate = DateTime(2026, 10, 3);
      final remainingDays = DateHelper.getRemainingDaysInMonth(testDate);
      // 31 - 3 + 1 = 29 hari
      expect(remainingDays, 29);

      // Misalkan hari terakhir bulan: 31 Oktober
      final lastDay = DateTime(2026, 10, 31);
      final remainingLastDay = DateHelper.getRemainingDaysInMonth(lastDay);
      // 31 - 31 + 1 = 1 hari
      expect(remainingLastDay, 1);
    });

    test('Formula Smart Daily Allowance: [Sisa Saldo Sekunder ÷ Sisa Hari Bulan Ini]', () {
      const secondaryTotal = 2900000.0;
      const remainingDays = 29;
      final dailyAllowance = (secondaryTotal / remainingDays).floorToDouble();

      // 2.900.000 / 29 = 100.000 / hari
      expect(dailyAllowance, 100000.0);

      // Quick Expense mengurangi saldo sekunder dan jatah harian berikutnya otomatis update
      final expense = ExpenseItem(
        id: '1',
        title: 'Makan Siang & Kopi',
        amount: 58000.0,
        category: 'Makan & Minum',
        timestamp: DateTime(2026, 10, 3, 12, 0),
      );

      final updatedSecondary = secondaryTotal - expense.amount; // 2.842.000
      final updatedDailyAllowance = (updatedSecondary / remainingDays).floorToDouble();
      // 2.842.000 / 29 = 98.000 / hari
      expect(updatedDailyAllowance, 98000.0);
    });

    test('Currency Formatter Format dan Parse Rupiah', () {
      expect(CurrencyFormatter.format(25000), 'Rp 25.000');
      expect(CurrencyFormatter.parse('Rp 25.000'), 25000.0);
      expect(CurrencyFormatter.parse('1.500.000'), 1500000.0);
      expect(CurrencyFormatter.formatCompact(2500000), 'Rp 2.5 Jt');
      expect(CurrencyFormatter.formatCompact(50000), 'Rp 50 Rb');
    });

    test('BudgetDetailItem dan Kalkulasi Otomatis Rincian Pos', () {
      const items = [
        BudgetDetailItem(id: '1', title: 'Sewa Kos', amount: 800000),
        BudgetDetailItem(id: '2', title: 'Listrik & Air', amount: 250000),
        BudgetDetailItem(id: '3', title: 'WiFi', amount: 200000),
        BudgetDetailItem(id: '4', title: 'Tagihan Lain', amount: 182000),
      ];

      final total = BudgetModel.sumDetails(items);
      expect(total, 1432000.0);

      final budget = BudgetModel(
        totalSalary: 3000000,
        primaryAllocation: total,
        secondaryAllocation: 500000,
        tertiaryAllocation: 400000,
        primaryDetails: items,
      );

      expect(budget.primaryAllocation, 1432000.0);
      expect(budget.savingsAllocation, 668000.0);
      expect(budget.primaryDetails.length, 4);

      // JSON serialization & deserialization check
      final json = budget.toJson();
      final fromJsonBudget = BudgetModel.fromJson(json);
      expect(fromJsonBudget.primaryAllocation, 1432000.0);
      expect(fromJsonBudget.primaryDetails.length, 4);
      expect(fromJsonBudget.primaryDetails[0].title, 'Sewa Kos');
    });
    test('FITUR 1: Smart Daily Allowance Rollover & Over-budget Logic', () {
      const secondaryTotal = 2000000.0;
      final testDateDay1 = DateTime(2026, 10, 1);
      final testDateDay2 = DateTime(2026, 10, 2);

      final remainingDaysDay1 = DateHelper.getRemainingDaysInMonth(testDateDay1); // 31 - 1 + 1 = 31 hari
      final remainingDaysDay2 = DateHelper.getRemainingDaysInMonth(testDateDay2); // 31 - 2 + 1 = 30 hari

      // Day 1 base daily allowance = 2.000.000 / 31 = 64.516,12
      final baseDailyAllowanceDay1 = secondaryTotal / remainingDaysDay1;
      expect(baseDailyAllowanceDay1.toStringAsFixed(2), '64516.13');

      // Kasus A: Hemat (Jajan < Jatah) pada Day 1 (Jajan 40.000)
      final expenseUnder = 40000.0;
      final remainingDay1Under = baseDailyAllowanceDay1 - expenseUnder;
      expect(remainingDay1Under > 0, true);

      // Rollover pada Day 2: Sisa saldo sekunder = 2.000.000 - 40.000 = 1.960.000
      final secondaryRemainingDay2Under = secondaryTotal - expenseUnder;
      final baseDailyAllowanceDay2Under = secondaryRemainingDay2Under / remainingDaysDay2;
      // 1.960.000 / 30 = 65.333,33 (NAIK dari 64.516,13!)
      expect(baseDailyAllowanceDay2Under > baseDailyAllowanceDay1, true);

      // Kasus B: Over-budget (Jajan > Jatah) pada Day 1 (Jajan 100.000)
      final expenseOver = 100000.0;
      final remainingDay1Over = baseDailyAllowanceDay1 - expenseOver;
      expect(remainingDay1Over < 0, true); // Minus/Over budget!

      // Rollover pada Day 2: Sisa saldo sekunder = 2.000.000 - 100.000 = 1.900.000
      final secondaryRemainingDay2Over = secondaryTotal - expenseOver;
      final baseDailyAllowanceDay2Over = secondaryRemainingDay2Over / remainingDaysDay2;
      // 1.900.000 / 30 = 63.333,33 (TURUN dari 64.516,13!)
      expect(baseDailyAllowanceDay2Over < baseDailyAllowanceDay1, true);
    });

    test('FITUR 2: Dual Filter Logic (Range Waktu & Filter Kategori)', () {
      final expenses = [
        ExpenseItem(
          id: '1',
          title: 'Nasi Goreng',
          amount: 25000,
          category: 'Makan & Minum',
          timestamp: DateTime.now(),
        ),
        ExpenseItem(
          id: '2',
          title: 'Kopi Susu',
          amount: 18000,
          category: 'Kopi & Nongkrong',
          timestamp: DateTime.now(),
        ),
        ExpenseItem(
          id: '3',
          title: 'Tiket Bioskop',
          amount: 50000,
          category: 'Hiburan',
          timestamp: DateTime.now().subtract(const Duration(days: 40)), // Bulan lalu
        ),
      ];

      // Skenario 1: Filter Bulan Ini + Semua Kategori
      final monthAllCategory = expenses.where((e) =>
        DateHelper.isThisMonth(e.timestamp) && (true)
      ).toList();
      expect(monthAllCategory.length, 2); // Nasi Goreng & Kopi Susu

      // Skenario 2: Filter Bulan Ini + Kategori 'Makan & Minum'
      final monthMakanMinum = expenses.where((e) =>
        DateHelper.isThisMonth(e.timestamp) && (e.category == 'Makan & Minum')
      ).toList();
      expect(monthMakanMinum.length, 1);
      expect(monthMakanMinum.first.title, 'Nasi Goreng');

      // Skenario 3: Filter Bulan Ini + Kategori 'Hiburan'
      final monthHiburan = expenses.where((e) =>
        DateHelper.isThisMonth(e.timestamp) && (e.category == 'Hiburan')
      ).toList();
      expect(monthHiburan.length, 0); // Tidak ada transaksi Hiburan bulan ini
    });
  });
}


