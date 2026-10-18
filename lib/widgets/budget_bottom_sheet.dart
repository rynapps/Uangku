import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/budget_model.dart';
import '../utils/currency_formatter.dart';

class BudgetBottomSheet extends StatefulWidget {
  final BudgetModel initialBudget;
  final Function(BudgetModel) onSaveBudget;

  const BudgetBottomSheet({
    super.key,
    required this.initialBudget,
    required this.onSaveBudget,
  });

  static Future<void> show({
    required BuildContext context,
    required BudgetModel initialBudget,
    required Function(BudgetModel) onSaveBudget,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BudgetBottomSheet(
        initialBudget: initialBudget,
        onSaveBudget: onSaveBudget,
      ),
    );
  }

  @override
  State<BudgetBottomSheet> createState() => _BudgetBottomSheetState();
}

class _BudgetBottomSheetState extends State<BudgetBottomSheet> {
  late TextEditingController _salaryController;
  late TextEditingController _primaryController;
  late TextEditingController _secondaryController;
  late TextEditingController _tertiaryController;

  // Detail lists
  late List<BudgetDetailItem> _primaryDetails;
  late List<BudgetDetailItem> _secondaryDetails;
  late List<BudgetDetailItem> _tertiaryDetails;

  // Expansion toggles
  bool _isPrimaryExpanded = false;
  bool _isSecondaryExpanded = false;
  bool _isTertiaryExpanded = false;

  // Controllers for adding new detail items
  final _newPrimaryTitleCtrl = TextEditingController();
  final _newPrimaryAmountCtrl = TextEditingController();

  final _newSecondaryTitleCtrl = TextEditingController();
  final _newSecondaryAmountCtrl = TextEditingController();

  final _newTertiaryTitleCtrl = TextEditingController();
  final _newTertiaryAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _salaryController = TextEditingController(
      text: CurrencyFormatter.formatWithoutSymbol(widget.initialBudget.totalSalary),
    );
    _primaryController = TextEditingController(
      text: CurrencyFormatter.formatWithoutSymbol(widget.initialBudget.primaryAllocation),
    );
    _secondaryController = TextEditingController(
      text: CurrencyFormatter.formatWithoutSymbol(widget.initialBudget.secondaryAllocation),
    );
    _tertiaryController = TextEditingController(
      text: CurrencyFormatter.formatWithoutSymbol(widget.initialBudget.tertiaryAllocation),
    );

    _primaryDetails = List.from(widget.initialBudget.primaryDetails);
    _secondaryDetails = List.from(widget.initialBudget.secondaryDetails);
    _tertiaryDetails = List.from(widget.initialBudget.tertiaryDetails);

    if (_primaryDetails.isNotEmpty) {
      _isPrimaryExpanded = true;
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _primaryController.dispose();
    _secondaryController.dispose();
    _tertiaryController.dispose();

    _newPrimaryTitleCtrl.dispose();
    _newPrimaryAmountCtrl.dispose();
    _newSecondaryTitleCtrl.dispose();
    _newSecondaryAmountCtrl.dispose();
    _newTertiaryTitleCtrl.dispose();
    _newTertiaryAmountCtrl.dispose();
    super.dispose();
  }

  double get _salary => CurrencyFormatter.parse(_salaryController.text);
  double get _primary => CurrencyFormatter.parse(_primaryController.text);
  double get _secondary => CurrencyFormatter.parse(_secondaryController.text);
  double get _tertiary => CurrencyFormatter.parse(_tertiaryController.text);

  double get _savings => _salary - (_primary + _secondary + _tertiary);

  void _applyPreset(double pRatio, double sRatio, double tRatio) {
    final sal = _salary > 0 ? _salary : 8000000;
    _salaryController.text = CurrencyFormatter.formatWithoutSymbol(sal);
    _primaryController.text = CurrencyFormatter.formatWithoutSymbol(sal * pRatio);
    _secondaryController.text = CurrencyFormatter.formatWithoutSymbol(sal * sRatio);
    _tertiaryController.text = CurrencyFormatter.formatWithoutSymbol(sal * tRatio);
    setState(() {});
  }

  void _addDetailItem(
    String posType,
    TextEditingController titleCtrl,
    TextEditingController amountCtrl,
  ) {
    final title = titleCtrl.text.trim();
    final amount = CurrencyFormatter.parse(amountCtrl.text);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan nama item rincian terlebih dahulu!'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan nominal rincian yang valid!'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final newItem = BudgetDetailItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
    );

    if (posType == 'primary') {
      _primaryDetails.add(newItem);
      final sum = BudgetModel.sumDetails(_primaryDetails);
      _primaryController.text = CurrencyFormatter.formatWithoutSymbol(sum);
    } else if (posType == 'secondary') {
      _secondaryDetails.add(newItem);
      final sum = BudgetModel.sumDetails(_secondaryDetails);
      _secondaryController.text = CurrencyFormatter.formatWithoutSymbol(sum);
    } else if (posType == 'tertiary') {
      _tertiaryDetails.add(newItem);
      final sum = BudgetModel.sumDetails(_tertiaryDetails);
      _tertiaryController.text = CurrencyFormatter.formatWithoutSymbol(sum);
    }

    titleCtrl.clear();
    amountCtrl.clear();
    setState(() {});
  }

  void _removeDetailItem(String posType, String itemId) {
    if (posType == 'primary') {
      _primaryDetails.removeWhere((e) => e.id == itemId);
      if (_primaryDetails.isNotEmpty) {
        final sum = BudgetModel.sumDetails(_primaryDetails);
        _primaryController.text = CurrencyFormatter.formatWithoutSymbol(sum);
      }
    } else if (posType == 'secondary') {
      _secondaryDetails.removeWhere((e) => e.id == itemId);
      if (_secondaryDetails.isNotEmpty) {
        final sum = BudgetModel.sumDetails(_secondaryDetails);
        _secondaryController.text = CurrencyFormatter.formatWithoutSymbol(sum);
      }
    } else if (posType == 'tertiary') {
      _tertiaryDetails.removeWhere((e) => e.id == itemId);
      if (_tertiaryDetails.isNotEmpty) {
        final sum = BudgetModel.sumDetails(_tertiaryDetails);
        _tertiaryController.text = CurrencyFormatter.formatWithoutSymbol(sum);
      }
    }
    setState(() {});
  }

  void _handleSubmit() {
    if (_salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Masukkan Total Gaji Bulanan yang valid!'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final updated = BudgetModel(
      totalSalary: _salary,
      primaryAllocation: _primary,
      secondaryAllocation: _secondary,
      tertiaryAllocation: _tertiary,
      primaryDetails: _primaryDetails,
      secondaryDetails: _secondaryDetails,
      tertiaryDetails: _tertiaryDetails,
    );

    widget.onSaveBudget(updated);
    Navigator.pop(context);
  }

  Widget _buildPosSection({
    required String label,
    required TextEditingController controller,
    required Color accentColor,
    required IconData icon,
    required String posType,
    required List<BudgetDetailItem> details,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
    required TextEditingController newTitleCtrl,
    required TextEditingController newAmountCtrl,
  }) {
    final currentPosAmount = CurrencyFormatter.parse(controller.text);
    final percentOfSalary = _salary > 0 ? (currentPosAmount / _salary) * 100 : 0.0;
    final totalFromDetails = BudgetModel.sumDetails(details);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: details.isNotEmpty ? accentColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: accentColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${percentOfSalary.toStringAsFixed(0)}% Gaji',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Total Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Text(
                  'Rp ',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        final numVal = CurrencyFormatter.parse(val);
                        final formatted = CurrencyFormatter.formatWithoutSymbol(numVal);
                        if (val != formatted) {
                          controller.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      }
                      setState(() {});
                    },
                  ),
                ),
                if (details.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Auto-sum',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Detail Expansion Toggle Button
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: details.isNotEmpty ? accentColor.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: details.isNotEmpty ? accentColor.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          details.isNotEmpty ? Icons.playlist_add_check_rounded : Icons.playlist_add_rounded,
                          size: 16,
                          color: details.isNotEmpty ? accentColor : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            details.isEmpty
                                ? '+ Tambah Rincian Item (Opsional)'
                                : '${details.length} Rincian Item (${CurrencyFormatter.format(totalFromDetails)})',
                            style: TextStyle(
                              color: details.isNotEmpty ? accentColor : const Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: details.isNotEmpty ? accentColor : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Detail Items List & Add Form
          if (isExpanded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Pengeluaran Pos Ini:',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (details.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Belum ada rincian. Masukkan item spesifik (misal: Kos, WiFi, Listrik) di bawah.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.length,
                      separatorBuilder: (context, index) => const Divider(height: 10, color: Color(0xFFE2E8F0)),
                      itemBuilder: (context, index) {
                        final item = details[index];
                        return Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(item.amount),
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => _removeDetailItem(posType, item.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),

                  // Mini Form Tambah Item
                  const Text(
                    '+ Tambah Item Baru:',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newTitleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Nama item (misal: Kos, Listrik, WiFi)...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newAmountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            hintText: 'Nominal (Rp)...',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              final numVal = CurrencyFormatter.parse(val);
                              final formatted = CurrencyFormatter.formatWithoutSymbol(numVal);
                              if (val != formatted) {
                                newAmountCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addDetailItem(posType, newTitleCtrl, newAmountCtrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Tambah',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDeficit = _savings < 0;

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
        color: Color(0xFFF8FAFC), // Off-white modern slate sheet
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
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

          const SizedBox(height: 14),

          // Header Modal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: Color(0xFF0F172A),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Atur Anggaran Bulanan',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Alokasikan gaji atau susun rincian pos keuangan',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                splashRadius: 20,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Preset Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                const Text(
                  'Preset Cepat: ',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.pie_chart_outline_rounded, size: 13, color: Color(0xFF0F172A)),
                  label: const Text('50 / 30 / 20', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  onPressed: () => _applyPreset(0.50, 0.30, 0.20),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  avatar: const Icon(Icons.pie_chart_outline_rounded, size: 13, color: Color(0xFF0F172A)),
                  label: const Text('50 / 25 / 10', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  onPressed: () => _applyPreset(0.50, 0.25, 0.10),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Scrollable Fields Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. HERO CARD: Total Gaji Bulanan (#0F172A Dark Slate Theme)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TOTAL GAJI BULANAN',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Rp ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _salaryController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    if (val.isNotEmpty) {
                                      final numVal = CurrencyFormatter.parse(val);
                                      final formatted = CurrencyFormatter.formatWithoutSymbol(numVal);
                                      if (val != formatted) {
                                        _salaryController.value = TextEditingValue(
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
                      ],
                    ),
                  ),

                  // 2. POS PRIMER
                  _buildPosSection(
                    label: 'Pos Primer (Kebutuhan Pokok)',
                    controller: _primaryController,
                    accentColor: const Color(0xFF334155), // Slate navy
                    icon: Icons.home_work_rounded,
                    posType: 'primary',
                    details: _primaryDetails,
                    isExpanded: _isPrimaryExpanded,
                    onToggleExpand: () => setState(() => _isPrimaryExpanded = !_isPrimaryExpanded),
                    newTitleCtrl: _newPrimaryTitleCtrl,
                    newAmountCtrl: _newPrimaryAmountCtrl,
                  ),

                  // 3. POS SEKUNDER
                  _buildPosSection(
                    label: 'Pos Sekunder (Jajan & Style)',
                    controller: _secondaryController,
                    accentColor: const Color(0xFF0284C7), // Sky blue
                    icon: Icons.local_cafe_rounded,
                    posType: 'secondary',
                    details: _secondaryDetails,
                    isExpanded: _isSecondaryExpanded,
                    onToggleExpand: () => setState(() => _isSecondaryExpanded = !_isSecondaryExpanded),
                    newTitleCtrl: _newSecondaryTitleCtrl,
                    newAmountCtrl: _newSecondaryAmountCtrl,
                  ),

                  // 4. POS TERSIER
                  _buildPosSection(
                    label: 'Pos Tersier (Keinginan & Tak Terduga)',
                    controller: _tertiaryController,
                    accentColor: const Color(0xFFD97706), // Amber
                    icon: Icons.auto_awesome_rounded,
                    posType: 'tertiary',
                    details: _tertiaryDetails,
                    isExpanded: _isTertiaryExpanded,
                    onToggleExpand: () => setState(() => _isTertiaryExpanded = !_isTertiaryExpanded),
                    newTitleCtrl: _newTertiaryTitleCtrl,
                    newAmountCtrl: _newTertiaryAmountCtrl,
                  ),

                  // 5. REALTIME SISA TABUNGAN SUMMARY CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDeficit ? const Color(0xFFFEF2F2) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDeficit ? const Color(0xFFFECDD3) : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDeficit
                              ? Colors.red.withValues(alpha: 0.1)
                              : const Color(0xFF0F172A).withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDeficit ? Icons.warning_amber_rounded : Icons.savings_rounded,
                                  color: isDeficit ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SISA TABUNGAN OTOMATIS',
                                  style: TextStyle(
                                    color: isDeficit
                                        ? const Color(0xFF991B1B)
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDeficit
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFF10B981).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _salary > 0
                                    ? '${((_savings / _salary) * 100).toStringAsFixed(1)}% Gaji'
                                    : '0%',
                                style: TextStyle(
                                  color: isDeficit ? const Color(0xFFB91C1C) : const Color(0xFF34D399),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(_savings),
                            style: TextStyle(
                              color: isDeficit ? const Color(0xFFDC2626) : Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDeficit
                              ? '⚠️ Total alokasi melebihi gaji! Kurangi alokasi pos di atas.'
                              : 'Otomatis dihitung: Total Gaji - (Primer + Sekunder + Tersier)',
                          style: TextStyle(
                            color: isDeficit
                                ? const Color(0xFFB91C1C)
                                : Colors.white.withValues(alpha: 0.65),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Submit Button (#0F172A Dark Slate Theme)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Simpan & Terapkan Anggaran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
