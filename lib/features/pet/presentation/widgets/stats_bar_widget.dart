import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pet.dart';

class StatsBarWidget extends StatelessWidget {
  final double hunger;
  final double mood;
  final double play;
  final double sleep;
  final double cleanliness;
  final double health;
  final List<PetCondition> conditions;

  const StatsBarWidget({
    super.key,
    required this.hunger,
    required this.mood,
    required this.play,
    required this.sleep,
    required this.cleanliness,
    required this.health,
    this.conditions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.85),
            borderRadius: conditions.isNotEmpty
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(icon: '🍗', value: hunger, color: AppColors.statHunger),
              _StatItem(icon: '😊', value: mood, color: AppColors.statMood),
              _StatItem(icon: '🎮', value: play, color: AppColors.statPlay),
              _StatItem(icon: '💤', value: sleep, color: AppColors.statSleep),
              _StatItem(
                icon: '🧼',
                value: cleanliness,
                color: AppColors.statCleanliness,
              ),
              _StatItem(
                icon: '❤️',
                value: health,
                color: AppColors.statHealth,
              ),
            ],
          ),
        ),
        if (conditions.isNotEmpty) _ConditionsBar(conditions: conditions),
      ],
    );
  }
}

class _ConditionsBar extends StatelessWidget {
  final List<PetCondition> conditions;

  const _ConditionsBar({required this.conditions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.statCritical.withValues(alpha: 0.18),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(
              color: AppColors.statCritical.withValues(alpha: 0.5), width: 1),
          right: BorderSide(
              color: AppColors.statCritical.withValues(alpha: 0.5), width: 1),
          bottom: BorderSide(
              color: AppColors.statCritical.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: conditions
            .map((c) => Text(
                  '${c.icon} ${c.displayName}',
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 6,
                    color: AppColors.statCritical,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final double value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
  });

  Color get _barColor {
    if (value > 60) return AppColors.statHigh;
    if (value > 30) return AppColors.statMedium;
    if (value > 15) return AppColors.statLow;
    return AppColors.statCritical;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        SizedBox(
          width: 38,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}%',
          style: const TextStyle(
            fontSize: 6,
            color: AppColors.textSecondary,
            fontFamily: 'PressStart2P',
          ),
        ),
      ],
    );
  }
}
