import '../models/budget_model.dart';
import '../models/expense_item.dart';
import 'database_helper.dart';

class StorageService {
  /// Simpan pengaturan budget bulanan ke SQLite
  static Future<void> saveBudget(BudgetModel budget) async {
    await DatabaseHelper.saveBudget(budget);
  }

  /// Ambil pengaturan budget bulanan dari SQLite
  static Future<BudgetModel> loadBudget() async {
    return await DatabaseHelper.getBudget();
  }

  /// Simpan seluruh riwayat transaksi (helper opsional)
  static Future<void> saveExpenses(List<ExpenseItem> items) async {
    for (final item in items) {
      await DatabaseHelper.insertExpense(item);
    }
  }

  /// Tambah satu transaksi pengeluaran ke SQLite
  static Future<void> addExpense(ExpenseItem item) async {
    await DatabaseHelper.insertExpense(item);
  }

  /// Hapus satu transaksi pengeluaran dari SQLite berdasarkan ID
  static Future<void> deleteExpense(String id) async {
    await DatabaseHelper.deleteExpense(id);
  }

  /// Ambil riwayat transaksi pengeluaran dari SQLite
  static Future<List<ExpenseItem>> loadExpenses() async {
    return await DatabaseHelper.getAllExpenses();
  }
}

