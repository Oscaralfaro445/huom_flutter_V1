import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Identifica un minijuego registrado en el menú.
enum GameId { jumpRope, foodDrop }

/// Bottom sheet con la lista de minijuegos disponibles.
/// Devuelve el [GameId] seleccionado o null si el usuario cierra.
Future<GameId?> showGamesMenu(BuildContext context) {
  return showModalBottomSheet<GameId>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _GamesMenuSheet(),
  );
}

class _GamesMenuSheet extends StatelessWidget {
  const _GamesMenuSheet();

  static const _games = <_GameInfo>[
    _GameInfo(
      id: GameId.jumpRope,
      icon: '🪢',
      label: 'Jump Rope',
      description: 'Salta la cuerda y gana monedas',
      color: AppColors.statPlay,
      enabled: true,
    ),
    _GameInfo(
      id: GameId.foodDrop,
      icon: '🍔',
      label: 'Food Drop',
      description: 'Atrapa la comida, esquiva las bombas',
      color: AppColors.statHunger,
      enabled: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                'MINIJUEGOS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final g in _games) ...[
              _GameTile(
                info: g,
                onTap: g.enabled
                    ? () => Navigator.of(context).pop(g.id)
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _GameInfo {
  final GameId id;
  final String icon;
  final String label;
  final String description;
  final Color color;
  final bool enabled;

  const _GameInfo({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.enabled,
  });
}

class _GameTile extends StatelessWidget {
  final _GameInfo info;
  final VoidCallback? onTap;

  const _GameTile({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: info.color, width: 1.5),
          ),
          child: Row(
            children: [
              Text(info.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 10,
                        color: info.color,
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
                  ],
                ),
              ),
              Icon(
                disabled ? Icons.lock_outline : Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
