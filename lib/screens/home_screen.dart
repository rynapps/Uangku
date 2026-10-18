import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/expense_item.dart';
import '../services/storage_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_helper.dart';
import '../widgets/primary_allowance_card.dart';
import '../widgets/bento_grid.dart';
import '../widgets/transaction_history_section.dart';
import '../widgets/expense_bottom_sheet.dart';
import '../widgets/budget_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  BudgetModel _budget = BudgetModel.initial();
  List<ExpenseItem> _expenses = [];

  int _remainingDays = 30;
  double _secondaryRemaining = 0.0;
  double _baseDailyAllowance = 0.0;
  double _todayRemainingAllowance = 0.0;
  double _todaySpent = 0.0;

  @override
  void initState() {
    super.initState();
    _recalculateMetrics();
    _loadData();
  }

  /// Kalkulasi Ulang Smart Daily Allowance Pos Sekunder
  void _recalculateMetrics() {
    final now = DateTime.now();
    _remainingDays = DateHelper.getRemainingDaysInMonth(now);

    // 1. Total pengeluaran sekunder bulan ini SEBELUM hari ini
    final secondarySpentBeforeToday = _expenses
        .where((e) =>
            e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day < now.day)
        .fold(0.0, (sum, item) => sum + item.amount);

    // 2. Total pengeluaran sekunder HARI INI
    _todaySpent = _expenses
        .where((e) =>
            e.timestamp.year == now.year &&
            e.timestamp.month == now.month &&
            e.timestamp.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);

    // 3. Sisa saldo sekunder pada awal hari ini (sebelum pengeluaran hari ini)
    final secondaryRemainingStartOfDay =
        _budget.secondaryAllocation - secondarySpentBeforeToday;

    // 4. Formula Smart Daily Allowance Baru Saat Berganti Hari:
    // Jatah Harian Baru = Total Sisa Saldo Pos Sekunder (sebelum hari ini) / Sisa Hari dalam Bulan Berjalan
    _baseDailyAllowance = _remainingDays > 0
        ? (secondaryRemainingStartOfDay / _remainingDays)
        : 0.0;

    // 5. Real-time Sisa Jatah Hari Ini = Base Jatah Harian - Pengeluaran Hari Ini
    _todayRemainingAllowance = _baseDailyAllowance - _todaySpent;

    // 6. Total Sisa Saldo Pos Sekunder Real-time
    _secondaryRemaining = secondaryRemainingStartOfDay - _todaySpent;
  }

  Future<void> _loadData() async {
    final loadedBudget = await StorageService.loadBudget();
    final loadedExpenses = await StorageService.loadExpenses();
    if (mounted) {
      setState(() {
        _budget = loadedBudget;
        _expenses = loadedExpenses;
        _recalculateMetrics();
        _isLoading = false;
      });
    }
  }

  /// Tambah transaksi jajan baru (Disimpan ke SQLite)
  Future<void> _handleAddExpense(ExpenseItem item) async {
    setState(() {
      _expenses.insert(0, item);
      _recalculateMetrics();
    });
    await StorageService.addExpense(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jajan dicatat! Sisa jatah hari ini: ${CurrencyFormatter.format(_todayRemainingAllowance)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  /// Hapus transaksi jajan (Dihapus dari SQLite)
  Future<void> _handleDeleteExpense(ExpenseItem item) async {
    setState(() {
      _expenses.removeWhere((e) => e.id == item.id);
      _recalculateMetrics();
    });
    await StorageService.deleteExpense(item.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catatan "${item.title}" dihapus. Saldo jajan dikembalikan.'),
          backgroundColor: const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  /// Simpan pembaharuan budget alokasi (Disimpan ke SQLite)
  Future<void> _handleSaveBudget(BudgetModel newBudget) async {
    setState(() {
      _budget = newBudget;
      _recalculateMetrics();
    });
    await StorageService.saveBudget(newBudget);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Alokasi anggaran bulanan berhasil diperbarui!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  void _openExpenseModal() {
    ExpenseBottomSheet.show(
      context: context,
      currentDailyAllowance: _todayRemainingAllowance > 0
          ? _todayRemainingAllowance
          : _baseDailyAllowance,
      currentSecondaryRemaining: _secondaryRemaining,
      onAddExpense: _handleAddExpense,
    );
  }

  void _openBudgetModal() {
    BudgetBottomSheet.show(
      context: context,
      initialBudget: _budget,
      onSaveBudget: _handleSaveBudget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0F172A),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF0F172A),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Top Bar Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo & Subtitle
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Uangku',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 12,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateHelper.getFullDateString(),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Atur Budget
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openBudgetModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: Color(0xFF0F172A),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Atur Budget',
                                  style: TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // FITUR 1: Highlight Card: Smart Daily Allowance Pos Sekunder
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: RepaintBoundary(
                    child: PrimaryAllowanceCard(
                      baseDailyAllowance: _baseDailyAllowance,
                      todayRemainingAllowance: _todayRemainingAllowance,
                      todaySpent: _todaySpent,
                      secondaryRemaining: _secondaryRemaining,
                      secondaryTotal: _budget.secondaryAllocation,
                      remainingDays: _remainingDays,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Bento Grid (2x2 Cards: Primer, Sekunder, Tersier, Tabungan)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RepaintBoundary(
                    child: BentoGrid(
                      budget: _budget,
                      secondaryRemaining: _secondaryRemaining,
                      onEditBudget: _openBudgetModal,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // FITUR 2: Redesign Transaction History (Dynamic Category Grouping & Time Filter)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TransactionHistorySection(
                    expenses: _expenses,
                    onDeleteExpense: _handleDeleteExpense,
                  ),
                ),
              ),

              // Bottom padding for FAB clearance
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button (FAB): "Catat Jajan"
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _openExpenseModal,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 28),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 22, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Catat Jajan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
