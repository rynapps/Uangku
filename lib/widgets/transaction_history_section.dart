import 'package:flutter/material.dart';
import '../models/expense_item.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_helper.dart';

class TransactionHistorySection extends StatefulWidget {
  final List<ExpenseItem> expenses;
  final Function(ExpenseItem) onDeleteExpense;

  const TransactionHistorySection({
    super.key,
    required this.expenses,
    required this.onDeleteExpense,
  });

  @override
  State<TransactionHistorySection> createState() => _TransactionHistorySectionState();
}

class _TransactionHistorySectionState extends State<TransactionHistorySection> {
  // FILTER 1: Range Waktu
  String _selectedTimeFilter = 'Hari Ini';
  final List<String> _timeFilters = ['Hari Ini', 'Minggu ini', 'Bulan ini'];

  // FILTER 2: Group Kategori (Dinamis)
  String _selectedCategoryFilter = 'Semua kategori';

  /// Mendapatkan daftar kategori dinamis yang HANYA berisi kategori yang sudah pernah diinput oleh user
  List<String> _getAvailableCategories() {
    final categoriesInExpenses = widget.expenses
        .map((e) => e.category)
        .toSet()
        .toList();

    const standardOrder = [
      'Makan & Minum',
      'Kopi & Nongkrong',
      'Hiburan',
      'Belanja',
      'Transportasi',
      'Lain-lain',
    ];

    categoriesInExpenses.sort((a, b) {
      final indexA = standardOrder.indexOf(a);
      final indexB = standardOrder.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return a.compareTo(b);
    });

    return ['Semua kategori', ...categoriesInExpenses];
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Makan & Minum':
        return Icons.restaurant_rounded;
      case 'Kopi & Nongkrong':
        return Icons.local_cafe_rounded;
      case 'Hiburan':
        return Icons.movie_outlined;
      case 'Belanja':
        return Icons.shopping_bag_outlined;
      case 'Transportasi':
        return Icons.two_wheeler_rounded;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Makan & Minum':
        return const Color(0xFF059669); // Emerald green
      case 'Kopi & Nongkrong':
        return const Color(0xFFD97706); // Amber
      case 'Hiburan':
        return const Color(0xFF2563EB); // Royal Blue
      case 'Belanja':
        return const Color(0xFFDC2626); // Crimson Red
      case 'Transportasi':
        return const Color(0xFF4F46E5); // Indigo
      default:
        return const Color(0xFF475569); // Slate Gray
    }
  }

  /// Filter transaksi berdasarkan kombinasi 2 Filter: Waktu & Kategori
  List<ExpenseItem> _getFilteredExpenses([String? timeFilter, String? categoryFilter]) {
    final activeTimeFilter = timeFilter ?? _selectedTimeFilter;
    final activeCategoryFilter = categoryFilter ?? _selectedCategoryFilter;

    final now = DateTime.now();

    return widget.expenses.where((item) {
      bool matchTime = true;
      switch (activeTimeFilter) {
        case 'Hari Ini':
          matchTime = DateHelper.isToday(item.timestamp, now);
          break;
        case 'Minggu ini':
          matchTime = DateHelper.isThisWeek(item.timestamp, now);
          break;
        case 'Bulan ini':
          matchTime = DateHelper.isThisMonth(item.timestamp, now);
          break;
        default:
          matchTime = true;
          break;
      }

      bool matchCategory = true;
      if (activeCategoryFilter != 'Semua kategori' && activeCategoryFilter != 'Semua Kategori') {
        matchCategory = item.category == activeCategoryFilter;
      }

      return matchTime && matchCategory;
    }).toList();
  }

  String _getTimeFilterLabel([String? filter]) {
    final active = filter ?? _selectedTimeFilter;
    switch (active) {
      case 'Hari Ini': return 'Hari Ini';
      case 'Minggu ini': return 'Minggu Ini';
      case 'Bulan ini': return 'Bulan Ini';
      default: return 'Semua Periode';
    }
  }

  /// Group expenses by date label for display
  Map<String, List<ExpenseItem>> _groupByDate(List<ExpenseItem> expenses) {
    final now = DateTime.now();
    final Map<String, List<ExpenseItem>> groups = {};
    for (final item in expenses) {
      final isToday = DateHelper.isToday(item.timestamp, now);
      final isThisMonth = DateHelper.isThisMonth(item.timestamp, now);
      String key;
      if (isToday) {
        key = 'Hari ini · ${item.timestamp.day} ${DateHelper.getMonthName(item.timestamp.month)}';
      } else if (isThisMonth) {
        key = 'Sebelumnya · ${DateHelper.getMonthName(item.timestamp.month)}';
      } else {
        key = '${DateHelper.getMonthName(item.timestamp.month)} ${item.timestamp.year}';
      }
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(item);
    }
    return groups;
  }

  void _openViewAllModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final availableCategories = _getAvailableCategories();
            if (!availableCategories.contains(_selectedCategoryFilter)) {
              _selectedCategoryFilter = 'Semua kategori';
            }

            final modalFilteredExpenses = _getFilteredExpenses();
            final double modalTotalSpent = modalFilteredExpenses.fold(
              0.0,
              (sum, item) => sum + item.amount,
            );
            final grouped = _groupByDate(modalFilteredExpenses);

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header "Semua Transaksi"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Semua Transaksi',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Jejak kecil, keuangan lebih terarah.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Filter Tabs Row (Hari ini, Minggu ini, Bulan ini)
                  Row(
                    children: [
                      ..._timeFilters.map((filter) {
                        final isSelected = _selectedTimeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedTimeFilter = filter);
                              setModalState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Semua kategori filter button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF475569)),
                            const SizedBox(width: 6),
                            const Text(
                              'Semua kategori',
                              style: TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${DateHelper.getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Summary Card
                  _buildSummaryCard(modalTotalSpent, modalFilteredExpenses.length),

                  const SizedBox(height: 16),

                  // Grouped List
                  Expanded(
                    child: modalFilteredExpenses.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              ...grouped.entries.map((entry) => _buildDateGroup(ctx, entry.key, entry.value, grouped.values.fold(0.0, (s, l) => s + l.fold(0.0, (a, e) => a + e.amount)))),
                              const SizedBox(height: 12),
                              // Footer hint
                              const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF94A3B8)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Geser transaksi ke kiri untuk menghapus',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // All transactions shown footer
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Semua transaksi ${_getTimeFilterLabel().toLowerCase()} sudah ditampilkan',
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build a date group header + items for the modal list
  Widget _buildDateGroup(BuildContext context, String dateLabel, List<ExpenseItem> items, double ignored) {
    final groupTotal = items.fold(0.0, (s, e) => s + e.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date group header
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                CurrencyFormatter.format(groupTotal),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildTransactionItemTile(context, item),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _getFilteredExpenses();
    final double totalSpent = filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
    final previewItems = filteredExpenses.take(4).toList();
    final grouped = _groupByDate(previewItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Transaksi',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () => _openViewAllModal(context),
              child: Row(
                children: [
                  const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Color(0xFF0284C7),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.north_east_rounded,
                      size: 12,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Filter Tabs Row (Hari ini, Minggu ini, Bulan ini)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _timeFilters.map((filter) {
              final isSelected = _selectedTimeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTimeFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Summary Card
        _buildSummaryCard(totalSpent, filteredExpenses.length),

        const SizedBox(height: 14),

        // Transaction List (grouped or empty)
        if (filteredExpenses.isEmpty)
          _buildEmptyState()
        else ...[
          ...grouped.entries.map((entry) => _buildDateGroup(context, entry.key, entry.value, 0)),
          if (filteredExpenses.length > 4) ...[
            const SizedBox(height: 10),
            // Swipe hint
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF94A3B8)),
                  SizedBox(width: 4),
                  Text(
                    'Geser ke kiri untuk menghapus transaksi',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  /// Widget Pembantu: 2 Filter (Waktu & Kategori Dinamis)
  Widget _buildFilterSection({
    required List<String> availableCategories,
    required Function(String) onTimeChanged,
    required Function(String) onCategoryChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label & Chip Filter 1: Range Waktu
        const Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text(
              'RENTANG WAKTU:',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _timeFilters.map((filter) {
              final isSelected = _selectedTimeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onTimeChanged(filter);
                  },
                  selectedColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  showCheckmark: false,
                  elevation: isSelected ? 2 : 0,
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Label & Chip Filter 2: Group Kategori (Dinamis: Hanya kategori yang sudah di-input user)
        const Row(
          children: [
            Icon(Icons.category_rounded, size: 12, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text(
              'KATEGORI:',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: availableCategories.map((cat) {
              final isSelected = _selectedCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  avatar: cat == 'Semua Kategori'
                      ? Icon(
                          Icons.grid_view_rounded,
                          size: 14,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        )
                      : Icon(
                          _getCategoryIcon(cat),
                          size: 14,
                          color: isSelected ? Colors.white : _getCategoryColor(cat),
                        ),
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onCategoryChanged(cat);
                  },
                  selectedColor: const Color(0xFF0284C7),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  showCheckmark: false,
                  elevation: isSelected ? 2 : 0,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Widget Pembantu: Card Summary Total Pengeluaran
  Widget _buildSummaryCard(double totalSpent, int itemCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENGELUARAN ${_getTimeFilterLabel().toUpperCase()} INI',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(totalSpent),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$itemCount transaksi',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget Pembantu: Empty State jika tidak ada transaksi pada filter ini
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF94A3B8),
                size: 25,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tidak ada transaksi untuk filter ini',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Coba ganti filter waktu atau kategori di atas',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format jam item - '12.30'
  String _formatItemTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  /// Pos label sesuai kategori
  String _getPosLabel(String category) {
    switch (category) {
      case 'Makan & Minum':
      case 'Transportasi':
      case 'Lain-lain':
        return 'Primer';
      case 'Kopi & Nongkrong':
      case 'Belanja':
        return 'Sekunder';
      case 'Hiburan':
        return 'Tersier';
      default:
        return 'Sekunder';
    }
  }

  /// Warna pos label
  Color _getPosColor(String category) {
    switch (_getPosLabel(category)) {
      case 'Primer':
        return const Color(0xFF475569);
      case 'Sekunder':
        return const Color(0xFF0284C7);
      case 'Tersier':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  /// Widget Pembantu: Item Tile Transaksi tunggal (100% Bebas Pixel Overflow)
  Widget _buildTransactionItemTile(BuildContext context, ExpenseItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _confirmDelete(context, item);
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 0),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_rounded, color: Colors.white, size: 22),
              SizedBox(height: 4),
              Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Kategori
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: _getCategoryColor(item.category),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Judul Transaksi & Subtitle (Menggunakan single Text dengan maxLines: 1 & ellipsis agar 100% Bebas Overflow)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatItemTime(item.timestamp)}  ·  ${item.category}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Nominal + Pos label
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${CurrencyFormatter.format(item.amount)}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPosLabel(item.category),
                  style: TextStyle(
                    color: _getPosColor(item.category),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, ExpenseItem item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Transaksi?',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          'Hapus catatan "${item.title}" sebesar ${CurrencyFormatter.format(item.amount)}?',
          style: const TextStyle(color: Color(0xFF475569), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              widget.onDeleteExpense(item);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}