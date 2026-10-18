import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../utils/currency_formatter.dart';
import 'bento_card.dart';

class BentoGrid extends StatelessWidget {
  final BudgetModel budget;
  final double secondaryRemaining;
  final VoidCallback onEditBudget;

  const BentoGrid({
    super.key,
    required this.budget,
    required this.secondaryRemaining,
    required this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alokasi Pos',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: onEditBudget,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 13,
                      color: Color(0xFF475569),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Ubah Pos',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Grid 2x2 Bento Cards
        Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Card Primer
                  Expanded(
                    child: BentoCard(
                      title: 'Primer',
                      amount: CurrencyFormatter.format(budget.primaryAllocation),
                      badgeText: '${budget.primaryPercent.toStringAsFixed(1)}%',
                      icon: Icons.receipt_long_rounded,
                      iconBackgroundColor: const Color(0xFFE2E8F0),
                      iconColor: const Color(0xFF475569),
                      onTap: onEditBudget,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 2. Card Sekunder
                  Expanded(
                    child: BentoCard(
                      title: 'Sekunder',
                      amount: CurrencyFormatter.format(secondaryRemaining),
                      badgeText: '${budget.secondaryPercent.toStringAsFixed(1)}%',
                      icon: Icons.local_cafe_rounded,
                      iconBackgroundColor: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      onTap: onEditBudget,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 3. Card Tersier
                  Expanded(
                    child: BentoCard(
                      title: 'Tersier',
                      amount: CurrencyFormatter.format(budget.tertiaryAllocation),
                      badgeText: '${budget.tertiaryPercent.toStringAsFixed(1)}%',
                      icon: Icons.auto_awesome_rounded,
                      iconBackgroundColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      onTap: onEditBudget,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 4. Card Tabungan
                  Expanded(
                    child: BentoCard(
                      title: 'Tabungan',
                      amount: CurrencyFormatter.format(budget.savingsAllocation),
                      badgeText: '${budget.savingsPercent.toStringAsFixed(1)}%',
                      icon: Icons.savings_rounded,
                      iconBackgroundColor: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      onTap: onEditBudget,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}