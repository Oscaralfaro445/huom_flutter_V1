import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../pet/domain/entities/pet.dart';
import '../../../pet/domain/usecases/treat_pet_usecase.dart';
import '../../../pet/presentation/providers/pet_provider.dart';
import '../providers/coins_provider.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petActionsProvider);
    final coinsAsync = ref.watch(coinsProvider);

    final pet = petAsync.valueOrNull;
    final coins = coinsAsync.valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _StoreHeader(coins: coins, onClose: () => Navigator.of(context).pop()),
            if (pet != null && pet.conditions.isNotEmpty)
              _ConditionsBanner(conditions: pet.conditions),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  const _SectionTitle(text: 'Medicamentos'),
                  const SizedBox(height: 8),
                  ...TreatmentItem.values.map((item) => _TreatmentCard(
                        item: item,
                        pet: pet,
                        coins: coins,
                        onBuy: () => _purchase(context, ref, item, coins),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    TreatmentItem item,
    int coins,
  ) async {
    if (coins < item.cost) {
      _showSnack(context, 'No tienes suficientes monedas', AppColors.statCritical);
      return;
    }

    await ref.read(petActionsProvider.notifier).treatPet(item);
    await ref.read(coinsProvider.notifier).refresh();

    if (context.mounted) {
      _showSnack(
        context,
        item.cost == 0
            ? '${item.icon} ${item.displayName} aplicado'
            : '${item.icon} ${item.displayName} comprado',
        AppColors.statPlay,
      );
    }
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 8,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Widgets internos ────────────────────────────────────────────────────────

class _StoreHeader extends StatelessWidget {
  final int coins;
  final VoidCallback onClose;

  const _StoreHeader({required this.coins, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.cardBackground,
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: AppColors.textPrimary, size: 26),
          ),
          const SizedBox(width: 12),
          const Text(
            'Tienda',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: AppColors.statMood,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionsBanner extends StatelessWidget {
  final List<PetCondition> conditions;

  const _ConditionsBanner({required this.conditions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statCritical.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statCritical, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Condiciones activas',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 8,
              color: AppColors.statCritical,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: conditions
                .map((c) => _ConditionChip(condition: c))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final PetCondition condition;

  const _ConditionChip({required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.statCritical.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${condition.icon} ${condition.displayName}',
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          fontSize: 7,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 10,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final TreatmentItem item;
  final Pet? pet;
  final int coins;
  final VoidCallback onBuy;

  const _TreatmentCard({
    required this.item,
    required this.pet,
    required this.coins,
    required this.onBuy,
  });

  bool get _canAfford => coins >= item.cost;

  bool get _curesActivCondition {
    if (pet == null) return false;
    if (item.cures.isEmpty) return true; // vitamins / forced rest siempre útiles
    return item.cures.any(
      (type) => pet!.conditions.any((c) => c.type == type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRelevant = _curesActivCondition;
    final borderColor = isRelevant
        ? AppColors.primary
        : AppColors.surface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isRelevant ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icono
            Text(item.icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isRelevant && item.cures.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '✓ Útil ahora',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 7,
                        color: AppColors.statPlay,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Botón de compra
            GestureDetector(
              onTap: _canAfford ? onBuy : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _canAfford
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.cost == 0)
                      const Text(
                        'USAR',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 7,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      Text(
                        '${item.cost}',
                        style: TextStyle(
                          fontFamily: 'PressStart2P',
                          fontSize: 8,
                          color: _canAfford
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
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
