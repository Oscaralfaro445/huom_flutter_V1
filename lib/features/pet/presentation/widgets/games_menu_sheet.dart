import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Identifica un minijuego registrado en el menú.
enum GameId {
  foodDrop,
  colorTap,
  memory,
  skyJump,
  reactionTap,
  whackAPet,
  dodgeBombs,
}

/// Bottom sheet con la lista de minijuegos disponibles.
/// Devuelve el [GameId] seleccionado o null si el usuario cierra.
Future<GameId?> showGamesMenu(BuildContext context) {
  return showModalBottomSheet<GameId>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _GamesMenuSheet(),
  );
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

class _GamesMenuSheet extends StatelessWidget {
  const _GamesMenuSheet();

  static const _games = <_GameInfo>[
    _GameInfo(
      id: GameId.foodDrop,
      icon: '🍔',
      label: 'Food Drop',
      description: 'Atrapa comida',
      color: AppColors.statHunger,
      enabled: true,
    ),
    _GameInfo(
      id: GameId.colorTap,
      icon: '🎨',
      label: 'Color Tap',
      description: 'Reflejos rápidos',
      color: AppColors.statMood,
      enabled: true,
    ),
    _GameInfo(
      id: GameId.memory,
      icon: '🧠',
      label: 'Memory',
      description: 'Encuentra pares',
      color: AppColors.statHealth,
      enabled: true,
    ),
    _GameInfo(
      id: GameId.skyJump,
      icon: '☁️',
      label: 'Sky Jump',
      description: 'Sube alto',
      color: AppColors.statSleep,
      enabled: true,
    ),
    _GameInfo(
      id: GameId.reactionTap,
      icon: '⚡',
      label: 'Reaction',
      description: 'Toca rápido',
      color: AppColors.primary,
      enabled: true,
    ),
    _GameInfo(
      id: GameId.whackAPet,
      icon: '🔨',
      label: 'Whack-A-Pet',
      description: 'Atrapa mascotas',
      color: AppColors.statPlay,
      enabled: true,
    ),
    _GameInfo(
      id: GameId.dodgeBombs,
      icon: '💣',
      label: 'Dodge Bombs',
      description: 'Esquiva bombas',
      color: AppColors.statCritical,
      enabled: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundSecondary,
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Header
                  Row(
                    children: [
                      const Text('🎮', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MINIJUEGOS',
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_games.where((g) => g.enabled).length} disponibles',
                            style: const TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 7,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Grid de minijuegos (2 columnas)
                  Expanded(
                    child: GridView.builder(
                      itemCount: _games.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, i) {
                        final g = _games[i];
                        return _GameCard(
                          info: g,
                          onTap: g.enabled
                              ? () => Navigator.of(context).pop(g.id)
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final _GameInfo info;
  final VoidCallback? onTap;

  const _GameCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surface.withValues(alpha: 0.4)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled
                ? AppColors.buttonBorder.withValues(alpha: 0.3)
                : info.color,
            width: 2,
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: info.color.withValues(alpha: 0.2),
          highlightColor: info.color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono grande con badge de color
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: disabled
                        ? AppColors.buttonBackground
                        : info.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: disabled ? 0.4 : 1,
                    child: Text(info.icon, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  info.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 9,
                    color: disabled ? AppColors.textSecondary : info.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.description,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (disabled) ...[
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
