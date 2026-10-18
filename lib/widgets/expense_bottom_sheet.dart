import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense_item.dart';
import '../utils/currency_formatter.dart';

class ExpenseBottomSheet extends StatefulWidget {
  final double currentDailyAllowance;
  final double currentSecondaryRemaining;
  final Function(ExpenseItem) onAddExpense;

  const ExpenseBottomSheet({
    super.key,
    required this.currentDailyAllowance,
    required this.currentSecondaryRemaining,
    required this.onAddExpense,
  });

  static Future<void> show({
    required BuildContext context,
    required double currentDailyAllowance,
    required double currentSecondaryRemaining,
    required Function(ExpenseItem) onAddExpense,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExpenseBottomSheet(
        currentDailyAllowance: currentDailyAllowance,
        currentSecondaryRemaining: currentSecondaryRemaining,
        onAddExpense: onAddExpense,
      ),
    );
  }

  @override
  State<ExpenseBottomSheet> createState() => _ExpenseBottomSheetState();
}

class _ExpenseBottomSheetState extends State<ExpenseBottomSheet> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedCategory = 'Makan & Minum';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Makan', 'icon': Icons.restaurant_rounded},
    {'name': 'Transport', 'icon': Icons.directions_bike_rounded},
    {'name': 'Belanja', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Tagihan', 'icon': Icons.receipt_long_outlined},
    {'name': 'Hiburan', 'icon': Icons.confirmation_number_outlined},
    {'name': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  final List<int> _quickAmounts = [10000, 25000, 50000, 100000];

  String _mapCategoryToOld(String cat) {
    switch (cat) {
      case 'Makan': return 'Makan & Minum';
      case 'Transport': return 'Transportasi';
      case 'Belanja': return 'Belanja';
      case 'Tagihan': return 'Lain-lain';
      case 'Hiburan': return 'Hiburan';
      default: return 'Lain-lain';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int value) {
    final currentVal = CurrencyFormatter.parse(_amountController.text);
    final newVal = currentVal + value;
    _amountController.text = CurrencyFormatter.formatWithoutSymbol(newVal);
    setState(() {});
  }

  void _handleSubmit() {
    final amount = CurrencyFormatter.parse(_amountController.text);
    final title = _titleController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan nominal pengeluaran yang valid!'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final expense = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? _selectedCategory : title,
      amount: amount,
      category: _mapCategoryToOld(_selectedCategory),
      timestamp: DateTime.now(),
    );

    widget.onAddExpense(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catat Jajan',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sisa jatah hari ini ${CurrencyFormatter.format(widget.currentDailyAllowance)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // JUMLAH PENGELUARAN label
            const Text(
              'JUMLAH PENGELUARAN',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Nominal Input — Large underline style
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF0F172A), width: 1.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Rp ',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      cursorColor: const Color(0xFF0F172A),
                      cursorWidth: 2.5,
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          final numVal = CurrencyFormatter.parse(val);
                          final formatted = CurrencyFormatter.formatWithoutSymbol(numVal);
                          if (val != formatted) {
                            _amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Quick Amount Chips - 4 chips sesuai desain
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickAmounts.map((amount) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _addQuickAmount(amount),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '+${CurrencyFormatter.formatCompact(amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Keterangan input - with pencil icon hint
            const Text(
              'Jajan apa hari ini?',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Roti sore',
                hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Kategori — 3 columns grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih kategori',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Masuk ke pos Primer',
                  style: TextStyle(
                    color: const Color(0xFF0284C7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 24,
                          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Info Banner: Sisa jatah setelah dicatat
            Builder(builder: (context) {
              final amount = CurrencyFormatter.parse(_amountController.text);
              final remainingAfter = widget.currentDailyAllowance - amount;
              if (amount <= 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Setelah dicatat, jatahmu tersisa ${CurrencyFormatter.format(remainingAfter > 0 ? remainingAfter : 0)}.',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Simpan Pengeluaran',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
