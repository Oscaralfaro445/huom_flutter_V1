import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onBathe;
  final VoidCallback onSleep;

  const ActionButtonsWidget({
    super.key,
    required this.onFeed,
    required this.onPlay,
    required this.onBathe,
    required this.onSleep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: '🍗',
            label: 'Comer',
            color: AppColors.statHunger,
            onTap: onFeed,
          ),
          _ActionButton(
            icon: '🎮',
            label: 'Jugar',
            color: AppColors.statPlay,
            onTap: onPlay,
          ),
          _ActionButton(
            icon: '🛁',
            label: 'Bañar',
            color: AppColors.statSleep,
            onTap: onBathe,
          ),
          _ActionButton(
            icon: '💤',
            label: 'Dormir',
            color: AppColors.statMood,
            onTap: onSleep,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.buttonBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
                color: color,
                fontFamily: 'PressStart2P',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
