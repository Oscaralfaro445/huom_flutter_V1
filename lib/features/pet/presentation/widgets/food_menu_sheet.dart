import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/usecases/feed_pet_usecase.dart';

/// Bottom sheet para elegir qué comida darle a la mascota.
///
/// Uso:
/// ```dart
/// final food = await showFoodMenu(context);
/// if (food != null) await ref.read(petActionsProvider.notifier).feedPet(food);
/// ```
Future<FoodItem?> showFoodMenu(BuildContext context) {
  return showModalBottomSheet<FoodItem>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _FoodMenuSheet(),
  );
}

class _FoodMenuSheet extends StatelessWidget {
  const _FoodMenuSheet();

  static const _items = <_FoodInfo>[
    _FoodInfo(
      item: FoodItem.snack,
      icon: '🍪',
      label: 'Snack',
      description: 'Refrigerio rápido',
    ),
    _FoodInfo(
      item: FoodItem.basicFood,
      icon: '🍗',
      label: 'Comida básica',
      description: 'Comida estándar nutritiva',
    ),
    _FoodInfo(
      item: FoodItem.premiumFood,
      icon: '🥩',
      label: 'Comida premium',
      description: 'Mejor calidad, más saciante',
    ),
    _FoodInfo(
      item: FoodItem.specialFood,
      icon: '🍰',
      label: 'Comida especial',
      description: 'Platillo gourmet, sube ánimo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Indicador de drag
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.buttonBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '¿QUÉ LE DAS DE COMER?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // --- INICIO DEL CAMBIO ---
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final info in _items) ...[
                      _FoodTile(
                        info: info,
                        onTap: () => Navigator.of(context).pop(info.item),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            // --- FIN DEL CAMBIO ---
          ],
        ),
      ),
      ),
    );
  }
}

class _FoodInfo {
  final FoodItem item;
  final String icon;
  final String label;
  final String description;

  const _FoodInfo({
    required this.item,
    required this.icon,
    required this.label,
    required this.description,
  });
}

class _FoodTile extends StatelessWidget {
  final _FoodInfo info;
  final VoidCallback onTap;

  const _FoodTile({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.buttonBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Text(info.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 9,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatChip(
                        label: '+${info.item.hungerBonus.toInt()}',
                        color: AppColors.statHunger,
                        icon: '🍗',
                      ),
                      if (info.item.moodBonus > 0) ...[
                        const SizedBox(width: 6),
                        _StatChip(
                          label: '+${info.item.moodBonus.toInt()}',
                          color: AppColors.statMood,
                          icon: '😊',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 7,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
