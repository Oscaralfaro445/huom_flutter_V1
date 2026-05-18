import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatsBarWidget extends StatelessWidget {
  final double hunger;
  final double mood;
  final double play;
  final double sleep;
  final double cleanliness;

  const StatsBarWidget({
    super.key,
    required this.hunger,
    required this.mood,
    required this.play,
    required this.sleep,
    required this.cleanliness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
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
        ],
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
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        SizedBox(
          width: 44,
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
            fontSize: 7,
            color: AppColors.textSecondary,
            fontFamily: 'PressStart2P',
          ),
        ),
      ],
    );
  }
}
